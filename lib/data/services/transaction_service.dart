import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../dto/offline_transaction_request.dart';
import '../dto/offline_allowance.dart';
import '../dto/sync_response.dart';
import '../dto/sync_transactions_request.dart';
import 'api_client.dart';
import 'api_constants.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory TransactionService() {
    return _instance;
  }

  TransactionService._internal();

  static const String _pendingTransactionsKey = 'paymesh_pending_transactions';

  /// Create and store offline transaction
  Future<void> createOfflineTransaction({
    required String id,
    required String senderId,
    required String receiverId,
    required double amount,
    required String timestamp,
    required String signature,
  }) async {
    try {
      final transaction = OfflineTransactionRequest(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        timestamp: timestamp,
        signature: signature,
      );

      // Store transaction locally
      final pendingTransactions = await getPendingTransactions();
      pendingTransactions.add(transaction);
      await _savePendingTransactions(pendingTransactions);

      print('[v0] Offline transaction created: $id');
    } catch (e) {
      print('[v0] Create offline transaction error: $e');
      rethrow;
    }
  }

  /// Get pending offline transactions
  Future<List<OfflineTransactionRequest>> getPendingTransactions() async {
    try {
      final jsonStr = await _secureStorage.read(
        key: _pendingTransactionsKey,
      );

      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((item) => OfflineTransactionRequest.fromJson(
              item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[v0] Get pending transactions error: $e');
      return [];
    }
  }

  /// Sync pending transactions with backend
  Future<SyncResponse> syncTransactions({
    required String userId,
    String? merkleRoot,
  }) async {
    try {
      final pendingTransactions = await getPendingTransactions();

      if (pendingTransactions.isEmpty) {
        return SyncResponse(
          accepted: [],
          conflicts: [],
          message: 'No pending transactions to sync',
        );
      }

      final syncRequest = SyncTransactionsRequest(
        userId: userId,
        transactions: pendingTransactions,
        merkleRoot: merkleRoot,
      );

      final response = await _apiClient.post(
        ApiConstants.syncTransactions,
        data: syncRequest.toJson(),
      );

      final syncResponse = SyncResponse.fromJson(response.data);

      // Clear synced transactions from local storage
      final remainingTransactions = pendingTransactions
          .where((tx) =>
              syncResponse.conflicts.any((conflict) => conflict.id == tx.id))
          .toList();

      await _savePendingTransactions(remainingTransactions);

      print('[v0] Sync completed: ${syncResponse.message}');
      return syncResponse;
    } catch (e) {
      print('[v0] Sync transactions error: $e');
      rethrow;
    }
  }

  /// Get offline allowance for user
  Future<OfflineAllowance> getOfflineAllowance({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getOfflineAllowance,
        queryParameters: {'userId': userId},
      );

      final allowance = OfflineAllowance.fromJson(response.data);
      print('[v0] Offline allowance retrieved: ${allowance.maxAmount}');
      return allowance;
    } catch (e) {
      print('[v0] Get offline allowance error: $e');
      rethrow;
    }
  }

  /// Clear pending transactions
  Future<void> clearPendingTransactions() async {
    try {
      await _secureStorage.delete(key: _pendingTransactionsKey);
      print('[v0] Pending transactions cleared');
    } catch (e) {
      print('[v0] Clear pending transactions error: $e');
      rethrow;
    }
  }

  /// Save pending transactions to secure storage
  Future<void> _savePendingTransactions(
    List<OfflineTransactionRequest> transactions,
  ) async {
    try {
      final jsonList = transactions.map((tx) => tx.toJson()).toList();
      final jsonStr = jsonEncode(jsonList);
      await _secureStorage.write(
        key: _pendingTransactionsKey,
        value: jsonStr,
      );
    } catch (e) {
      print('[v0] Save pending transactions error: $e');
      rethrow;
    }
  }
}
