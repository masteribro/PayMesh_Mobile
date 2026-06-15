import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../dto/offline_transaction_request.dart';
import '../dto/sync_response.dart';
import '../dto/sync_transactions_request.dart';
import 'api_client.dart';
import 'api_constants.dart';

/// Manages transactions received from another PayMesh user via offline QR scan.
///
/// BACKEND NOTE: The sync endpoint (POST /transactions/sync) will be called by
/// BOTH the sender (outgoing) and the recipient (incoming) for the same transaction.
/// Your backend MUST be idempotent on transaction ID — if a transaction with the
/// same `id` arrives twice, process it once and return success for both calls.
class IncomingTransactionService {
  static final IncomingTransactionService _instance =
      IncomingTransactionService._internal();
  factory IncomingTransactionService() => _instance;
  IncomingTransactionService._internal();

  static const String _key = 'paymesh_incoming_transactions';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();

  /// Save an incoming payment received via QR scan.
  /// Silently ignores duplicate transaction IDs.
  Future<void> saveIncoming({
    required String id,
    required String senderId,
    required String receiverId,
    required double amount,
    required String timestamp,
    required String signature,
  }) async {
    final existing = await getAll();
    if (existing.any((t) => t.id == id)) return; // deduplicate

    final tx = OfflineTransactionRequest(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      timestamp: timestamp,
      signature: signature,
    );
    existing.add(tx);
    await _write(existing);
  }

  /// Returns all locally-stored incoming pending transactions.
  Future<List<OfflineTransactionRequest>> getAll() async {
    try {
      final str = await _storage.read(key: _key);
      if (str == null || str.isEmpty) return [];
      final list = jsonDecode(str) as List<dynamic>;
      return list
          .map((e) => OfflineTransactionRequest.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns the total amount across all pending incoming transactions.
  Future<double> totalPendingAmount() async {
    final all = await getAll();
    return all.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Sync all incoming transactions to the backend using the same sync endpoint.
  ///
  /// BACKEND NOTE: The `userId` here is the RECIPIENT's ID, not the sender's.
  /// Your backend should look up the transaction by `id`, and if it already
  /// exists (submitted by the sender), return it in the `accepted` list
  /// without reprocessing.
  Future<SyncResponse> syncAll(String userId) async {
    final pending = await getAll();
    if (pending.isEmpty) {
      return SyncResponse(
        accepted: [],
        conflicts: [],
        message: 'No incoming transactions to sync',
      );
    }

    final request = SyncTransactionsRequest(
      userId: userId,
      transactions: pending,
    );

    final response = await _apiClient.post(
      ApiConstants.syncTransactions,
      data: request.toJson(),
    );
    final syncResponse = SyncResponse.fromJson(response.data);

    // Remove accepted transactions; keep conflicts for retry
    final acceptedIds =
        syncResponse.accepted.map((a) => a.id).toSet();
    final remaining =
        pending.where((t) => !acceptedIds.contains(t.id)).toList();
    await _write(remaining);

    return syncResponse;
  }

  Future<void> _write(List<OfflineTransactionRequest> transactions) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
  }
}
