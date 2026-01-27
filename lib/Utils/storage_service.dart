import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _userKey = 'user_data';

  /// Save access token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get access token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Save token type
  static Future<void> saveTokenType(String tokenType) async {
    await _storage.write(key: _tokenTypeKey, value: tokenType);
  }

  /// Get token type
  static Future<String?> getTokenType() async {
    return await _storage.read(key: _tokenTypeKey);
  }

  /// Save user data as JSON string
  static Future<void> saveUser(Map<String, dynamic> user) async {
    // Convert user map to JSON string for storage
    final userJson = jsonEncode(user);
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Get user data as Map
  static Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear all stored data (logout)
  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _userKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

