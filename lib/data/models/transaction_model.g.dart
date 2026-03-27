// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String,
      status: json['status'] as String? ?? 'PENDING_SYNC',
      prevHash: json['prevHash'] as String?,
      currentHash: json['currentHash'] as String?,
      isSpent: json['isSpent'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
      conflictReason: json['conflictReason'] as String?,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'amount': instance.amount,
      'timestamp': instance.timestamp.toIso8601String(),
      'signature': instance.signature,
      'status': instance.status,
      'prevHash': instance.prevHash,
      'currentHash': instance.currentHash,
      'isSpent': instance.isSpent,
      'createdAt': instance.createdAt.toIso8601String(),
      'syncedAt': instance.syncedAt?.toIso8601String(),
      'conflictReason': instance.conflictReason,
    };
