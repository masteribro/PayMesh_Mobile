abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;

  /// Factory constructor to create AppException from any exception
  factory AppException.fromException(dynamic e) {
    if (e is AppException) {
      return e;
    } else if (e is Exception) {
      return GenericException(e.toString());
    } else {
      return GenericException(e.toString());
    }
  }
}

class GenericException extends AppException {
  GenericException(String message) : super(message);
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred'])
      : super(message);
}

class ServerException extends AppException {
  final int? statusCode;
  ServerException(String message, {this.statusCode}) : super(message);
}

class AuthenticationException extends AppException {
  AuthenticationException([String message = 'Authentication failed'])
      : super(message);
}

class ValidationException extends AppException {
  final Map<String, String>? errors;
  ValidationException(String message, {this.errors}) : super(message);
}

class OfflineException extends AppException {
  OfflineException([String message = 'No internet connection'])
      : super(message);
}

class LocalStorageException extends AppException {
  LocalStorageException([String message = 'Local storage error'])
      : super(message);
}

class BluetoothException extends AppException {
  BluetoothException([String message = 'Bluetooth error']) : super(message);
}

class InsufficientFundsException extends AppException {
  final double required;
  final double available;
  InsufficientFundsException({
    required this.required,
    required this.available,
  }) : super(
          'Insufficient funds. Required: $required, Available: $available',
        );
}

class DoubleSpendsException extends AppException {
  final List<String> conflictTransactionIds;
  DoubleSpendsException(this.conflictTransactionIds)
      : super(
          'Double spending detected for ${conflictTransactionIds.length} transactions',
        );
}
