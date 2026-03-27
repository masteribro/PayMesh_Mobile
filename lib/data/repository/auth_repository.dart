import '../../core/exceptions/app_exception.dart';
import '../../core/result/app_result.dart';
import '../datasource/remote_datasource.dart';
import '../datasource/local_datasource.dart';
import '../models/auth_response_model.dart';


class AuthRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  AuthRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Register user
  Future<AppResult<AuthResponseModel>> register({
    required String email,
    required String username,
    required String password,
    required String publicKey,
    required double initialBalance,
  }) async {
    try {
      final response = await remoteDataSource.register(
        email: email,
        username: username,
        password: password,
        publicKey: publicKey,
        initialBalance: initialBalance,
      );

      // Save token and user locally
      await localDataSource.saveToken(response.token);
      await localDataSource.saveBalance(response.balance);

      return AppResult.success(response);
    } on AppException catch (e) {
      return AppResult.failure(e);
    } catch (e) {
      return AppResult.failure(
        ServerException('An unexpected error occurred: $e'),
      );
    }
  }

  /// Login user
  Future<AppResult<AuthResponseModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save token and user locally
      await localDataSource.saveToken(response.token);
      await localDataSource.saveBalance(response.balance);

      return AppResult.success(response);
    } on AppException catch (e) {
      return AppResult.failure(e);
    } catch (e) {
      return AppResult.failure(
        ServerException('An unexpected error occurred: $e'),
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    await localDataSource.clearAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get saved token
  Future<String?> getToken() async {
    return await localDataSource.getToken();
  }
}
