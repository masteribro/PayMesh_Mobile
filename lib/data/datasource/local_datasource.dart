import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exception.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';


// Simple in-memory storage for now (can be replaced with SharedPreferences or Hive)
class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._internal();
  final Map<String, dynamic> _storage = {};

  factory LocalDataSource() {
    return _instance;
  }

  LocalDataSource._internal();

  /// Save authentication token
  Future<void> saveToken(String token) async {
    try {
      _storage[Constants.tokenKey] = token;
    } catch (e) {
      throw LocalStorageException('Failed to save token: $e');
    }
  }

  /// Get saved token
  Future<String?> getToken() async {
    try {
      return _storage[Constants.tokenKey] as String?;
    } catch (e) {
      throw LocalStorageException('Failed to read token: $e');
    }
  }

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    try {
      _storage[Constants.userKey] = user.toJson();
    } catch (e) {
      throw LocalStorageException('Failed to save user: $e');
    }
  }

  /// Get saved user
  Future<UserModel?> getUser() async {
    try {
      final userData = _storage[Constants.userKey];
      if (userData == null) return null;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      throw LocalStorageException('Failed to read user: $e');
    }
  }

  /// Save offline transactions
  Future<void> saveOfflineTransactions(List<TransactionModel> transactions) async {
    try {
      _storage[Constants.offlineTransactionsKey] =
          transactions.map((t) => t.toJson()).toList();
    } catch (e) {
      throw LocalStorageException('Failed to save offline transactions: $e');
    }
  }

  /// Get offline transactions
  Future<List<TransactionModel>> getOfflineTransactions() async {
    try {
      final List<dynamic>? transactions =
      _storage[Constants.offlineTransactionsKey] as List<dynamic>?;
      if (transactions == null) return [];

      return transactions
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw LocalStorageException('Failed to read offline transactions: $e');
    }
  }

  /// Save offline permit
  Future<void> saveOfflinePermit(Map<String, dynamic> permit) async {
    try {
      _storage[Constants.offlinePermitKey] = permit;
    } catch (e) {
      throw LocalStorageException('Failed to save offline permit: $e');
    }
  }

  /// Get offline permit
  Future<Map<String, dynamic>?> getOfflinePermit() async {
    try {
      return _storage[Constants.offlinePermitKey] as Map<String, dynamic>?;
    } catch (e) {
      throw LocalStorageException('Failed to read offline permit: $e');
    }
  }

  /// Save user balance
  Future<void> saveBalance(double balance) async {
    try {
      _storage[Constants.balanceKey] = balance;
    } catch (e) {
      throw LocalStorageException('Failed to save balance: $e');
    }
  }

  /// Get user balance
  Future<double?> getBalance() async {
    try {
      return _storage[Constants.balanceKey] as double?;
    } catch (e) {
      throw LocalStorageException('Failed to read balance: $e');
    }
  }

  /// Clear all data (logout)
  Future<void> clearAll() async {
    try {
      _storage.clear();
    } catch (e) {
      throw LocalStorageException('Failed to clear storage: $e');
    }
  }

  /// Delete specific key
  Future<void> deleteKey(String key) async {
    try {
      _storage.remove(key);
    } catch (e) {
      throw LocalStorageException('Failed to delete key: $e');
    }
  }

  /// Delete user data
  Future<void> deleteUser(String userId) async {
    try {
      _storage.remove(Constants.userKey);
      _storage.remove(Constants.tokenKey);
      _storage.remove(Constants.offlineTransactionsKey);
      _storage.remove(Constants.offlinePermitKey);
      _storage.remove(Constants.balanceKey);
    } catch (e) {
      throw LocalStorageException('Failed to delete user: $e');
    }
  }
}
