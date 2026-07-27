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
        final remembered = await _authService.getRememberMe();
        if (!remembered) {
          // User didn't ask to be remembered - require a fresh login every app launch.
          await _authService.logout();
          _isAuthenticated = false;
          _user = null;
        } else {
          // Only load user from storage - DON'T verify with server to avoid lag
          _user = await _authService.getUserFromStorage();
          _isAuthenticated = _user != null;
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      debugPrint('Check auth status error: $e');
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password,
      {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
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
    required String nik,
    required String ktpPhotoPath,
    required String email,
    required String rt,
    required String rw,
    String? phone,
    required String address,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        nik: nik,
        ktpPhotoPath: ktpPhotoPath,
        email: email,
        rt: rt,
        rw: rw,
        phone: phone,
        address: address,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.success) {
        // If registration requires admin verification, don't set authenticated
        // User will need to wait for admin approval
        if (response.data != null && response.data!.token.isNotEmpty) {
          _user = response.data!.user;
          _isAuthenticated = true;
        } else {
          // Registration successful but needs verification
          _isAuthenticated = false;
        }
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
    debugPrint('🚪 [AuthProvider] Logout started - clearing data immediately');

    // Clear state FIRST before calling service
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();

    debugPrint('✅ [AuthProvider] State cleared, now calling logout service');

    // Then call logout service (async in background)
    try {
      await _authService.logout();
      debugPrint('✅ [AuthProvider] Logout service completed');
    } catch (e) {
      debugPrint('⚠️ [AuthProvider] Logout service error (ignored): $e');
      // Ignore errors - user already logged out from app perspective
    }
  }

  // Logout all sessions/devices
  Future<void> logoutAll() async {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();

    try {
      await _authService.logoutAll();
    } catch (_) {
      // Ignore errors - state is already cleared
    }
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    try {
      final freshUser = await _authService.getProfile();
      if (freshUser != null) {
        _user = freshUser;
        _isAuthenticated = true;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Get profile (with loading state)
  Future<void> getProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final freshUser = await _authService.getProfile();
      if (freshUser != null) {
        _user = freshUser;
        _isAuthenticated = true;
        _errorMessage = null;
      } else if (_user == null) {
        _user = await _authService.getUserFromStorage();
        _isAuthenticated = _user != null;
      }
    } catch (e) {
      if (_user == null) {
        _user = await _authService.getUserFromStorage();
        _isAuthenticated = _user != null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? nik,
    String? rt,
    String? rw,
    String? avatarPath,
    bool removeAvatar = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.updateProfile(
        name: name ?? _user?.name ?? '',
        phone: phone ?? _user?.phone ?? '',
        address: address ?? _user?.address ?? '',
        nik: nik,
        rtNumber: rt,
        rwNumber: rw,
        avatarPath: avatarPath,
        removeAvatar: removeAvatar,
      );

      if (response['success'] == true && response['user'] != null) {
        _user = response['user'] as User;
        _errorMessage = null;
      } else {
        _errorMessage = response['message'];
        throw Exception(response['message']);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
