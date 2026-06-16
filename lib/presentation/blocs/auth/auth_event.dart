part of 'auth_bloc.dart';

sealed class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String username;
  final String password;
  final String publicKey;
  RegisterSubmitted({
    required this.email,
    required this.username,
    required this.password,
    required this.publicKey,
  });
}
