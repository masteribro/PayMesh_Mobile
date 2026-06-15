import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../dto/offline_transaction_request.dart';
import '../dto/offline_allowance.dart';
import '../dto/sync_response.dart';
import '../dto/sync_transactions_request.dart';
import '../dto/transaction_response.dart';
import '../models/transaction_model.dart';
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

  Future<void> createOfflineTransaction({
    required String id,
    required String senderId,
    required String receiverId,
    required double amount,
    required String timestamp,
    required String signature,
  }) async {
    final transaction = OfflineTransactionRequest(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      timestamp: timestamp,
      signature: signature,
    );

    final pendingTransactions = await getPendingTransactions();
    pendingTransactions.add(transaction);
    await _savePendingTransactions(pendingTransactions);
  }

  Future<List<OfflineTransactionRequest>> getPendingTransactions() async {
    try {
      final jsonStr = await _secureStorage.read(key: _pendingTransactionsKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((item) => OfflineTransactionRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SyncResponse> syncTransactions({
    required String userId,
    String? merkleRoot,
  }) async {
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

    final remainingTransactions = pendingTransactions
        .where((tx) => syncResponse.conflicts.any((c) => c.id == tx.id))
        .toList();

    await _savePendingTransactions(remainingTransactions);
    return syncResponse;
  }

  Future<TransactionResponse> sendMoneyOnline({
    required String senderId,
    required String receiverId,
    required double amount,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      if (description != null) 'description': description,
    };
    final response = await _apiClient.post(ApiConstants.sendMoney, data: body);
    return TransactionResponse.fromJson(response.data);
  }

  Future<OfflineAllowance> getOfflineAllowance({required String userId}) async {
    final response = await _apiClient.get(
      '${ApiConstants.offlineAllowanceBase}/$userId',
    );
    return OfflineAllowance.fromJson(response.data);
  }

  /// Fetch the confirmed transaction history for a user from the backend.
  /// Returns an empty list if the network is unavailable.
  Future<List<TransactionModel>> getTransactionHistory(String userId) async {
    try {
      final response = await _apiClient
          .get('${ApiConstants.transactionHistoryBase}/$userId');
      final list = response.data as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return TransactionModel(
          id: m['id'] as String,
          senderId: m['senderId'] as String,
          receiverId: m['receiverId'] as String,
          amount: (m['amount'] as num).toDouble(),
          timestamp: DateTime.parse(m['timestamp'] as String),
          signature: '',
          status: m['status'] as String,
          syncedAt: m['syncedAt'] != null
              ? DateTime.parse(m['syncedAt'] as String)
              : null,
          createdAt: DateTime.parse(m['timestamp'] as String),
          conflictReason: m['conflictReason'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Convert a locally-stored pending request to a [TransactionModel].
  TransactionModel pendingToModel(OfflineTransactionRequest r) {
    final ts = DateTime.tryParse(r.timestamp) ?? DateTime.now();
    return TransactionModel(
      id: r.id,
      senderId: r.senderId,
      receiverId: r.receiverId,
      amount: r.amount,
      timestamp: ts,
      signature: r.signature,
      status: 'PENDING_SYNC',
      createdAt: ts,
    );
  }

  Future<void> clearPendingTransactions() async {
    await _secureStorage.delete(key: _pendingTransactionsKey);
  }

  Future<void> _savePendingTransactions(
    List<OfflineTransactionRequest> transactions,
  ) async {
    await _secureStorage.write(
      key: _pendingTransactionsKey,
      value: jsonEncode(transactions.map((tx) => tx.toJson()).toList()),
    );
  }
}
