import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage JWT / secrets — Keystore Android + Keychain iOS.
/// Ne jamais utiliser SharedPreferences pour les tokens.
class AppSecureStorage {
  AppSecureStorage._();

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String tokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
}
