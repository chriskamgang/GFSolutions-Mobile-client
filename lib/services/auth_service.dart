import 'api_service.dart';
import 'storage_service.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiService();

  /// Login client -> returns client data or {requires2FA: true}
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? totpCode,
  }) async {
    final body = <String, dynamic>{
      'identifier': identifier,
      'password': password,
    };
    if (totpCode != null) body['totpCode'] = totpCode;

    final response = await _api.post('/client-auth/login', data: body);
    final data = response.data;

    if (data['requires2FA'] == true) {
      return {'requires2FA': true};
    }

    // Save token & session info
    await StorageService.saveToken(data['access_token']);
    await StorageService.saveUserId(data['client']['id']);
    if (data['expiresIn'] != null) {
      await StorageService.saveSessionInfo(data['expiresIn']);
    }

    return {
      'requires2FA': false,
      'user': User.fromJson(data['client']),
      'token': data['access_token'],
    };
  }

  Future<void> logout() async {
    try {
      await _api.post('/client-auth/logout');
    } catch (_) {}
    await StorageService.clearAll();
  }

  Future<User?> getCurrentUser() async {
    final token = await StorageService.getToken();
    if (token == null) return null;
    try {
      final response = await _api.get('/client-auth/me');
      return User.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.patch('/client-auth/change-password', data: {
      'oldPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
