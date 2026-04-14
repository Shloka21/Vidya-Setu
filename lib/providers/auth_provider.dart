import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/security_utils.dart';

import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.currentUser != null;
  bool get isInitialized => _isInitialized;
  User? get firebaseUser => _authService.currentUser;
  bool get needsRoleSelection =>
      _userModel != null && _userModel!.role.isEmpty;

  // Initialize - check if user is logged in
  Future<void> initialize() async {
    if (_isInitialized) return;

    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserModel(user.uid);
      // Fallback: if Firestore failed, build from FirebaseAuth
      _userModel ??= _buildFallbackUser(user);
    }
    _isInitialized = true;
    notifyListeners();
  }
  // Refresh current user data from Firestore
  Future<void> refreshUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserModel(user.uid);
    }
  }
  Future<void> _loadUserModel(String uid) async {
    // Try up to 2 times to load from Firestore (handles transient network failures)
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        _userModel = await _authService.getUserModel(uid);
        if (_userModel != null) {
          // Initialize gamification fields if they don't exist
          await FirestoreService().ensureUserInitialized(uid);
          break;
        }
      } catch (e) {
        debugPrint('Failed to load user model (attempt ${attempt + 1}): $e');
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    notifyListeners();
  }

  /// Creates a basic UserModel from FirebaseAuth when Firestore is unreachable.
  /// Uses 'student' as default role so returning users aren't sent back to role selection.
  /// Genuinely new users (from Google/Phone sign-in) will have their role set properly
  /// during the sign-up flow before this fallback is ever needed.
  UserModel _buildFallbackUser(User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      role: 'student', // Safe default — prevents role-selection loop for returning users
      phone: user.phoneNumber,
      profileImageUrl: user.photoURL,
    );
  }

  // Sign in with email
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.signInWithEmail(email, password);
      try {
        await _loadUserModel(credential.user!.uid);
      } catch (e) {
        debugPrint('Firestore read failed during login: $e');
      }
      // Fallback if Firestore failed
      _userModel ??= _buildFallbackUser(credential.user!);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString().contains('firebase')
          ? 'Authentication failed. Please try again.'
          : 'An unexpected error occurred';
      _setLoading(false);
      return false;
    }
  }

  // Sign up with email
  Future<bool> signUpWithEmail(
    String name,
    String email,
    String password,
    String role,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      final credential =
          await _authService.signUpWithEmail(email, password, name, role);
      try {
        await _loadUserModel(credential.user!.uid);
      } catch (e) {
        debugPrint('Firestore read failed during signup: $e');
      }
      _userModel ??= UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        role: role,
      );

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        _setLoading(false);
        return false;
      }
      try {
        await _loadUserModel(credential.user!.uid);
      } catch (e) {
        debugPrint('Firestore read failed during Google login: $e');
      }
      _userModel ??= _buildFallbackUser(credential.user!);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Google sign-in failed';
      _setLoading(false);
      return false;
    }
  }

  // Set user role (after Google sign-in or role selection)
  Future<void> setUserRole(String role) async {
    if (_authService.currentUser != null) {
      try {
        await _authService.updateUserRole(_authService.currentUser!.uid, role);
      } catch (_) {}
      // Update local model immediately
      if (_userModel != null) {
        _userModel = UserModel(
          uid: _userModel!.uid,
          name: _userModel!.name,
          email: _userModel!.email,
          role: role,
          phone: _userModel!.phone,
          profileImageUrl: _userModel!.profileImageUrl,
          isTimetableCreated: _userModel!.isTimetableCreated,
        );
      }
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Failed to send reset email';
      _setLoading(false);
      return false;
    }
  }

  // ─── Phone Authentication ────────────────────────────────
  String? _verificationId;
  int? _resendToken;
  bool _phoneAuthLoading = false;

  String? get verificationId => _verificationId;
  bool get phoneAuthLoading => _phoneAuthLoading;

  Future<bool> sendOtp(String phoneNumber) async {
    _phoneAuthLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _phoneAuthLoading = false;
          notifyListeners();
        },
        onVerificationCompleted: (credential) async {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          await _loadUserModel(userCredential.user!.uid);
          _userModel ??= _buildFallbackUser(userCredential.user!);
          _phoneAuthLoading = false;
          notifyListeners();
        },
        onVerificationFailed: (e) {
          _error = e.message ?? 'Phone verification failed';
          _phoneAuthLoading = false;
          notifyListeners();
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
      return true;
    } catch (e) {
      _error = 'Failed to send OTP';
      _phoneAuthLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _error = 'Please request OTP first';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _loadUserModel(credential.user!.uid);
      _userModel ??= _buildFallbackUser(credential.user!);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Invalid OTP';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Verification failed';
      _setLoading(false);
      return false;
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    await sendOtp(phoneNumber);
  }

  // Reload user from Firestore
  Future<void> reloadUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserModel(user.uid);
      _userModel ??= _buildFallbackUser(user);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _verificationId = null;
    _resendToken = null;
    _isInitialized = false;
    notifyListeners();
  }

  // Soft delete account
  Future<void> softDeleteAccount(String uid) async {
    await _authService.softDeleteAccount(uid);
    await signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    return SecurityUtils.maskAuthError(code);
  }
}
