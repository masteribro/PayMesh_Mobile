part of 'home_bloc.dart';

enum HomeSyncStatus { idle, syncing, success, nothingToSync, failure }

class HomeState extends Equatable {
  final AuthResponse? user;
  final List<TransactionModel> recentTransactions;
  final bool isLoading;
  final bool isOnline;
  final double incomingPendingAmount;
  final String? error;
  final HomeSyncStatus syncStatus;
  final String? syncError;
  final bool loggedOut;

  const HomeState({
    this.user,
    this.recentTransactions = const [],
    this.isLoading = true,
    this.isOnline = false,
    this.incomingPendingAmount = 0.0,
    this.error,
    this.syncStatus = HomeSyncStatus.idle,
    this.syncError,
    this.loggedOut = false,
  });

  HomeState copyWith({
    AuthResponse? user,
    List<TransactionModel>? recentTransactions,
    bool? isLoading,
    bool? isOnline,
    double? incomingPendingAmount,
    String? error,
    HomeSyncStatus? syncStatus,
    String? syncError,
    bool? loggedOut,
  }) {
    return HomeState(
      user: user ?? this.user,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      incomingPendingAmount:
          incomingPendingAmount ?? this.incomingPendingAmount,
      error: error,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError,
      loggedOut: loggedOut ?? this.loggedOut,
    );
  }

  @override
  List<Object?> get props => [
        user,
        recentTransactions,
        isLoading,
        isOnline,
        incomingPendingAmount,
        error,
        syncStatus,
        syncError,
        loggedOut,
      ];
}
