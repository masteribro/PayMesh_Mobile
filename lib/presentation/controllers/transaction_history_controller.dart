import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/transaction_service.dart';

class TransactionHistoryController extends ChangeNotifier {
  final AuthService _authService;
  final TransactionService _txService;

  String userId = '';
  List<TransactionModel> transactions = [];
  bool isLoading = true;

  TransactionHistoryController()
      : _authService = AuthService(),
        _txService = TransactionService();

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    final id = await _authService.getUserId() ?? '';
    userId = id;

    final serverTransactions = await _txService.getTransactionHistory(id);

    if (serverTransactions.isNotEmpty) {
      transactions = serverTransactions;
    } else {
      // Offline — show locally pending transactions
      final pending = await _txService.getPendingTransactions();
      transactions = pending.map(_txService.pendingToModel).toList();
    }

    isLoading = false;
    notifyListeners();
  }
}
