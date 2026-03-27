import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: 'id')
  final String userId;
  
  final String email;
  final String username;
  final double balance;
  
  @JsonKey(name: 'pendingOfflineAmount')
  final double pendingOfflineAmount;
  
  @JsonKey(name: 'pendingOfflineTransactionCount')
  final int pendingOfflineTransactionCount;
  
  @JsonKey(name: 'isActive')
  final bool isActive;
  
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.balance,
    this.pendingOfflineAmount = 0.0,
    this.pendingOfflineTransactionCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get available balance (excluding pending transactions)
  double get availableBalance => balance - pendingOfflineAmount;

  /// Check if user can perform offline transaction
  bool canPerformOfflineTransaction(double amount) {
    return availableBalance >= amount;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? userId,
    String? email,
    String? username,
    double? balance,
    double? pendingOfflineAmount,
    int? pendingOfflineTransactionCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      balance: balance ?? this.balance,
      pendingOfflineAmount: pendingOfflineAmount ?? this.pendingOfflineAmount,
      pendingOfflineTransactionCount:
          pendingOfflineTransactionCount ?? this.pendingOfflineTransactionCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserModel(userId: $userId, email: $email, '
      'username: $username, balance: $balance, '
      'pendingOfflineAmount: $pendingOfflineAmount)';
}
