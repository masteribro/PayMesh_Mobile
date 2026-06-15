import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../dto/auth_response.dart';
import '../dto/login_request.dart';
import '../dto/register_request.dart';
import 'api_client.dart';
import 'api_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Store tokens in secure storage
  static const String _tokenKey = 'paymesh_auth_token';
  static const String _userIdKey = 'paymesh_user_id';
  static const String _userDataKey = 'paymesh_user_data';

  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    required String publicKey,
    required double initialBalance,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: RegisterRequest(
        email: email,
        username: username,
        password: password,
        publicKey: publicKey,
        initialBalance: initialBalance,
      ).toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _saveAuthData(authResponse);
    _apiClient.setAuthToken(authResponse.token);
    return authResponse;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: LoginRequest(email: email, password: password).toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);
    await _saveAuthData(authResponse);
    _apiClient.setAuthToken(authResponse.token);
    return authResponse;
  }

  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> restoreSession() async {
    final token = await getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userDataKey);
    _apiClient.removeAuthToken();
  }

  Future<AuthResponse?> getCachedAuthResponse() async {
    try {
      final data = await _secureStorage.read(key: _userDataKey);
      if (data == null) return null;
      return AuthResponse.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  /// Fetch a fresh user profile from the backend and update the local cache.
  /// Returns null if the network is unavailable.
  Future<AuthResponse?> fetchFreshProfile(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.usersBase}/$userId');
      final data = response.data as Map<String, dynamic>;
      final cached = await getCachedAuthResponse();
      final updated = AuthResponse(
        token: cached?.token ?? '',
        userId: userId,
        username: data['username'] as String? ?? cached?.username ?? '',
        email: data['email'] as String? ?? cached?.email ?? '',
        balance: (data['balance'] as num).toDouble(),
        pendingOfflineAmount: (data['pendingOfflineAmount'] as num).toDouble(),
        pendingOfflineTransactionCount:
            data['pendingOfflineTransactionCount'] as int,
      );
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(updated.toJson()),
      );
      return updated;
    } catch (_) {
      return null;
    }
  }

  /// Top up the user's wallet balance.
  Future<void> topUp({required String userId, required double amount}) async {
    await _apiClient.post(
      '${ApiConstants.usersBase}/$userId/topup',
      data: {'amount': amount},
    );
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _secureStorage.write(key: _tokenKey, value: authResponse.token);
    await _secureStorage.write(key: _userIdKey, value: authResponse.userId);
    await _secureStorage.write(
      key: _userDataKey,
      value: jsonEncode(authResponse.toJson()),
    );
  }
}
