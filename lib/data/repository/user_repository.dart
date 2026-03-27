import '../../core/exceptions/app_exception.dart';
import '../../core/result/app_result.dart';
import '../datasource/local_datasource.dart';
import '../datasource/remote_datasource.dart';
import '../models/user_model.dart';

/// Repository for user-related operations
/// Handles getting user profile and managing user data
class UserRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  UserRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Get user profile from backend
  /// Returns user details including balance and transaction counts
  Future<AppResult<UserModel>> getUserProfile(String userId, String token) async {
    try {
      // Try to fetch from remote source
      final remoteUser = await remoteDataSource.getUserProfile(userId: userId, token: token,);
      
      // Cache locally
      await localDataSource.saveUser(remoteUser);
      
      return AppResult.success(remoteUser);
    } on NetworkException catch (e) {
      // Fallback to local cache if network fails
      try {
        final cachedUser = await localDataSource.getUser();
        return AppResult.success(cachedUser!);
      } catch (_) {
        return AppResult.failure(e);
      }
    } catch (e) {
      return AppResult.failure(AppException.fromException(e));
    }
  }

  /// Update user balance after transaction
  /// Only updates local cache, backend updates during sync
  Future<AppResult<UserModel>> updateLocalBalance(
    String userId,
    double newBalance,
  ) async {
    try {
      final user = await localDataSource.getUser();
      final updatedUser = user?.copyWith(balance: newBalance);
      await localDataSource.saveUser(updatedUser!);
      return AppResult.success(updatedUser);
    } catch (e) {
      return AppResult.failure(AppException.fromException(e));
    }
  }

  /// Get cached user profile from local storage
  /// Used for quick access without network call
  Future<AppResult<UserModel>> getCachedUserProfile(String userId) async {
    try {
      final user = await localDataSource.getUser();
      return AppResult.success(user!);
    } catch (e) {
      return AppResult.failure(AppException.fromException(e));
    }
  }

  /// Update pending offline transaction count
  /// Tracks how many transactions are waiting to sync
  Future<AppResult<UserModel>> updatePendingTransactionCount(
    String userId,
    int count,
  ) async {
    try {
      final user = await localDataSource.getUser();
      final updatedUser = user!.copyWith(
        pendingOfflineTransactionCount: count,
      );
      await localDataSource.saveUser(updatedUser);
      return AppResult.success(updatedUser);
    } catch (e) {
      return AppResult.failure(AppException.fromException(e));
    }
  }

  /// Update pending offline amount
  /// Tracks total amount in unsynced transactions
  Future<AppResult<UserModel>> updatePendingOfflineAmount(
    String userId,
    double amount,
  ) async {
    try {
      final user = await localDataSource.getUser();
      final updatedUser = user!.copyWith(
        pendingOfflineAmount: amount,
      );
      await localDataSource.saveUser(updatedUser);
      return AppResult.success(updatedUser);
    } catch (e) {
      return AppResult.failure(AppException.fromException(e));
    }
  }

  /// Clear all cached user data
  /// Used during logout
  Future<AppResult<void>> clearUserCache(String userId) async {
    try {
      await localDataSource.deleteUser(userId);
      return AppResult.success(null);
    } catch (e) {
      return AppResult.failure(AppException.fromException(e));
    }
  }
}
