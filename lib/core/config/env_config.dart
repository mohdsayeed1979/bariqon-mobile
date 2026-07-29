/// Which backend this build points at. Distinct from Flutter's own
/// debug/profile/release build mode — a release build can still target
/// staging (e.g. a TestFlight build for internal QA).
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String name) => switch (name) {
    'staging' => AppEnvironment.staging,
    'production' => AppEnvironment.production,
    _ => AppEnvironment.development,
  };

  String get label => switch (this) {
    AppEnvironment.development => 'Development',
    AppEnvironment.staging => 'Staging',
    AppEnvironment.production => 'Production',
  };
}

/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` / `--dart-define-from-file` at
/// build time, never hardcoded and never committed. One Supabase project
/// per environment is supported — [environment] just selects which URL/key
/// pair got baked into this particular build; swapping backends later is a
/// matter of pointing at a different `env/<name>.json`, not editing code.
///
/// Copy the relevant `env/<name>.example.json` to `env/<name>.json`
/// (git-ignored) and fill in the real values, then run with:
/// ```
/// flutter run --dart-define-from-file=env/development.json
/// flutter run --dart-define-from-file=env/staging.json
/// flutter run --dart-define-from-file=env/production.json
/// ```
/// See the project README for the full command set (Android/iOS/Web all
/// read the same three files, so every platform stays in sync).
class EnvConfig {
  const EnvConfig._();

  static const String _appEnvName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Which environment this build was compiled for. Defaults to
  /// [AppEnvironment.development] when `APP_ENV` isn't supplied, so an
  /// accidental bare `flutter run` (no `--dart-define-from-file`) can never
  /// silently behave as if it were production.
  static final AppEnvironment environment = AppEnvironment.fromName(
    _appEnvName,
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// True once both required values have been supplied at build time.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Human-readable explanation for startup failures when config is missing,
  /// so a missing `--dart-define` fails loudly and specifically instead of
  /// surfacing as an opaque Supabase client error later.
  static String get missingConfigMessage =>
      'Supabase configuration is missing for the "${environment.name}" '
      'environment. Provide SUPABASE_URL and SUPABASE_ANON_KEY via '
      '--dart-define-from-file=env/${environment.name}.json when running '
      'or building the app.';
}
