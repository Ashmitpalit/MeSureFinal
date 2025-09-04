import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _user!.emailVerified;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      String? error = await _authService.signUpWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      if (error != null) {
        _setError(error);
        return false;
      }

      return true;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);

    try {
      String? error = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (error != null) {
        _setError(error);
        return false;
      }

      return true;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _setError(null);

    try {
      String? error = await _authService.sendEmailVerification();

      if (error != null) {
        _setError(error);
        return false;
      }

      return true;
    } catch (e) {
      _setError('Failed to send verification email. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check email verification status
  Future<void> checkEmailVerification() async {
    await _authService.reloadUser();
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      String? error = await _authService.resetPassword(email);

      if (error != null) {
        _setError(error);
        return false;
      }

      return true;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _setLoading(false);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    return await _authService.getUserData();
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    await _authService.updateUserData(data);
    notifyListeners();
  }
}
