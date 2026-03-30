## PayMesh Mobile - Flutter Implementation

Complete Flutter frontend implementation for the PayMesh offline-first wallet application, fully integrated with the Java Spring Boot backend.

### Backend Integration

The mobile app connects to your Spring Boot backend with the following services:

#### Authentication Service (`lib/data/services/auth_service.dart`)
- **Register**: Create new user accounts with email, username, password, and initial balance
- **Login**: Authenticate users and store JWT tokens securely
- **Session Management**: Automatic session restoration on app launch
- **Secure Storage**: Uses Flutter Secure Storage to protect sensitive data

#### Transaction Service (`lib/data/services/transaction_service.dart`)
- **Offline Transactions**: Create and store transactions locally when offline
- **Sync Mechanism**: Sync pending transactions with backend when connectivity is restored
- **Conflict Resolution**: Handle transaction conflicts and double-spend detection
- **Offline Allowance**: Check available offline transaction limits

### Architecture

#### Data Layer
- **DTOs**: Complete data models matching backend (AuthResponse, LoginRequest, OfflineAllowance, etc.)
- **API Client**: Singleton Dio HTTP client with JWT token management and error handling
- **Services**: AuthService and TransactionService for business logic

#### Presentation Layer
- **Splash Screen**: App initialization and session restoration
- **Authentication Screens**: Login and Registration with form validation
- **Main Navigation**: Home, Send Money, and Transaction History screens
- **State Management**: Stateful widgets with form state handling

#### Models
- User profiles with balance and offline transaction tracking
- Transactions with status tracking (PENDING_SYNC, COMPLETED, FAILED, CONFLICT, DOUBLE_SPEND_DETECTED)
- Offline permits and digital tokens for cryptographic verification

### Setup Instructions

1. **Update API Base URL**
   ```dart
   // In lib/data/services/api_constants.dart
   static const String baseUrl = 'http://YOUR_BACKEND_IP:8080/api/v1';
   ```

2. **Add Dependencies to pubspec.yaml**
   ```yaml
   dependencies:
     dio: ^5.3.0
     flutter_secure_storage: ^9.0.0
     json_annotation: ^4.8.0
     crypto: ^3.0.0
     
   dev_dependencies:
     build_runner: ^2.4.0
     json_serializable: ^6.7.0
   ```

3. **Generate JSON Serialization Code**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

### Features

#### Authentication
- User registration with validation
- Secure login with JWT tokens
- Automatic session restoration
- Logout functionality

#### Home Screen
- Display user balance and profile
- Show offline/online status
- Display pending transactions
- Quick action buttons for sync and request

#### Send Money
- Select payment method (NFC or Bluetooth)
- Enter recipient and amount
- Create transactions with cryptographic signing
- Support for offline and online payments
- Fee calculation and total display

#### Transaction History
- View all transactions with filtering
- Color-coded transaction types (sent, received)
- Status indicators (pending, synced, failed)
- Expandable transaction details

#### Offline Support
- Local storage of transactions when offline
- Automatic sync when connection restored
- Conflict detection and resolution
- Merkle tree verification for batch transactions

### API Endpoints Used

```
POST /api/v1/auth/register     - User registration
POST /api/v1/auth/login        - User login
POST /api/v1/transactions/sync - Sync pending transactions
GET  /api/v1/transactions/offline-allowance - Get offline limits
```

### Security Features

- JWT token-based authentication
- Secure token storage with flutter_secure_storage
- Password hashing with bcrypt (backend)
- Cryptographic transaction signing
- HTTPS support ready
- Input validation on all forms

### File Structure

```
lib/
├── main.dart
├── data/
│   ├── services/
│   │   ├── api_client.dart
│   │   ├── api_constants.dart
│   │   ├── auth_service.dart
│   │   └── transaction_service.dart
│   ├── dto/
│   │   ├── auth_response.dart
│   │   ├── login_request.dart
│   │   ├── register_request.dart
│   │   ├── offline_transaction_request.dart
│   │   ├── offline_allowance.dart
│   │   ├── sync_response.dart
│   │   ├── sync_transactions_request.dart
│   │   └── transaction_response.dart
│   ├── repository/
│   ├── models/
│   └── datasources/
├── domain/
│   ├── entities/
│   └── utils/
└── presentation/
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── home_screen.dart
    │   ├── send_money_screen.dart
    │   └── transaction_history_screen.dart
    ├── widgets/
    └── states/
```

### Next Steps

1. Implement NFC/Bluetooth communication
2. Add digital token generation and verification
3. Implement offline signature verification
4. Add more detailed transaction analytics
5. Implement push notifications for sync events
6. Add biometric authentication
7. Implement transaction export/reporting

### Backend Configuration

Ensure your Spring Boot backend has:
- CORS enabled for mobile client
- JWT secret configured
- Transaction sync validation implemented
- User balance management
- Offline allowance configuration

```properties
# application.properties
jwt.secret=your-secret-key-here
jwt.expiration=86400000
payment.max-offline-balance=5000
payment.max-single-offline-transaction=1000
payment.max-offline-transactions=50
```

### Troubleshooting

**Connection Refused**: Update the base URL in api_constants.dart to match your backend IP
**Token Expired**: Implement token refresh logic in auth_service.dart
**Sync Failures**: Check backend transaction validation and error responses
**Storage Errors**: Ensure secure storage permissions are configured in Android/iOS

---

For more information about the backend, see the PayMesh backend documentation.
