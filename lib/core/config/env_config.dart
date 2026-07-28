/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` / `--dart-define-from-file` at
/// build time, never hardcoded and never committed. This app targets the
/// existing production Bariqon Supabase project — there is no separate
/// dev/staging backend, per the approved architecture (see
/// docs/ARCHITECTURE.md §6 and docs/SUPABASE_INTEGRATION.md §1).
///
/// Example (once real values are supplied):
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://qqqwmxqnhjymswhqcpgp.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon-key>
/// ```
///
/// Or, copy env.example.json to env.json (git-ignored) and run with
/// `flutter run --dart-define-from-file=env.json` — see the project README.
class EnvConfig {
  const EnvConfig._();

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
      'Supabase configuration is missing. Provide SUPABASE_URL and '
      'SUPABASE_ANON_KEY via --dart-define (or --dart-define-from-file) '
      'when running or building the app.';
}
