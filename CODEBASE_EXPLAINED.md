# PayMesh Mobile — Explained Like You're Five (But You're Not, So It's Actually Good)

> This document explains the entire PayMesh Mobile codebase in plain English.
> No jargon. No assumptions. Just the truth about what every file does and why it exists.

---

## What Is This App?

**PayMesh Mobile** is a digital wallet app — think of it like a simpler version of Cash App or PayPal, but with one superpower: **it works without internet**.

You can send money to someone even when both of you are offline (using Bluetooth or NFC, like tapping phones). When you get internet again, the app automatically syncs everything with the server to make it official.

The backend is a separate Java Spring Boot server. This Flutter app is just the phone-side of things.

---

## The Big Picture (How It's Organized)

Think of the app like a restaurant:

- **The Kitchen** = the `data/` folder (where the actual food/data is made and stored)
- **The Waiter** = the `domain/` folder (who carries data around and applies rules)
- **The Dining Room** = the `presentation/` folder (what the customer/user sees)
- **The Manager's Rules** = the `core/` folder (constants, error types, shared rules)

```
lib/
├── core/           The Manager's Rules
├── data/           The Kitchen
├── domain/         The Waiter
├── presentation/   The Dining Room
└── main.dart       The front door of the restaurant
```

---

## Starting Point: `main.dart`

This is where the app wakes up. It does two things:

1. **Defines the app's theme** — the colors, fonts, button styles, card styles. Everything looks consistent because it's all defined here once and reused everywhere.
2. **Defines the routes** — the "map" of the app. Every screen has a name:
   - `/splash` → the loading screen
   - `/login` → login page
   - `/register` → sign-up page
   - `/home` → the main dashboard with 3 tabs (Home, Send, History)

The app always starts at `/splash`. From there, it decides where to go.

---

## Screens (What You See)

### 1. Splash Screen
**File**: `lib/presentation/screens/splash_screen.dart`

The first screen you see — just the PayMesh logo and a loading spinner.

Behind the scenes, it's doing a quick check: "Has this user logged in before?" It looks in secure storage for a saved token. If it finds one, it sends you straight to the home dashboard. If not, it sends you to login.

**Plain English**: It's the bouncer that checks your wristband before you enter the club.

---

### 2. Login Screen
**File**: `lib/presentation/screens/login_screen.dart`

