class ApiConstants {
  // Backend base URL - Change this to your backend URL
  static const String baseUrl = 'http://192.168.210.185:8080/api/v1'; // iOS simulator (explicit IPv4)
  // For Android emulator, use: 'http://10.0.2.2:8080/api/v1'
  // For physical device, use: 'http://YOUR_MACHINE_LOCAL_IP:8080/api/v1'

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
