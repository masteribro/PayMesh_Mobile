

import '../../data/models/transaction_model.dart';

class OfflineTransactionService {
  /// Generate transaction hash using SHA256
  static String generateTransactionHash({
    required String transactionId,
    required String senderId,
    required String receiverId,
    required double amount,
    required DateTime timestamp,
    String? prevHash,
  }) {
    final data =
        '$transactionId:$senderId:$receiverId:$amount:${timestamp.toIso8601String()}:${prevHash ?? ""}';
    // Using simple hash for now - implement actual SHA256 with crypto package
    return data.hashCode.toString();
  }

  /// Generate merkle root for multiple transactions
  static String generateMerkleRoot(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return '';
    }

    if (transactions.length == 1) {
      return transactions.first.currentHash ?? '';
    }

    List<String> hashes =
        transactions.map((tx) => tx.currentHash ?? '').toList();

    while (hashes.length > 1) {
      List<String> nextLevel = [];
      for (int i = 0; i < hashes.length; i += 2) {
        final left = hashes[i];
        final right = i + 1 < hashes.length ? hashes[i + 1] : hashes[i];
        final combined = left + right;
        nextLevel.add(combined.hashCode.toString());
      }
      hashes = nextLevel;
    }

    return hashes.isNotEmpty ? hashes.first : '';
  }

  /// Validate transaction amount
  static bool validateTransactionAmount(
    double amount,
    double maxAmount,
  ) {
    return amount > 0 && amount <= maxAmount;
  }

  /// Validate sender balance
  static bool validateSenderBalance(
    double senderBalance,
    double amount,
  ) {
    return senderBalance >= amount;
  }

  /// Check for double spending
  static bool checkDoubleSpending(
    List<TransactionModel> transactions,
    String transactionId,
  ) {
    return transactions.any((tx) => tx.id == transactionId && tx.isSpent);
  }

  /// Calculate total pending amount
  static double calculatePendingAmount(
    List<TransactionModel> transactions,
    String userId,
  ) {
    return transactions
        .where((tx) =>
            tx.senderId == userId &&
            (tx.status == 'PENDING_SYNC' || tx.status == 'PENDING_CONFIRMATION'))
        .fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  /// Get pending transaction count
  static int getPendingTransactionCount(
    List<TransactionModel> transactions,
  ) {
    return transactions
        .where((tx) =>
            tx.status == 'PENDING_SYNC' ||
            tx.status == 'PENDING_CONFIRMATION')
        .length;
  }

  /// Check if can perform offline transaction
  static bool canPerformOfflineTransaction({
    required double currentBalance,
    required double transactionAmount,
    required double maxOfflineAmount,
    required int currentPendingCount,
    required int maxPendingCount,
  }) {
    final hasBalance = (currentBalance - transactionAmount) >= 0;
    final withinLimit = transactionAmount <= maxOfflineAmount;
    final withinPendingLimit = currentPendingCount < maxPendingCount;

    return hasBalance && withinLimit && withinPendingLimit;
  }
}
