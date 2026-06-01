import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _pinKey = 'user_pin';
  static const _userIdKey = 'user_id';
  static const _biometricKey = 'biometric_enabled';
  static const _loginAtKey = 'login_at';
  static const _expiresInKey = 'session_expires_in';

  // Token
  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // PIN
  static Future<void> savePin(String pin) => _storage.write(key: _pinKey, value: pin);
  static Future<String?> getPin() => _storage.read(key: _pinKey);
  static Future<void> deletePin() => _storage.delete(key: _pinKey);

  // User ID
  static Future<void> saveUserId(String id) => _storage.write(key: _userIdKey, value: id);
  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  // Biometric
  static Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricKey, value: enabled.toString());
  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricKey);
    return val == 'true';
  }

  // Session timing
  static Future<void> saveSessionInfo(int expiresInSeconds) async {
    await _storage.write(key: _loginAtKey, value: DateTime.now().millisecondsSinceEpoch.toString());
    await _storage.write(key: _expiresInKey, value: expiresInSeconds.toString());
  }

  static Future<int> getRemainingSeconds() async {
    final loginAtStr = await _storage.read(key: _loginAtKey);
    final expiresInStr = await _storage.read(key: _expiresInKey);
    if (loginAtStr == null || expiresInStr == null) return 0;
    final loginAt = int.parse(loginAtStr);
    final expiresIn = int.parse(expiresInStr);
    final elapsed = (DateTime.now().millisecondsSinceEpoch - loginAt) ~/ 1000;
    return (expiresIn - elapsed).clamp(0, expiresIn);
  }

  // Clear all
  static Future<void> clearAll() => _storage.deleteAll();
}
