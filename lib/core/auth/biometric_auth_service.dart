import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Single access point for `local_auth` — App Lock's biometric challenge,
/// per the same "one wrapper, nothing else touches the plugin directly"
/// shape as [SupabaseService]/[LocalPreferencesService].
class BiometricAuthService {
  BiometricAuthService(this._auth);

  final LocalAuthentication _auth;

  /// Whether this device can plausibly do a biometric (or device-credential
  /// fallback) challenge at all — checked before offering "Biometric Lock"
  /// as an option.
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric (Face/Touch ID, fingerprint) UI.
  /// `biometricOnly: false` lets the OS fall back to the device's own
  /// lock-screen credential (PIN/pattern/password) if no biometric is
  /// enrolled or it fails — local_auth's own recommended default, so a
  /// user without enrolled biometrics isn't locked out of an app feature
  /// entirely.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(LocalAuthentication());
});
