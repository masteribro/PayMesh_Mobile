import '../../core/exceptions/app_exception.dart';
import '../../data/models/sync_response_model.dart';
import '../../data/models/transaction_model.dart';


/// State holder for transaction operations
class TransactionState {
  final bool isLoading;
  final List<TransactionModel> offlineTransactions;
  final SyncResponse? syncResponse;
  final AppException? error;
  final bool isSyncing;
  final int totalPendingCount;
  final double totalPendingAmount;

  TransactionState({
    this.isLoading = false,
    this.offlineTransactions = const [],
    this.syncResponse,
    this.error,
    this.isSyncing = false,
    this.totalPendingCount = 0,
    this.totalPendingAmount = 0.0,
  });

  TransactionState copyWith({
    bool? isLoading,
    List<TransactionModel>? offlineTransactions,
    SyncResponse? syncResponse,
    AppException? error,
    bool? isSyncing,
    int? totalPendingCount,
    double? totalPendingAmount,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      offlineTransactions: offlineTransactions ?? this.offlineTransactions,
      syncResponse: syncResponse ?? this.syncResponse,
      error: error ?? this.error,
      isSyncing: isSyncing ?? this.isSyncing,
      totalPendingCount: totalPendingCount ?? this.totalPendingCount,
      totalPendingAmount: totalPendingAmount ?? this.totalPendingAmount,
    );
  }
}
