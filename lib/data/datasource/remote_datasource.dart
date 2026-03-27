import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/offline_allowance_model.dart';
import '../models/sync_response_model.dart';
import '../models/user_model.dart';

class RemoteDataSource {
  final Dio dio;

  RemoteDataSource({required this.dio});

  /// Register user
  Future<AuthResponseModel> register({
    required String email,
    required String username,
    required String password,
    required String publicKey,
    required double initialBalance,
  }) async {
    try {
      final response = await dio.post(
        Constants.authRegister,
        data: {
          'email': email,
          'username': username,
          'password': password,
          'publicKey': publicKey,
          'initialBalance': initialBalance,
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Login user
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        Constants.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get user profile
  Future<UserModel> getUserProfile({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await dio.get(
        '${Constants.userProfile}/$userId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch user profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get offline allowance
  Future<OfflineAllowanceModel> getOfflineAllowance({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await dio.get(
        '${Constants.offlineAllowance}/$userId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return OfflineAllowanceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch offline allowance',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Sync transactions
  Future<SyncResponse> syncTransactions({
    required String userId,
    required List<Map<String, dynamic>> transactions,
    required String merkleRoot,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        Constants.transactionsSync,
        data: {
          'userId': userId,
          'transactions': transactions,
          'merkleRoot': merkleRoot,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return SyncResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Sync failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
