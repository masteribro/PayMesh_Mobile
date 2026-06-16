import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/transaction_service.dart';
import '../../../domain/services/bluetooth_service.dart';

part 'send_money_event.dart';
part 'send_money_state.dart';

class SendMoneyBloc extends Bloc<SendMoneyEvent, SendMoneyState> {
  final AuthService _authService;
  final TransactionService _txService;
  final PayMeshBluetoothService _bleService;
  StreamSubscription? _bleScanSub;

  SendMoneyBloc()
      : _authService = AuthService(),
        _txService = TransactionService(),
        _bleService = PayMeshBluetoothService(),
        super(const SendMoneyState()) {
    on<RecipientQrScanned>(_onRecipientQrScanned);
    on<RecipientFromDeviceSelected>(_onDeviceSelected);
    on<RecipientCleared>(_onRecipientCleared);
    on<AdvertisingToggled>(_onAdvertisingToggled);
    on<BleScanStarted>(_onBleScanStarted);
    on<_BleDevicesUpdated>(_onBleDevicesUpdated);
    on<_BleScanCompleted>(_onBleScanCompleted);
    on<SendMoneySubmitted>(_onSendMoney);
    on<SendMoneyReset>(_onReset);
  }

  @override
  Future<void> close() {
    _bleScanSub?.cancel();
    _bleService.stopScan();
    _bleService.stopAdvertising();
    return super.close();
  }

  void _onRecipientQrScanned(
      RecipientQrScanned event, Emitter<SendMoneyState> emit) {
    emit(state.copyWith(
      recipientId: event.userId,
      recipientName: event.username,
      status: SendMoneyStatus.idle,
    ));
  }

  void _onDeviceSelected(
      RecipientFromDeviceSelected event, Emitter<SendMoneyState> emit) {
    emit(state.copyWith(
      recipientId: event.device.userId,
      recipientName: event.device.displayName,
      status: SendMoneyStatus.idle,
    ));
  }

  void _onRecipientCleared(
      RecipientCleared event, Emitter<SendMoneyState> emit) {
    emit(state.copyWith(clearRecipient: true, status: SendMoneyStatus.idle));
  }

  Future<void> _onAdvertisingToggled(
      AdvertisingToggled event, Emitter<SendMoneyState> emit) async {
    if (event.start) {
      final userId = await _authService.getUserId();
      final cached = await _authService.getCachedAuthResponse();
      if (userId == null || cached == null) return;
      try {
        await _bleService.startAdvertising(
            userId: userId, username: cached.username);
        emit(state.copyWith(isAdvertising: true));
      } catch (e) {
        emit(state.copyWith(
            status: SendMoneyStatus.error,
            errorMessage: e.toString()));
      }
    } else {
      await _bleService.stopAdvertising();
      emit(state.copyWith(isAdvertising: false));
    }
  }

  void _onBleScanStarted(
      BleScanStarted event, Emitter<SendMoneyState> emit) {
    _bleScanSub?.cancel();
    emit(state.copyWith(isScanning: true, nearbyDevices: []));
    _bleScanSub = _bleService.scanForDevices().listen(
      (devices) => add(_BleDevicesUpdated(devices)),
      onDone: () => add(_BleScanCompleted()),
    );
  }

  void _onBleDevicesUpdated(
      _BleDevicesUpdated event, Emitter<SendMoneyState> emit) {
    emit(state.copyWith(nearbyDevices: event.devices));
  }

  void _onBleScanCompleted(
      _BleScanCompleted event, Emitter<SendMoneyState> emit) {
    emit(state.copyWith(isScanning: false));
  }

  Future<void> _onSendMoney(
      SendMoneySubmitted event, Emitter<SendMoneyState> emit) async {
    if (state.recipientId == null) return;

    emit(state.copyWith(status: SendMoneyStatus.submitting));

    try {
      final senderId = await _authService.getUserId();
      if (senderId == null) throw Exception('Not logged in');

      try {
        final result = await _txService.sendMoneyOnline(
          senderId: senderId,
          receiverId: state.recipientId!,
          amount: event.amount,
        );
        emit(state.copyWith(
          status: SendMoneyStatus.onlineSuccess,
          onlineTxId: result.id,
          onlineAmount: event.amount,
          clearRecipient: true,
        ));
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          final id = _generateUuid();
          final timestamp = DateTime.now().toIso8601String();
          final signature = _generateSignature(
            id: id,
            senderId: senderId,
            receiverId: state.recipientId!,
            amount: event.amount,
            timestamp: timestamp,
          );
          await _txService.createOfflineTransaction(
            id: id,
            senderId: senderId,
            receiverId: state.recipientId!,
            amount: event.amount,
            timestamp: timestamp,
            signature: signature,
          );
          final cached = await _authService.getCachedAuthResponse();
          emit(state.copyWith(
            status: SendMoneyStatus.offlineQueued,
            offlineTxId: id,
            offlineSenderId: senderId,
            offlineSenderName: cached?.username ?? senderId,
            offlineReceiverId: state.recipientId,
            offlineRecipientName: state.recipientName ?? state.recipientId,
            offlineAmount: event.amount,
            offlineTimestamp: timestamp,
            offlineSignature: signature,
            clearRecipient: true,
          ));
        } else {
          emit(state.copyWith(
            status: SendMoneyStatus.error,
            errorMessage:
                e.response?.data?['message']?.toString() ??
                e.message ??
                e.toString(),
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
          status: SendMoneyStatus.error, errorMessage: e.toString()));
    }
  }

  void _onReset(SendMoneyReset event, Emitter<SendMoneyState> emit) {
    emit(state.copyWith(status: SendMoneyStatus.idle));
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  String _generateUuid() {
    final random = Random.secure();
    final bytes =
        List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  String _generateSignature({
    required String id,
    required String senderId,
    required String receiverId,
    required double amount,
    required String timestamp,
  }) {
    final data = '$id:$senderId:$receiverId:$amount:$timestamp';
    return sha256.convert(utf8.encode(data)).toString();
  }
}
