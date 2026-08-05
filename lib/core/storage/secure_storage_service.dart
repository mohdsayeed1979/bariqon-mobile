import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single access point for anything that must live in OS-encrypted storage
/// (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on
/// Android) rather than plain preferences — today, just the App Lock PIN.
/// Mirrors [LocalPreferencesService]'s "one wrapper" shape for secrets
/// specifically.
///
/// The PIN is never stored in plaintext, even inside secure storage: it's
/// SHA-256 hashed first, so [verifyPin] only ever compares hashes. This is
/// defense in depth on top of the OS-level encryption secure storage
/// already provides — belt and suspenders, per the same principle applied
/// to RLS elsewhere in this app.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _pinHashKey = 'app_lock_pin_hash';

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinHashKey, value: _hash(pin));
  }

  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinHashKey)) != null;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    return stored != null && stored == _hash(pin);
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});
