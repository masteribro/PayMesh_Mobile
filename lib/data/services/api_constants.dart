class ApiConstants {
  // Backend base URL - Change this to your backend URL
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator
  // For physical device, use: 'http://YOUR_BACKEND_IP:8080/api/v1'

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  // Transaction endpoints
  static const String syncTransactions = '$baseUrl/transactions/sync';
  static const String getOfflineAllowance = '$baseUrl/transactions/offline-allowance';
  static const String createTransaction = '$baseUrl/transactions/create';

  // User endpoints
  static const String getUserProfile = '$baseUrl/users/profile';

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
