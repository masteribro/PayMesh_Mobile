import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String username;
  final String password;
  final String publicKey;
  final double initialBalance;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    required this.publicKey,
    required this.initialBalance,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
