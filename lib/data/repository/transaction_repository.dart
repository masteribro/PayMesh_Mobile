import '../../core/exceptions/app_exception.dart';
import '../../core/result/app_result.dart';
import '../datasource/remote_datasource.dart';
import '../datasource/local_datasource.dart';
import '../models/sync_response_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  TransactionRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Create offline transaction
  Future<AppResult<TransactionModel>> createOfflineTransaction({
    required String transactionId,
    required String senderId,
    required String receiverId,
    required double amount,
    required String signature,
  }) async {
    try {
      final transaction = TransactionModel(
        id: transactionId,
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        timestamp: DateTime.now(),
        signature: signature,
        status: 'PENDING_SYNC',
        createdAt: DateTime.now(),
      );

      // Save locally
      final existingTransactions =
          await localDataSource.getOfflineTransactions();
      existingTransactions.add(transaction);
      await localDataSource.saveOfflineTransactions(existingTransactions);

      return AppResult.success(transaction);
    } on AppException catch (e) {
      return AppResult.failure(e);
    } catch (e) {
      return AppResult.failure(
        LocalStorageException('Failed to create offline transaction: $e'),
      );
    }
  }

  /// Get offline transactions
  Future<AppResult<List<TransactionModel>>> getOfflineTransactions() async {
    try {
      final transactions =
          await localDataSource.getOfflineTransactions();
      return AppResult.success(transactions);
    } on AppException catch (e) {
      return AppResult.failure(e);
    } catch (e) {
      return AppResult.failure(
        LocalStorageException('Failed to fetch offline transactions: $e'),
      );
    }
  }

  /// Sync transactions with backend
  Future<AppResult<SyncResponse>> syncTransactions({
    required String userId,
    required List<TransactionModel> transactions,
    required String merkleRoot,
    required String token,
  }) async {
    try {
      final txData = transactions
          .map((tx) => {
            'id': tx.id,
            'senderId': tx.senderId,
            'receiverId': tx.receiverId,
            'amount': tx.amount,
            'timestamp': tx.timestamp.toIso8601String(),
            'signature': tx.signature,
          })
          .toList();

      final response = await remoteDataSource.syncTransactions(
        userId: userId,
        transactions: txData,
        merkleRoot: merkleRoot,
        token: token,
      );

      // Update local transactions with sync status
      final updatedTransactions = transactions.map((tx) {
        final accepted = response.accepted.any((a) => a.id == tx.id);
        if (accepted) {
          return tx.copyWith(
            status: 'COMPLETED',
            syncedAt: DateTime.now(),
          );
        }
        return tx;
      }).toList();

      await localDataSource.saveOfflineTransactions(updatedTransactions);

      return AppResult.success(response);
    } on AppException catch (e) {
      return AppResult.failure(e);
    } catch (e) {
      return AppResult.failure(
        ServerException('Failed to sync transactions: $e'),
      );
    }
  }

  /// Remove synced transactions from local storage
  Future<void> removeSyncedTransactions(List<String> transactionIds) async {
    try {
      final transactions =
          await localDataSource.getOfflineTransactions();
      final remaining = transactions
          .where((tx) => !transactionIds.contains(tx.id))
          .toList();
      await localDataSource.saveOfflineTransactions(remaining);
    } catch (e) {
      // Log error but don't throw
      print('Error removing synced transactions: $e');
    }
  }
}
