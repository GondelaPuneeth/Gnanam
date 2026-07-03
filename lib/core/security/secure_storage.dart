import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure encryption and storage of sensitive data (like chat history).
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Saves encrypted data
  Future<void> saveSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Retrieves encrypted data
  Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes encrypted data
  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }
}
