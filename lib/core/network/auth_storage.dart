import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/models/user_model.dart';

/// Persists auth token + user via secure storage (encrypted_prefs on Android,
/// Keychain on iOS, cookies on web via flutter_secure_storage web impl).
class AuthStorage {
  AuthStorage._();

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _storage = FlutterSecureStorage();

  // In-memory cache so Dio interceptor is sync
  static String? _cachedToken;
  static UserModel? _cachedUser;

  static String? get cachedToken => _cachedToken;
  static UserModel? get cachedUser => _cachedUser;

  static Future<void> saveAuth({
    required String token,
    required UserModel user,
  }) async {
    _cachedToken = token;
    _cachedUser = user;
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
  }

  static Future<void> clear() async {
    _cachedToken = null;
    _cachedUser = null;
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
  }

  static Future<String?> readToken() async {
    if (_cachedToken != null) return _cachedToken;
    final v = await _storage.read(key: _kToken);
    _cachedToken = v;
    return v;
  }

  static Future<UserModel?> readUser() async {
    if (_cachedUser != null) return _cachedUser;
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final u = UserModel.fromJson(map);
      _cachedUser = u;
      return u;
    } catch (_) {
      return null;
    }
  }

  /// Hydrate in-memory cache at app start (non-blocking — call and await before first authed request).
  static Future<void> hydrate() async {
    await readToken();
    await readUser();
  }

  static void setTokenInMemory(String? token) {
    _cachedToken = token;
  }

  static void setUserInMemory(UserModel? user) {
    _cachedUser = user;
  }
}
