# Bariqon Mobile

Flutter client for Bariqon Trading, sharing the existing production
Supabase backend used by [bariqon.bh](https://www.bariqon.bh). See
`../docs/` for the full architecture, roadmap, and design documentation
this project is built against.

## Running locally

The app requires the production Supabase project's URL and anon key,
supplied at build/run time — never hardcoded, never committed.

1. Copy `env.example.json` to `env.json` and fill in the two values.
2. Run with:

   ```
   flutter run --dart-define-from-file=env.json
   ```

Without `env.json`, the app still boots (browsing/UI foundation works),
but logs a clear warning and skips Supabase initialization — see
`lib/core/config/env_config.dart`.

## App identifiers

- Android: `com.bariqon.mobile`
- iOS: `com.bariqon.mobile`

## Fonts

Brand fonts (Inter, Playfair Display, Cairo, Amiri) are wired into the
theme by name but the font files themselves aren't bundled yet — see the
`fonts:` block in `pubspec.yaml` for what's needed once they're sourced.
