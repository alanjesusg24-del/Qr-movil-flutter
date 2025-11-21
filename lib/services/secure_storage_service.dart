import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_user.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // User
  Future<void> saveUser(AuthUser user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _keyUser, value: userJson);
  }

  Future<AuthUser?> getUser() async {
    final userJson = await _storage.read(key: _keyUser);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthUser.fromJson(userMap);
    } catch (e) {
      print('Error al parsear usuario: $e');
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _keyUser);
  }

  // Biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // Remember Me
  Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: _keyRememberMe, value: remember.toString());
  }

  Future<bool> isRememberMe() async {
    final value = await _storage.read(key: _keyRememberMe);
    return value == 'true';
  }

  // Saved Credentials (solo si Remember Me está activo)
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);

    if (email == null || password == null) return null;

    return {
      'email': email,
      'password': password,
    };
  }

  Future<void> deleteSavedCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear auth data only (mantiene preferencias)
  Future<void> clearAuthData() async {
    await deleteToken();
    await deleteUser();
    await deleteSavedCredentials();
  }
}
