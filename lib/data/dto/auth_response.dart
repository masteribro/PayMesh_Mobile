import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String token;
  final String userId;
  final String username;
  final String email;
  final double balance;
  final double pendingOfflineAmount;
  final int pendingOfflineTransactionCount;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
    required this.balance,
    required this.pendingOfflineAmount,
    required this.pendingOfflineTransactionCount,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  AuthResponse copyWith({
    String? token,
    String? userId,
    String? username,
    String? email,
    double? balance,
    double? pendingOfflineAmount,
    int? pendingOfflineTransactionCount,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      pendingOfflineAmount: pendingOfflineAmount ?? this.pendingOfflineAmount,
      pendingOfflineTransactionCount:
          pendingOfflineTransactionCount ?? this.pendingOfflineTransactionCount,
    );
  }
}
