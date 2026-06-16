part of 'transaction_history_bloc.dart';

sealed class TransactionHistoryEvent {}

class TransactionHistoryLoadRequested extends TransactionHistoryEvent {}

class TransactionHistoryFilterChanged extends TransactionHistoryEvent {
  final String filter;
  TransactionHistoryFilterChanged(this.filter);
}
