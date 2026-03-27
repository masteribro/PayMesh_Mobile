class Constants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8080';
  static const String apiV1 = '$baseUrl/api/v1';
  
  // API Endpoints
  static const String authRegister = '$apiV1/auth/register';
  static const String authLogin = '$apiV1/auth/login';
  static const String userProfile = '$apiV1/users';
  static const String transactionsSync = '$apiV1/transactions/sync';
  static const String offlineAllowance = '$apiV1/transactions/offline-allowance';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String offlineTransactionsKey = 'offline_transactions';
  static const String offlinePermitKey = 'offline_permit';
  static const String balanceKey = 'user_balance';
  
  // Offline Payment Limits
  static const double maxOfflineBalance = 50000.0;
  static const double maxSingleTransaction = 5000.0;
  static const int maxOfflineTransactions = 10;
  static const int offlineTokenExpiryHours = 24;
  
  // Timeout Durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);
  
  // Bluetooth Constants
  static const String bluetoothServiceUuid = '550e8400-e29b-41d4-a716-446655440000';
  static const String transactionCharacteristicUuid = '550e8400-e29b-41d4-a716-446655440001';
  static const String balanceCharacteristicUuid = '550e8400-e29b-41d4-a716-446655440002';
  
  // NFC Constants
  static const String nfcTagType = 'com.paymesh.transaction';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int minUsernameLength = 3;
  static const Pattern emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
