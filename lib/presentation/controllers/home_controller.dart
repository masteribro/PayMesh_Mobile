import 'package:flutter/foundation.dart';
import '../../data/dto/auth_response.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/incoming_transaction_service.dart';
import '../../data/services/transaction_service.dart';

class HomeController extends ChangeNotifier {
  final AuthService _authService;
  final TransactionService _txService;
  final IncomingTransactionService _incomingService;

  AuthResponse? user;
  List<TransactionModel> recentTransactions = [];
  bool isLoading = true;
  bool isOnline = false;
  String? error;

  /// Total pending incoming amount from offline QR receives (for UI display).
  double incomingPendingAmount = 0.0;

  HomeController()
      : _authService = AuthService(),
        _txService = TransactionService(),
        _incomingService = IncomingTransactionService();

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final cached = await _authService.getCachedAuthResponse();
      if (cached != null) {
        user = cached;
        notifyListeners();
      }

      final userId = await _authService.getUserId();
      if (userId == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final freshProfile = await _authService.fetchFreshProfile(userId);
      if (freshProfile != null) {
        user = freshProfile;
        isOnline = true;
      } else {
        isOnline = false;
      }
      notifyListeners();

      List<TransactionModel> serverTransactions = [];
      if (isOnline) {
        serverTransactions = await _txService.getTransactionHistory(userId);
      }

      // Outgoing pending (sender side)
      final pending = await _txService.getPendingTransactions();
      final pendingModels = pending.map(_txService.pendingToModel).toList();

      // Incoming pending (recipient side — received via offline QR)
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

      incomingPendingAmount =
          incoming.fold(0.0, (sum, t) => sum + t.amount);

      final serverIds = serverTransactions.map((t) => t.id).toSet();
      final uniquePending =
          pendingModels.where((p) => !serverIds.contains(p.id)).toList();
      final uniqueIncoming =
          incomingModels.where((p) => !serverIds.contains(p.id)).toList();

      final all = [...serverTransactions, ...uniquePending, ...uniqueIncoming]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      recentTransactions = all.take(5).toList();
    } catch (_) {
      error = 'Failed to load data';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Syncs both outgoing (sender) and incoming (recipient) pending transactions.
  /// Returns false if there was nothing to sync on either side.
  Future<bool> syncTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    final outgoing = await _txService.getPendingTransactions();
    final incoming = await _incomingService.getAll();

    if (outgoing.isEmpty && incoming.isEmpty) return false;

    if (outgoing.isNotEmpty) {
      await _txService.syncTransactions(userId: userId);
    }
    if (incoming.isNotEmpty) {
      // BACKEND NOTE: This submits the same transaction IDs the sender already
      // submitted. Your backend must be idempotent — return the transaction in
      // `accepted` if it already exists, without double-crediting.
      await _incomingService.syncAll(userId);
    }

    await loadData();
    return true;
  }

  Future<void> topUp(double amount) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('Not logged in');
    await _authService.topUp(userId: userId, amount: amount);
    await loadData();
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
