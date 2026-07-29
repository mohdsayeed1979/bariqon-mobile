# Bariqon Mobile

Flutter client for Bariqon Trading, sharing the existing production
Supabase backend used by [bariqon.bh](https://www.bariqon.bh). See
`../docs/` for the full architecture, roadmap, and design documentation
this project is built against.

## Running locally

The app takes its Supabase URL/anon key and target environment
(`development` / `staging` / `production`) from a `--dart-define-from-file`
JSON, never hardcoded and never committed. One file per environment, all
three read by Android, iOS, and Web alike:

1. Copy the relevant `env/<name>.example.json` to `env/<name>.json`
   (git-ignored) and fill in the real Supabase URL/anon key for that
   environment.
2. Run with:

   ```
   flutter run --dart-define-from-file=env/development.json
   flutter run --dart-define-from-file=env/staging.json
   flutter run --dart-define-from-file=env/production.json
   ```

   Same flag for `flutter build ios` / `flutter build appbundle` /
   `flutter build web`.

Today only `env/production.json` points at a real backend (the existing
Bariqon Supabase project). `development`/`staging` are scaffolded and
ready to go the moment separate Supabase projects exist for them — no
code change needed, just filling in that environment's JSON file.

Without a matching `env/<name>.json`, the app still boots (browsing/UI
foundation works), but logs a clear warning and skips Supabase
initialization — see `lib/core/config/env_config.dart`.

## App identifiers

- Android: `com.bariqon.mobile`
- iOS: `com.bariqon.mobile`

## Fonts

Brand fonts (Inter, Playfair Display, Cairo, Amiri) are wired into the
theme by name but the font files themselves aren't bundled yet — see the
`fonts:` block in `pubspec.yaml` for what's needed once they're sourced.
