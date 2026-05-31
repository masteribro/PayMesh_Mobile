import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exception.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._internal();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  factory LocalDataSource() => _instance;
  LocalDataSource._internal();

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: Constants.tokenKey, value: token);
    } catch (e) {
      throw LocalStorageException('Failed to save token: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: Constants.tokenKey);
    } catch (e) {
      throw LocalStorageException('Failed to read token: $e');
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _storage.write(
        key: Constants.userKey,
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      throw LocalStorageException('Failed to save user: $e');
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final raw = await _storage.read(key: Constants.userKey);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      throw LocalStorageException('Failed to read user: $e');
    }
  }

  Future<void> saveOfflineTransactions(List<TransactionModel> transactions) async {
    try {
      await _storage.write(
        key: Constants.offlineTransactionsKey,
        value: jsonEncode(transactions.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      throw LocalStorageException('Failed to save offline transactions: $e');
    }
  }

  Future<List<TransactionModel>> getOfflineTransactions() async {
    try {
      final raw = await _storage.read(key: Constants.offlineTransactionsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw LocalStorageException('Failed to read offline transactions: $e');
    }
  }

  Future<void> saveOfflinePermit(Map<String, dynamic> permit) async {
    try {
      await _storage.write(
        key: Constants.offlinePermitKey,
        value: jsonEncode(permit),
      );
    } catch (e) {
      throw LocalStorageException('Failed to save offline permit: $e');
    }
  }

  Future<Map<String, dynamic>?> getOfflinePermit() async {
    try {
      final raw = await _storage.read(key: Constants.offlinePermitKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw LocalStorageException('Failed to read offline permit: $e');
    }
  }

  Future<void> saveBalance(double balance) async {
    try {
      await _storage.write(
        key: Constants.balanceKey,
        value: balance.toString(),
      );
    } catch (e) {
      throw LocalStorageException('Failed to save balance: $e');
    }
  }

  Future<double?> getBalance() async {
    try {
      final raw = await _storage.read(key: Constants.balanceKey);
      if (raw == null) return null;
      return double.tryParse(raw);
    } catch (e) {
      throw LocalStorageException('Failed to read balance: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw LocalStorageException('Failed to clear storage: $e');
    }
  }

  Future<void> deleteKey(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw LocalStorageException('Failed to delete key: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await Future.wait([
        _storage.delete(key: Constants.userKey),
        _storage.delete(key: Constants.tokenKey),
        _storage.delete(key: Constants.offlineTransactionsKey),
        _storage.delete(key: Constants.offlinePermitKey),
        _storage.delete(key: Constants.balanceKey),
      ]);
    } catch (e) {
      throw LocalStorageException('Failed to delete user: $e');
    }
  }
}
