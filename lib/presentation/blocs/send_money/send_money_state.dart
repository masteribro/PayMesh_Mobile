part of 'send_money_bloc.dart';

enum SendMoneyStatus {
  idle,
  submitting,
  onlineSuccess,
  offlineQueued,
  error,
}

class SendMoneyState extends Equatable {
  final String? recipientId;
  final String? recipientName;
  final bool isAdvertising;
  final bool isScanning;
  final List<PayMeshDevice> nearbyDevices;
  final SendMoneyStatus status;
  final String? errorMessage;

  // Online success
  final String? onlineTxId;
  final double? onlineAmount;

  // Offline queued — data needed to show Payment QR
  final String? offlineTxId;
  final String? offlineSenderId;
  final String? offlineSenderName;
  final String? offlineReceiverId;
  final String? offlineRecipientName;
  final double? offlineAmount;
  final String? offlineTimestamp;
  final String? offlineSignature;

  const SendMoneyState({
    this.recipientId,
    this.recipientName,
    this.isAdvertising = false,
    this.isScanning = false,
    this.nearbyDevices = const [],
    this.status = SendMoneyStatus.idle,
    this.errorMessage,
    this.onlineTxId,
    this.onlineAmount,
    this.offlineTxId,
    this.offlineSenderId,
    this.offlineSenderName,
    this.offlineReceiverId,
    this.offlineRecipientName,
    this.offlineAmount,
    this.offlineTimestamp,
    this.offlineSignature,
  });

  SendMoneyState copyWith({
    String? recipientId,
    String? recipientName,
    bool? isAdvertising,
    bool? isScanning,
    List<PayMeshDevice>? nearbyDevices,
    SendMoneyStatus? status,
    String? errorMessage,
    String? onlineTxId,
    double? onlineAmount,
    String? offlineTxId,
    String? offlineSenderId,
    String? offlineSenderName,
    String? offlineReceiverId,
    String? offlineRecipientName,
    double? offlineAmount,
    String? offlineTimestamp,
    String? offlineSignature,
    bool clearRecipient = false,
  }) {
    return SendMoneyState(
      recipientId: clearRecipient ? null : (recipientId ?? this.recipientId),
      recipientName:
          clearRecipient ? null : (recipientName ?? this.recipientName),
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isScanning: isScanning ?? this.isScanning,
      nearbyDevices: nearbyDevices ?? this.nearbyDevices,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      onlineTxId: onlineTxId ?? this.onlineTxId,
      onlineAmount: onlineAmount ?? this.onlineAmount,
      offlineTxId: offlineTxId ?? this.offlineTxId,
      offlineSenderId: offlineSenderId ?? this.offlineSenderId,
      offlineSenderName: offlineSenderName ?? this.offlineSenderName,
      offlineReceiverId: offlineReceiverId ?? this.offlineReceiverId,
      offlineRecipientName:
          offlineRecipientName ?? this.offlineRecipientName,
      offlineAmount: offlineAmount ?? this.offlineAmount,
      offlineTimestamp: offlineTimestamp ?? this.offlineTimestamp,
      offlineSignature: offlineSignature ?? this.offlineSignature,
    );
  }

  @override
  List<Object?> get props => [
        recipientId,
        recipientName,
        isAdvertising,
        isScanning,
        nearbyDevices,
        status,
        errorMessage,
        onlineTxId,
        onlineAmount,
        offlineTxId,
        offlineSenderId,
        offlineSenderName,
        offlineReceiverId,
        offlineRecipientName,
        offlineAmount,
        offlineTimestamp,
        offlineSignature,
      ];
}
