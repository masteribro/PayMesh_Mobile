import '../../core/exceptions/app_exception.dart';
import '../../data/models/auth_response_model.dart';


/// State holder for auth operations
class AuthState {
  final bool isLoading;
  final AuthResponseModel? authResponse;
  final AppException? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.authResponse,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthResponseModel? authResponse,
    AppException? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      authResponse: authResponse ?? this.authResponse,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
