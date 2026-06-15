import 'package:flutter/foundation.dart';
import '../../data/dto/auth_response.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/transaction_service.dart';

class HomeController extends ChangeNotifier {
  final AuthService _authService;
  final TransactionService _txService;

  AuthResponse? user;
  List<TransactionModel> recentTransactions = [];
  bool isLoading = true;
  bool isOnline = false;
  String? error;

  HomeController()
      : _authService = AuthService(),
        _txService = TransactionService();

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

      final pending = await _txService.getPendingTransactions();
      final pendingModels = pending.map(_txService.pendingToModel).toList();

      final serverIds = serverTransactions.map((t) => t.id).toSet();
      final uniquePending =
          pendingModels.where((p) => !serverIds.contains(p.id)).toList();

      final all = [...serverTransactions, ...uniquePending]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      recentTransactions = all.take(5).toList();
    } catch (_) {
      error = 'Failed to load data';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Returns false if there is nothing to sync.
  Future<bool> syncTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;
    final pending = await _txService.getPendingTransactions();
    if (pending.isEmpty) return false;
    await _txService.syncTransactions(userId: userId);
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
