// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  token: json['token'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  balance: (json['balance'] as num).toDouble(),
  pendingOfflineAmount: (json['pendingOfflineAmount'] as num).toDouble(),
  pendingOfflineTransactionCount:
      (json['pendingOfflineTransactionCount'] as num).toInt(),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'username': instance.username,
      'email': instance.email,
      'balance': instance.balance,
      'pendingOfflineAmount': instance.pendingOfflineAmount,
      'pendingOfflineTransactionCount': instance.pendingOfflineTransactionCount,
    };
