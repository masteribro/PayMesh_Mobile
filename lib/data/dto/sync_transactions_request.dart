import 'package:json_annotation/json_annotation.dart';
import 'offline_transaction_request.dart';

part 'sync_transactions_request.g.dart';

@JsonSerializable()
class SyncTransactionsRequest {
  final String userId;
  final List<OfflineTransactionRequest> transactions;
  final String? merkleRoot;

  SyncTransactionsRequest({
    required this.userId,
    required this.transactions,
    this.merkleRoot,
  });

  factory SyncTransactionsRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncTransactionsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SyncTransactionsRequestToJson(this);
}
