import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/transaction_service.dart';

part 'transaction_history_event.dart';
part 'transaction_history_state.dart';

class TransactionHistoryBloc
    extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  final AuthService _authService;
  final TransactionService _txService;

  TransactionHistoryBloc()
      : _authService = AuthService(),
        _txService = TransactionService(),
        super(const TransactionHistoryState()) {
    on<TransactionHistoryLoadRequested>(_onLoad);
    on<TransactionHistoryFilterChanged>(_onFilterChanged);
    add(TransactionHistoryLoadRequested());
  }

  Future<void> _onLoad(
      TransactionHistoryLoadRequested event,
      Emitter<TransactionHistoryState> emit) async {
    emit(state.copyWith(isLoading: true));

    final userId = await _authService.getUserId() ?? '';
    final serverTransactions =
        await _txService.getTransactionHistory(userId);

    final List<TransactionModel> transactions;
    if (serverTransactions.isNotEmpty) {
      transactions = serverTransactions;
    } else {
      final pending = await _txService.getPendingTransactions();
      transactions = pending.map(_txService.pendingToModel).toList();
    }

    emit(state.copyWith(
      transactions: transactions,
      userId: userId,
      isLoading: false,
    ));
  }

  void _onFilterChanged(
      TransactionHistoryFilterChanged event,
      Emitter<TransactionHistoryState> emit) {
    emit(state.copyWith(filterStatus: event.filter));
  }
}
