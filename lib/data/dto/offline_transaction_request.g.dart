// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_transaction_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineTransactionRequest _$OfflineTransactionRequestFromJson(
  Map<String, dynamic> json,
) => OfflineTransactionRequest(
  id: json['id'] as String,
  senderId: json['senderId'] as String,
  receiverId: json['receiverId'] as String,
  amount: (json['amount'] as num).toDouble(),
  timestamp: json['timestamp'] as String,
  signature: json['signature'] as String,
);

Map<String, dynamic> _$OfflineTransactionRequestToJson(
  OfflineTransactionRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'receiverId': instance.receiverId,
  'amount': instance.amount,
  'timestamp': instance.timestamp,
  'signature': instance.signature,
};
