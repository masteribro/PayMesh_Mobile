class AuthResponseModel {
  final String token;
  final String userId;
  final String username;
  final String email;
  final double balance;
  final double pendingOfflineAmount;
  final int pendingOfflineTransactionCount;

  AuthResponseModel({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
    required this.balance,
    this.pendingOfflineAmount = 0.0,
    this.pendingOfflineTransactionCount = 0,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      balance: (json['balance'] as num).toDouble(),
      pendingOfflineAmount: (json['pendingOfflineAmount'] as num?)?.toDouble() ?? 0.0,
      pendingOfflineTransactionCount: json['pendingOfflineTransactionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'username': username,
    'email': email,
    'balance': balance,
    'pendingOfflineAmount': pendingOfflineAmount,
    'pendingOfflineTransactionCount': pendingOfflineTransactionCount,
  };
}
