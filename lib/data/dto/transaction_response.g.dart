// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionResponse _$TransactionResponseFromJson(Map<String, dynamic> json) =>
    TransactionResponse(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
      conflictReason: json['conflictReason'] as String?,
    );

Map<String, dynamic> _$TransactionResponseToJson(
  TransactionResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'receiverId': instance.receiverId,
  'amount': instance.amount,
  'timestamp': instance.timestamp.toIso8601String(),
  'status': instance.status,
  'syncedAt': instance.syncedAt?.toIso8601String(),
  'conflictReason': instance.conflictReason,
};
