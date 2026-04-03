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
  GenericException(super.message);
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Network error occurred']);
}

class ServerException extends AppException {
  final int? statusCode;
  ServerException(super.message, {this.statusCode});
}

class AuthenticationException extends AppException {
  AuthenticationException([super.message = 'Authentication failed']);
}

class ValidationException extends AppException {
  final Map<String, String>? errors;
  ValidationException(super.message, {this.errors});
}

class OfflineException extends AppException {
  OfflineException([super.message = 'No internet connection']);
}

class LocalStorageException extends AppException {
  LocalStorageException([super.message = 'Local storage error']);
}

class BluetoothException extends AppException {
  BluetoothException([super.message = 'Bluetooth error']);
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
