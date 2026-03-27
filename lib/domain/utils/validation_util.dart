import '../../core/constants/app_constants.dart';

class ValidationUtil {
  /// Validate email format
  static bool isValidEmail(String email) {
    final regex = RegExp(Constants.emailPattern as String);
    return regex.hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= Constants.minPasswordLength;
  }

  /// Validate username format
  static bool isValidUsername(String username) {
    return username.length >= Constants.minUsernameLength;
  }

  /// Validate amount
  static bool isValidAmount(double amount) {
    return amount > 0;
  }

  /// Get password validation error
  static String? getPasswordError(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < Constants.minPasswordLength) {
      return 'Password must be at least ${Constants.minPasswordLength} characters';
    }
    return null;
  }

  /// Get email validation error
  static String? getEmailError(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Get username validation error
  static String? getUsernameError(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < Constants.minUsernameLength) {
      return 'Username must be at least ${Constants.minUsernameLength} characters';
    }
    return null;
  }

  /// Validate registration form
  static Map<String, String> validateRegistration({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <String, String>{};

    final emailError = getEmailError(email);
    if (emailError != null) errors['email'] = emailError;

    final usernameError = getUsernameError(username);
    if (usernameError != null) errors['username'] = usernameError;

    final passwordError = getPasswordError(password);
    if (passwordError != null) errors['password'] = passwordError;

    if (password != confirmPassword) {
      errors['confirmPassword'] = 'Passwords do not match';
    }

    return errors;
  }

  /// Validate login form
  static Map<String, String> validateLogin({
    required String email,
    required String password,
  }) {
    final errors = <String, String>{};

    final emailError = getEmailError(email);
    if (emailError != null) errors['email'] = emailError;

    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    }

    return errors;
  }
}
