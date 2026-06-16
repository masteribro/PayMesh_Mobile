import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/dto/auth_response.dart';
import '../../../data/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc()
      : _authService = AuthService(),
        super(AuthInitial()) {
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
  }

  Future<void> _onLogin(
      LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authService.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(response: response, title: 'Login Successful'));
    } on DioException catch (e) {
      final data = e.response?.data;
      emit(AuthFailure(
        title: 'Login Failed',
        body: {
          'status': e.response?.statusCode ?? 'N/A',
          'message': e.message ?? 'Unknown error',
          if (data is Map) ...Map<String, dynamic>.from(data),
          if (data is String) 'raw': data,
        },
      ));
    } catch (e) {
      emit(AuthFailure(
          title: 'Login Failed', body: {'message': e.toString()}));
    }
  }

  Future<void> _onRegister(
      RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authService.register(
        email: event.email,
        username: event.username,
        password: event.password,
        publicKey: event.publicKey,
        initialBalance: 1000.0,
      );
      emit(AuthSuccess(response: response, title: 'Account Created'));
    } on DioException catch (e) {
      final data = e.response?.data;
      emit(AuthFailure(
        title: 'Registration Failed',
        body: {
          'status': e.response?.statusCode ?? 'N/A',
          'message': e.message ?? 'Unknown error',
          if (data is Map) ...Map<String, dynamic>.from(data),
          if (data is String) 'raw': data,
        },
      ));
    } catch (e) {
      emit(AuthFailure(
          title: 'Registration Failed',
          body: {'message': e.toString()}));
    }
  }
}
