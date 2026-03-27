class OfflineAllowanceModel {
  final double maxAmount;
  final int maxTransactions;
  final double currentBalance;

  OfflineAllowanceModel({
    required this.maxAmount,
    required this.maxTransactions,
    required this.currentBalance,
  });

  factory OfflineAllowanceModel.fromJson(Map<String, dynamic> json) {
    return OfflineAllowanceModel(
      maxAmount: (json['maxAmount'] as num).toDouble(),
      maxTransactions: json['maxTransactions'] as int,
      currentBalance: (json['currentBalance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'maxAmount': maxAmount,
    'maxTransactions': maxTransactions,
    'currentBalance': currentBalance,
  };

  /// Check remaining balance that can be spent offline
  double get remainingBalance => maxAmount - currentBalance;

  /// Check if user can perform transaction of given amount
  bool canPerformTransaction(double amount) {
    return remainingBalance >= amount;
  }
}
