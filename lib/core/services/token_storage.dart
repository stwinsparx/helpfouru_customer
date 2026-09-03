import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the customer auth token and the raw auth response (as returned
/// by `auth/verify-otp`) across app restarts, so a returning user can skip
/// straight past onboarding/login.
class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _authDataKey = 'auth_data';
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _storage = FlutterSecureStorage();

  static Future<bool> hasSeenOnboarding() async {
    final raw = await _storage.read(key: _onboardingSeenKey);
    return raw == 'true';
  }

  static Future<void> markOnboardingSeen() =>
      _storage.write(key: _onboardingSeenKey, value: 'true');

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// Persists the full `data` object from `auth/verify-otp` (token + user).
  static Future<void> saveAuthData(Map<String, dynamic> authData) =>
      _storage.write(key: _authDataKey, value: jsonEncode(authData));

  static Future<Map<String, dynamic>?> readAuthData() async {
    final raw = await _storage.read(key: _authDataKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<bool> hasAuthData() async {
    final raw = await _storage.read(key: _authDataKey);
    return raw != null;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _authDataKey);
  }
}
