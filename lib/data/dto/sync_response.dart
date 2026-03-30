import 'package:json_annotation/json_annotation.dart';
import 'transaction_response.dart';

part 'sync_response.g.dart';

@JsonSerializable()
class SyncResponse {
  final List<TransactionResponse> accepted;
  final List<TransactionResponse> conflicts;
  final String message;

  SyncResponse({
    required this.accepted,
    required this.conflicts,
    required this.message,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SyncResponseToJson(this);
}
