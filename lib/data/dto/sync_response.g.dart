// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) => SyncResponse(
  accepted: (json['accepted'] as List<dynamic>)
      .map((e) => TransactionResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  conflicts: (json['conflicts'] as List<dynamic>)
      .map((e) => TransactionResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  message: json['message'] as String,
);

Map<String, dynamic> _$SyncResponseToJson(SyncResponse instance) =>
    <String, dynamic>{
      'accepted': instance.accepted,
      'conflicts': instance.conflicts,
      'message': instance.message,
    };
