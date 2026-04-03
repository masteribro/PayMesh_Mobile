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

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    required String publicKey,
    required double initialBalance,
  }) async {
    try {
      final registerRequest = RegisterRequest(
        email: email,
        username: username,
        password: password,
        publicKey: publicKey,
        initialBalance: initialBalance,
      );

      final response = await _apiClient.post(
        ApiConstants.register,
        data: registerRequest.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Store token and user info
      await _saveAuthData(authResponse);
      _apiClient.setAuthToken(authResponse.token);

      return authResponse;
    } catch (e) {
      print('[v0] Register error: $e');
      rethrow;
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginRequest = LoginRequest(
        email: email,
        password: password,
      );

      final response = await _apiClient.post(
        ApiConstants.login,
        data: loginRequest.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Store token and user info
      await _saveAuthData(authResponse);
      _apiClient.setAuthToken(authResponse.token);

      return authResponse;
    } catch (e) {
      print('[v0] Login error: $e');
      rethrow;
    }
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      print('[v0] Get token error: $e');
      return null;
    }
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      print('[v0] Get user ID error: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Restore session from stored token
  Future<bool> restoreSession() async {
    try {
      final token = await getToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('[v0] Restore session error: $e');
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _userDataKey);
      _apiClient.removeAuthToken();
    } catch (e) {
      print('[v0] Logout error: $e');
      rethrow;
    }
  }

  /// Get the stored auth response (user profile cached from last login/register)
  Future<AuthResponse?> getCachedAuthResponse() async {
    try {
      final data = await _secureStorage.read(key: _userDataKey);
      if (data == null) return null;
      return AuthResponse.fromJson(jsonDecode(data));
    } catch (e) {
      print('[v0] Get cached auth response error: $e');
      return null;
    }
  }

  /// Save authentication data securely
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: authResponse.token);
      await _secureStorage.write(key: _userIdKey, value: authResponse.userId);
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(authResponse.toJson()),
      );
    } catch (e) {
      print('[v0] Save auth data error: $e');
      rethrow;
    }
  }
}
