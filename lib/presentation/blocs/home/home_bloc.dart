import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/dto/auth_response.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/incoming_transaction_service.dart';
import '../../../data/services/transaction_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService _authService;
  final TransactionService _txService;
  final IncomingTransactionService _incomingService;

  HomeBloc()
      : _authService = AuthService(),
        _txService = TransactionService(),
        _incomingService = IncomingTransactionService(),
        super(const HomeState()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeSyncRequested>(_onSync);
    on<HomeTopUpRequested>(_onTopUp);
    on<HomeLogoutRequested>(_onLogout);
    add(HomeLoadRequested());
  }

  Future<void> _onLoad(
      HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final cached = await _authService.getCachedAuthResponse();
      if (cached != null) emit(state.copyWith(user: cached, isLoading: true));

      final userId = await _authService.getUserId();
      if (userId == null) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      final freshProfile = await _authService.fetchFreshProfile(userId);
      final isOnline = freshProfile != null;
      if (freshProfile != null) emit(state.copyWith(user: freshProfile, isOnline: true));
      else emit(state.copyWith(isOnline: false));

      List<TransactionModel> serverTransactions = [];
      if (isOnline) {
        serverTransactions = await _txService.getTransactionHistory(userId);
      }

      final pending = await _txService.getPendingTransactions();
      final pendingModels = pending.map(_txService.pendingToModel).toList();

      final incoming = await _incomingService.getAll();
      final incomingModels = incoming.map((r) {
        final ts = DateTime.tryParse(r.timestamp) ?? DateTime.now();
        return TransactionModel(
          id: r.id,
          senderId: r.senderId,
          receiverId: r.receiverId,
          amount: r.amount,
          timestamp: ts,
          signature: r.signature,
          status: 'INCOMING_PENDING',
          createdAt: ts,
        );
      }).toList();

      final incomingAmount =
          incoming.fold<double>(0.0, (s, t) => s + t.amount);
      final serverIds = serverTransactions.map((t) => t.id).toSet();
      final uniquePending =
          pendingModels.where((p) => !serverIds.contains(p.id)).toList();
      final uniqueIncoming =
          incomingModels.where((p) => !serverIds.contains(p.id)).toList();

      final all = [...serverTransactions, ...uniquePending, ...uniqueIncoming]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      emit(state.copyWith(
        recentTransactions: all.take(5).toList(),
        incomingPendingAmount: incomingAmount,
        isLoading: false,
        error: null,
      ));
    } catch (_) {
      emit(state.copyWith(
          isLoading: false, error: 'Failed to load data'));
    }
  }

  Future<void> _onSync(
      HomeSyncRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(syncStatus: HomeSyncStatus.syncing));
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        emit(state.copyWith(syncStatus: HomeSyncStatus.idle));
        return;
      }

      final outgoing = await _txService.getPendingTransactions();
      final incoming = await _incomingService.getAll();

      if (outgoing.isEmpty && incoming.isEmpty) {
        emit(state.copyWith(syncStatus: HomeSyncStatus.nothingToSync));
        return;
      }

      if (outgoing.isNotEmpty) {
        await _txService.syncTransactions(userId: userId);
      }
      if (incoming.isNotEmpty) {
        await _incomingService.syncAll(userId);
      }

      emit(state.copyWith(syncStatus: HomeSyncStatus.success));
      add(HomeLoadRequested());
    } catch (e) {
      emit(state.copyWith(
          syncStatus: HomeSyncStatus.failure,
          syncError: e.toString()));
    }
  }

  Future<void> _onTopUp(
      HomeTopUpRequested event, Emitter<HomeState> emit) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    await _authService.topUp(userId: userId, amount: event.amount);
    add(HomeLoadRequested());
  }

  Future<void> _onLogout(
      HomeLogoutRequested event, Emitter<HomeState> emit) async {
    await _authService.logout();
    emit(state.copyWith(loggedOut: true));
  }
}
