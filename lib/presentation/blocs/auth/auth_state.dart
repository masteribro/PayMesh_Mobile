part of 'auth_bloc.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final AuthResponse response;
  final String title;
  AuthSuccess({required this.response, required this.title});
}

class AuthFailure extends AuthState {
  final String title;
  final Map<String, dynamic> body;
  AuthFailure({required this.title, required this.body});
}
