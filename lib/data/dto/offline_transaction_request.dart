import 'package:json_annotation/json_annotation.dart';

part 'offline_transaction_request.g.dart';

@JsonSerializable()
class OfflineTransactionRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final String timestamp;
  final String signature;

  OfflineTransactionRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.timestamp,
    required this.signature,
  });

  factory OfflineTransactionRequest.fromJson(Map<String, dynamic> json) =>
      _$OfflineTransactionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OfflineTransactionRequestToJson(this);
}
