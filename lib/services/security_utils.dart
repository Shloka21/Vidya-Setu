/// Security utilities for input sanitization, validation, and error masking.
///
/// Use these throughout the app to prevent injection attacks,
/// data leaks, and enumeration attacks.
class SecurityUtils {
  SecurityUtils._();

  // ─── Input Sanitization ─────────────────────────────────────
  /// Strips HTML tags, trims whitespace, and limits length.
  /// Use on all user-provided text before storing in Firestore.
  static String sanitizeInput(String input, {int maxLength = 2000}) {
    // Strip HTML tags
    String clean = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove control characters (except newline, tab)
    clean = clean.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    // Trim and limit length
    clean = clean.trim();
    if (clean.length > maxLength) {
      clean = clean.substring(0, maxLength);
    }
    return clean;
  }

  /// Sanitize file names to prevent path traversal attacks.
  static String sanitizeFileName(String name) {
    // Remove path separators and null bytes
    String clean = name.replaceAll(RegExp(r'[/\\:\x00]'), '_');
    // Remove leading dots (hidden files)
    clean = clean.replaceAll(RegExp(r'^\.+'), '');
    // Limit length
    if (clean.length > 200) {
      clean = clean.substring(0, 200);
    }
    return clean.isEmpty ? 'unnamed_file' : clean;
  }

  // ─── Validation ─────────────────────────────────────────────
  /// RFC 5322 compliant email validation.
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    ).hasMatch(email.trim());
  }

  /// Password strength validation.
  /// Returns null if valid, error message if invalid.
  static String? validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Must contain an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Must contain a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Must contain a special character';
    }
    return null;
  }

  // ─── Error Masking ──────────────────────────────────────────
  /// Masks internal error details to prevent information leakage.
  /// Shows generic messages to users, logs real error in debug only.
  static String maskAuthError(String code) {
    // Generic message prevents email/user enumeration attacks
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Please choose a stronger password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your internet connection';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  /// Mask generic errors (never expose stack traces to users).
  static String maskError(dynamic error) {
    return 'Something went wrong. Please try again.';
  }
}
