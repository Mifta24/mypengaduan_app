import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Check if user is logged in
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // First load user from storage for faster UI
        _user = await _authService.getUserFromStorage();
        if (_user != null) {
          _isAuthenticated = true;
          notifyListeners(); // Notify immediately with cached user
        }
        
        // Try to verify with server (optional, jangan paksa)
        try {
          final serverUser = await _authService.getProfile();
          if (serverUser != null) {
            _user = serverUser;
            _isAuthenticated = true;
          }
          // Jika gagal tapi ada cached user, tetap authenticated
        } catch (e) {
          debugPrint('Server verification failed, using cached user: $e');
          // Keep authenticated with cached user
          if (_user != null) {
            _isAuthenticated = true;
          }
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      debugPrint('Check auth status error: $e');
      // If error but we have cached user, keep authenticated
      if (_user == null) {
        _isAuthenticated = false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        address: address,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;

    _isLoading = false;
    notifyListeners();
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  // Get profile (with loading state)
  Future<void> getProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getProfile();
      if (_user != null) {
        _isAuthenticated = true;
      }
    } catch (e) {
      // Handle error silently
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
