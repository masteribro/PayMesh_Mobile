class ApiConstants {
  static const String baseUrl = 'http://192.168.210.185:8080/api/v1';

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  static const String syncTransactions = '$baseUrl/transactions/sync';
  static const String offlineAllowanceBase = '$baseUrl/transactions/offline-allowance';
  static const String sendMoney = '$baseUrl/transactions/send';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
