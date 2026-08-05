/// The two ways App Lock can challenge the user — per the Settings brief's
/// "Authentication Options". Exclusive: exactly one is active at a time.
enum AppLockMethod { biometric, pin }

/// How soon after the app is backgrounded it re-locks, per the Settings
/// brief's "App Lock Timeout". `duration` is what [AppLockGate] compares
/// elapsed background time against; `Duration.zero` means "re-lock the
/// instant the app is backgrounded at all."
enum AppLockTimeout {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const AppLockTimeout(this.duration);

  final Duration duration;
}

/// App Lock state, persisted locally only (per the Settings brief — no
/// backend) via [LocalPreferencesService] (enabled/method/timeout) and
/// [SecureStorageService] (whether a PIN exists — the PIN's hash itself
/// never lives in this entity or in preferences, only in secure storage).
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.method,
    this.timeout = AppLockTimeout.immediately,
    this.hasPin = false,
  });

  final bool enabled;
  final AppLockMethod? method;
  final AppLockTimeout timeout;
  final bool hasPin;

  AppLockSettings copyWith({
    bool? enabled,
    AppLockMethod? Function()? method,
    AppLockTimeout? timeout,
    bool? hasPin,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      method: method != null ? method() : this.method,
      timeout: timeout ?? this.timeout,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}
