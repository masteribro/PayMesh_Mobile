part of 'transaction_history_bloc.dart';

class TransactionHistoryState extends Equatable {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String userId;
  final String filterStatus;

  const TransactionHistoryState({
    this.transactions = const [],
    this.isLoading = true,
    this.userId = '',
    this.filterStatus = 'ALL',
  });

  List<TransactionModel> get filtered {
    switch (filterStatus) {
      case 'SENT':
        return transactions.where((t) => t.senderId == userId).toList();
      case 'RECEIVED':
        return transactions.where((t) => t.receiverId == userId).toList();
      case 'PENDING':
        return transactions.where((t) => t.isPendingSync).toList();
      default:
        return transactions;
    }
  }

  TransactionHistoryState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? userId,
    String? filterStatus,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  @override
  List<Object?> get props =>
      [transactions, isLoading, userId, filterStatus];
}