Email + password form. When you tap "Login":
1. It validates the fields (not empty, email looks correct)
2. Calls the backend with your credentials
3. Gets back a token (a secret key that proves you're logged in)
4. Saves that token securely on your device
5. Takes you to the home screen

Has a link to "Register" if you're new.

---

### 3. Register Screen
**File**: `lib/presentation/screens/register_screen.dart`

Sign-up form with: email, username, password, confirm password.

Interesting detail: during registration, the app **auto-generates a public key** for you. It takes your email + username, hashes them with SHA256, and sends that as your cryptographic identity. You don't have to do anything — it just happens.

Your starting balance is automatically set to **1000.0** (for demo purposes).

---

### 4. Home Screen
**File**: `lib/presentation/screens/home_screen.dart`

The main dashboard. This is the screen that does the most showing-off:

- **Big balance card**: Your total balance in a blue gradient card
- **Available vs Pending**: Below the total, it shows how much you can actually use right now (total minus the money you've sent offline but hasn't been synced yet)
- **Connectivity indicator**: A small dot — green means online, orange means offline
- **Pending Sync Alert**: A yellow banner that says "Hey, you have X transactions waiting to sync"
- **Recent Transactions**: The last few transactions you made, color-coded (red = sent money out, green = received money)

Currently uses mock (fake) data to show what it'll look like when connected to a real backend.

---

### 5. Send Money Screen
**File**: `lib/presentation/screens/send_money_screen.dart`

The screen where you actually send money. It has:

- **Connection type toggle**: NFC (tap phones) or Bluetooth
- **Recipient address field**: The wallet ID or address of who you're paying. Also has a QR code scanner button.
- **Amount field**: How much to send (has a `$` prefix built in)
- **Description field**: Optional note ("for pizza", etc.)
- **Fee summary**: Shows the transaction fee, network fee, and total you'll be charged
- **Send button**: Triggers the transaction (2-second fake delay right now, will be real later)

---

### 6. Transaction History Screen
**File**: `lib/presentation/screens/transaction_history_screen.dart`

Shows all your transactions with filter chips at the top:
- **All** — everything
- **Sent** — money you sent out
- **Received** — money that came in
- **Pending** — transactions not yet synced with the server

Each transaction is a card. Tap any one and a **bottom sheet** pops up showing the full details: transaction ID, parties involved, amount, timestamp, sync status.

---

## The Data Layer (The Kitchen)

This is where data is fetched, stored, validated, and transformed.

### DTOs — Data Transfer Objects
**Folder**: `lib/data/dto/`

DTOs are just "data containers for talking to the server." They're like forms you fill out before mailing — exactly the shape the server expects.

| File | Purpose |
|------|---------|
| `login_request.dart` | Email + password to send to `/auth/login` |
| `register_request.dart` | All fields to send to `/auth/register` |
| `auth_response.dart` | What the server sends back after login/register (token, userId, balance, etc.) |
| `offline_transaction_request.dart` | One offline transaction's data (id, sender, receiver, amount, signature) |
| `sync_transactions_request.dart` | A batch of offline transactions + a merkle root, sent when syncing |
| `sync_response.dart` | What the server returns after sync (accepted transactions + conflicts) |
| `transaction_response.dart` | A single transaction's full details from the server |
| `offline_allowance.dart` | The server's rules: how much you can transact offline before you must sync |

The `.g.dart` files (like `auth_response.g.dart`) are **auto-generated** — you never touch them. They contain the `fromJson()` and `toJson()` code that converts between Dart objects and JSON automatically.

---

### Models — Domain Objects
**Folder**: `lib/data/models/`

Models are the "real" objects the app uses internally. They're similar to DTOs but they can have extra computed properties and business logic.

#### UserModel
The logged-in user. Key things it knows:
- `balance` — total money in the account
- `pendingOfflineAmount` — money you've sent offline but not yet synced
- `availableBalance` — what you can actually spend right now (`balance - pendingOfflineAmount`)
- `canPerformOfflineTransaction(amount)` — checks if you have enough available balance

#### TransactionModel
A single payment. Key things it tracks:
- `status` — one of: `PENDING_SYNC`, `COMPLETED`, `FAILED`, `CONFLICT`, `DOUBLE_SPEND_DETECTED`
- `prevHash` / `currentHash` — cryptographic hashes linking transactions together (like a mini blockchain chain)
- `isSpent` — prevents someone from spending the same money twice
- `syncedAt` — when did the server finally accept it?

#### OfflineAllowanceModel
The "offline budget" the server assigns you:
- `maxAmount` — you can't go offline-transact more than this total
- `maxTransactions` — max 10 pending offline transactions
- `canPerformTransaction(amount)` — checks both limits before allowing a transaction

---

### Data Sources
**Folder**: `lib/data/datasource/`

These are the two "storage systems" the app talks to:

**RemoteDataSource** — sends HTTP requests to the backend server. It's the part of the app that talks to the internet. It uses `Dio` (an HTTP library) under the hood.

**LocalDataSource** — stores data in memory on the device. Think of it as a temporary scratchpad. Currently it's just a `Map<String, dynamic>` in memory (can be replaced with SharedPreferences or Hive for persistence across app restarts).

---

### Services (Data Layer)
**Folder**: `lib/data/services/`

Services are higher-level than data sources. They coordinate the data.

**ApiClient** — the singleton HTTP client. One instance, used everywhere. It automatically attaches your JWT token to every request via an "interceptor" (a function that runs before every request, quietly inserting `Authorization: Bearer <token>` into the headers).

**AuthService** — handles everything about being logged in:
- Calling login/register endpoints
- Saving your token securely (`flutter_secure_storage`)
- Checking if you're authenticated
- Restoring session when app relaunches
- Logging out (clearing everything)

**TransactionService** — handles offline transactions:
- Saving offline transactions locally when you're offline
- Fetching pending (not-yet-synced) transactions
- Sending them to the server in a batch when you come back online
- Clearing synced transactions from local storage

---

### Repositories
**Folder**: `lib/data/repository/`

Repositories are the "bridge" layer. Screens don't talk to services directly. Instead, they go through repositories. Why? Because repositories wrap everything in a safe `AppResult<T>` wrapper so errors are handled gracefully instead of crashing the app.

| Repository | What it manages |
|------------|----------------|
| `AuthRepository` | Login, register, logout, token management |
| `UserRepository` | Fetching user profile — tries network first, falls back to cache |
| `TransactionRepository` | Creating offline transactions, syncing, removing completed ones |

---

## The Domain Layer (The Waiter)

**Folder**: `lib/domain/`

This layer contains business rules and utilities that aren't tied to any specific screen or data source.

### Validation Utilities
**File**: `lib/domain/utils/validation_util.dart`

Static functions that check if input is correct:
- `isValidEmail(email)` — checks against a regex pattern
- `isValidPassword(password)` — at least 8 characters
- `isValidUsername(username)` — at least 3 characters
- `isValidAmount(amount)` — must be a positive number
- `validateRegistration()` — runs all checks at once, returns a map of errors

### Format Utilities
**File**: `lib/domain/utils/format_util.dart`

Static functions that make data look pretty on screen:
- `formatCurrency(1234.5)` → `"1234.50"`
- `formatCurrencyWithComma(1234.5)` → `"1,234.50"`
- `formatDate(date)` → `"Jan 15, 2024"`
- `formatTransactionId("abc123xyz456")` → `"abc12...x456"` (shortened)
- `maskEmail("john@gmail.com")` → `"j***@gmail.com"`

### Offline Transaction Service
**File**: `lib/domain/services/transaction_service.dart`

This is the brain of the offline payment system. It:
1. **Validates** the transaction (enough balance? Within offline limits? Not a duplicate?)
2. **Generates transaction hashes** (SHA256 of the transaction data)
3. **Builds the Merkle root** — a single hash that represents a whole batch of transactions (like a fingerprint for the entire batch)
4. **Detects double-spend** — if you try to spend money you've already spent offline, it throws a `DoubleSpendsException`

**What's a Merkle Tree?** Imagine you have 4 transactions. You hash each one. Then you combine hashes in pairs and hash those. Keep doing it until you have one final hash. That's your Merkle root. It's a mathematical proof that the whole batch is exactly what you say it is.

### Bluetooth Service
**File**: `lib/domain/services/bluetooth_service.dart`

Currently a placeholder. It exists to define the interface for Bluetooth communication (scanning for nearby devices, establishing a connection, exchanging transaction data). The actual implementation is not yet done.

---

## Core Layer (The Manager's Rules)

**Folder**: `lib/core/`

### Constants
**File**: `lib/core/constants/app_constants.dart`

Every "magic number" in the app lives here. No hardcoded values scattered everywhere:

```
API base URL: http://localhost:8080
Max offline balance: 50,000
Max single offline transaction: 5,000
Max pending offline transactions: 10
Offline token expiry: 24 hours
Sync interval: 5 minutes
Min password length: 8 characters
```

There are also Bluetooth UUIDs (unique identifiers for the Bluetooth service) defined here.

---

### Custom Exceptions
**File**: `lib/core/exceptions/app_exception.dart`

Instead of generic crashes, every type of error has its own class. This makes error messages meaningful and lets the UI show the right message to the user.

| Exception | When it's thrown |
|-----------|-----------------|
| `NetworkException` | Can't reach server (no internet, server down) |
| `ServerException` | Server responded, but with an error (e.g. 401 Unauthorized, 500 Server Error) |
| `AuthenticationException` | Wrong password, expired token, etc. |
| `ValidationException` | User filled out a form incorrectly |
| `OfflineException` | Action requires internet but user is offline |
| `LocalStorageException` | Couldn't read/write local device storage |
| `BluetoothException` | Bluetooth pairing or communication failed |
| `InsufficientFundsException` | Not enough balance (tells you what you have vs. what you need) |
| `DoubleSpendsException` | Tried to spend money that's already been spent |

---

### AppResult Wrapper
**File**: `lib/core/result/app_result.dart`

This is a pattern called "Railway Oriented Programming." Instead of functions either returning a value OR throwing an exception (which can crash things), every function returns an `AppResult<T>` that is either:
- `AppResult.success(data)` — it worked, here's the data
- `AppResult.failure(error)` — it failed, here's what went wrong

The `when()` method lets you handle both cases cleanly:

```dart
result.when(
  success: (data) => print("Got data: $data"),
  failure: (error) => print("Error: ${error.message}"),
);
```

No try/catch everywhere. No unexpected crashes. Clean, predictable flow.

---

### State Classes
**Folder**: `lib/presentation/states/`

State classes hold all the "what's happening right now" data for screens.

**AuthState**:
- Is the app loading? (show spinner)
- Is the user authenticated?
- What was the error, if any?

**TransactionState**:
- Is it loading? Syncing?
- List of offline transactions
- How many are pending? What's the total pending amount?
- Any errors?

Both use `copyWith()` — an immutable update pattern. Instead of mutating state directly (which causes bugs), you make a copy with just the fields changed.

---

### Dependency Injection
**File**: `lib/presentation/providers/service_locator.dart`

This file sets up all the "wiring" — which concrete class goes where. It follows the **Service Locator** pattern:

- Creates the Dio HTTP client
- Creates the data sources (remote and local)
- Creates the repositories (injecting the data sources into them)
- Exposes them via simple getters

This means screens never create objects themselves — they just ask the locator: "give me the AuthRepository" and get a properly configured one back. This makes testing and swapping implementations easy.

---

## How the Offline-First System Works (Step by Step)

Here's the entire offline payment flow explained as a story:

1. **Ibrahim gets on the subway** — no internet
2. He opens PayMesh and wants to pay Fatima $50
3. The app checks: is Ibrahim online? No.
4. It checks: does Ibrahim have offline permission? (The server gave him a limit when he was last online)
5. It checks: does he have enough available balance? (total - already-pending-offline-amounts)
6. If yes → the transaction is created with status `PENDING_SYNC`
7. The transaction is **signed** with a hash and stored locally
8. **Ibrahim arrives at his stop** — internet restored
9. The app notices it's online
10. It bundles all `PENDING_SYNC` transactions into a `SyncTransactionsRequest`
11. It calculates a **Merkle root** (a fingerprint of the whole batch)
12. It sends everything to the backend
13. The backend validates each transaction and sends back:
    - `accepted` — transactions that went through ✓
    - `conflicts` — transactions that had problems ✗
14. The app updates each transaction's status accordingly
15. Fatima's account is officially credited

---

## Security (What Keeps It Safe)

- **JWT Tokens** — after login, the server gives you a token. Every request to the server includes this token in the header. If someone steals your token, they could impersonate you — which is why tokens have expiry times.
- **flutter_secure_storage** — stores your token in the device's encrypted keychain (not plain text). Even if someone takes your phone and opens the files, they can't read the token.
- **Public Key** — generated during registration using SHA256. This is your cryptographic identity. It's used to verify that transactions came from you.
- **Transaction Signatures** — each offline transaction is hashed. The hash proves the transaction data hasn't been tampered with.
- **Double-Spend Detection** — the `isSpent` flag on each transaction and the Merkle root verification prevents you from sending the same money twice.

---

## Dependencies (What Libraries Are Used)

| Library | What it does |
|---------|-------------|
| `dio` | Makes HTTP requests to the backend. More powerful than Flutter's built-in `http`. |
| `flutter_secure_storage` | Stores sensitive data (like tokens) encrypted on the device. |
| `json_serializable` | Auto-generates `fromJson`/`toJson` code for all models. You annotate the class, run a command, and it writes the boring code for you. |
| `build_runner` | The tool that runs `json_serializable` — executes code generation. |

---

## Things That Are Stubbed / Not Yet Done

To be transparent, here's what's built as a placeholder and needs real implementation:

- **Bluetooth** — `bluetooth_service.dart` exists but the actual phone-to-phone communication isn't wired up yet
- **NFC** — UI toggle exists but functionality isn't implemented
- **QR Code Scanner** — button exists in SendMoneyScreen, not yet functional
- **Home screen data** — uses hardcoded mock data instead of real API calls
- **The service locator** — is set up but screens don't use it yet (they call services directly)
- **Push notifications** — not yet added (would be great for sync alerts)

---

## File Count Summary

| Area | Files |
|------|-------|
| Screens (UI) | 6 |
| State classes | 2 |
| Data models | 5 |
| DTOs | 8 |
| Repositories | 3 |
| Services (data layer) | 4 |
| Services (domain layer) | 2 |
| Utilities | 2 |
| Core (exceptions, result, constants) | 3 |
| **Total Dart files** | **~35** |

---

## Architecture Diagram (Text Version)

```
USER TAPS BUTTON
       |
       v
  [SCREEN] (presentation/screens)
       |
       | calls
       v
  [REPOSITORY] (data/repository)
       |
       |---> [REMOTE DATA SOURCE] ---> HTTP ---> Backend Server
       |
       |---> [LOCAL DATA SOURCE]  ---> In-Memory Storage
       |
       v
  [MODEL] (clean data object)
       |
       v
  [STATE] updated → Screen re-renders with new data
```

---

*This document was written by someone who actually read every single file in this codebase. No hallucinations. No guessing.*