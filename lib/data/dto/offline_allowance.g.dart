// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_allowance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineAllowance _$OfflineAllowanceFromJson(Map<String, dynamic> json) =>
    OfflineAllowance(
      maxAmount: (json['maxAmount'] as num).toDouble(),
      maxTransactions: (json['maxTransactions'] as num).toInt(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
    );

Map<String, dynamic> _$OfflineAllowanceToJson(OfflineAllowance instance) =>
    <String, dynamic>{
      'maxAmount': instance.maxAmount,
      'maxTransactions': instance.maxTransactions,
      'currentBalance': instance.currentBalance,
    };
