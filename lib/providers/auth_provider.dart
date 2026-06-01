import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _requires2FA = false;
  String? _pendingIdentifier;
  String? _pendingPassword;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get requires2FA => _requires2FA;

  /// Check if user is already logged in
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final remaining = await StorageService.getRemainingSeconds();
    if (remaining <= 0) {
      await StorageService.clearAll();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final user = await _authService.getCurrentUser();
    if (user != null) {
      _user = user;
      _isAuthenticated = true;
    } else {
      await StorageService.clearAll();
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Login step 1 (credentials)
  Future<void> login(String identifier, String password) async {
    final result = await _authService.login(
      identifier: identifier,
      password: password,
    );

    if (result['requires2FA'] == true) {
      _requires2FA = true;
      _pendingIdentifier = identifier;
      _pendingPassword = password;
      notifyListeners();
      return;
    }

    _user = result['user'];
    _isAuthenticated = true;
    _requires2FA = false;
    notifyListeners();
  }

  /// Login step 2 (2FA code)
  Future<void> verify2FALogin(String code) async {
    if (_pendingIdentifier == null || _pendingPassword == null) {
      throw Exception('Pas de session en attente');
    }

    final result = await _authService.login(
      identifier: _pendingIdentifier!,
      password: _pendingPassword!,
      totpCode: code,
    );

    _user = result['user'];
    _isAuthenticated = true;
    _requires2FA = false;
    _pendingIdentifier = null;
    _pendingPassword = null;
    notifyListeners();
  }

  void cancelTwoFactor() {
    _requires2FA = false;
    _pendingIdentifier = null;
    _pendingPassword = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _requires2FA = false;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}
