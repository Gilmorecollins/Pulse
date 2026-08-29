import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the user's own Gemini API key in the platform keystore
/// (Android Keystore-backed), never in plain preferences or the database.
/// See docs/API.md — v1 calls Gemini directly from the app rather than
/// through a backend proxy, since this is a single personal install, not
/// a distributed app; the key still deserves real device-level protection.
class AiKeyRepository {
  static const _key = 'gemini_api_key';

  final _storage = const FlutterSecureStorage();

  Future<String?> getKey() => _storage.read(key: _key);

  Future<void> setKey(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await clearKey();
      return;
    }
    await _storage.write(key: _key, value: trimmed);
  }

  Future<void> clearKey() => _storage.delete(key: _key);
}
