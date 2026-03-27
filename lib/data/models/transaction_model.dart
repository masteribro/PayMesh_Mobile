import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String id;
  
  @JsonKey(name: 'senderId')
  final String senderId;
  
  @JsonKey(name: 'receiverId')
  final String receiverId;
  
  final double amount;
  final DateTime timestamp;
  final String signature;
  final String status; // PENDING_SYNC, COMPLETED, FAILED, CONFLICT, DOUBLE_SPEND_DETECTED
  
  @JsonKey(name: 'prevHash')
  final String? prevHash;
  
  @JsonKey(name: 'currentHash')
  final String? currentHash;
  
  @JsonKey(name: 'isSpent')
  final bool isSpent;
  
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  
  @JsonKey(name: 'syncedAt')
  final DateTime? syncedAt;
  
  @JsonKey(name: 'conflictReason')
  final String? conflictReason;

  TransactionModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.timestamp,
    required this.signature,
    this.status = 'PENDING_SYNC',
    this.prevHash,
    this.currentHash,
    this.isSpent = false,
    required this.createdAt,
    this.syncedAt,
    this.conflictReason,
  });

  /// Check if transaction is pending sync
  bool get isPendingSync => status == 'PENDING_SYNC';

  /// Check if transaction is completed
  bool get isCompleted => status == 'COMPLETED';

  /// Check if transaction has conflict
  bool get hasConflict =>
      status == 'CONFLICT' ||
      status == 'FAILED' ||
      status == 'DOUBLE_SPEND_DETECTED';

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  TransactionModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    double? amount,
    DateTime? timestamp,
    String? signature,
    String? status,
    String? prevHash,
    String? currentHash,
    bool? isSpent,
    DateTime? createdAt,
    DateTime? syncedAt,
    String? conflictReason,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      status: status ?? this.status,
      prevHash: prevHash ?? this.prevHash,
      currentHash: currentHash ?? this.currentHash,
      isSpent: isSpent ?? this.isSpent,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      conflictReason: conflictReason ?? this.conflictReason,
    );
  }

  @override
  String toString() => 'TransactionModel(id: $id, senderId: $senderId, '
      'receiverId: $receiverId, amount: $amount, status: $status)';
}
