// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_transactions_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncTransactionsRequest _$SyncTransactionsRequestFromJson(
  Map<String, dynamic> json,
) => SyncTransactionsRequest(
  userId: json['userId'] as String,
  transactions: (json['transactions'] as List<dynamic>)
      .map((e) => OfflineTransactionRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
  merkleRoot: json['merkleRoot'] as String?,
);

Map<String, dynamic> _$SyncTransactionsRequestToJson(
  SyncTransactionsRequest instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'transactions': instance.transactions,
  'merkleRoot': instance.merkleRoot,
};
