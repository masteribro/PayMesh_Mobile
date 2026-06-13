class ApiConstants {
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.1.8',
  );
  static const String baseUrl = 'http://$_host:8080/api/v1';

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  static const String usersBase = '$baseUrl/users';
  static const String syncTransactions = '$baseUrl/transactions/sync';
  static const String offlineAllowanceBase = '$baseUrl/transactions/offline-allowance';
  static const String sendMoney = '$baseUrl/transactions/send';
  static const String transactionHistoryBase = '$baseUrl/transactions/history';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
