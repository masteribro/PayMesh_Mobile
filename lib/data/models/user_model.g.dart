// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  userId: json['id'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  balance: (json['balance'] as num).toDouble(),
  pendingOfflineAmount:
      (json['pendingOfflineAmount'] as num?)?.toDouble() ?? 0.0,
  pendingOfflineTransactionCount:
      (json['pendingOfflineTransactionCount'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.userId,
  'email': instance.email,
  'username': instance.username,
  'balance': instance.balance,
  'pendingOfflineAmount': instance.pendingOfflineAmount,
  'pendingOfflineTransactionCount': instance.pendingOfflineTransactionCount,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
