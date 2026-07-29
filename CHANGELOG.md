# Changelog

All notable changes to the Bariqon mobile app are documented here.

## [v1.0.0-beta.1] - 2026-07-29

First beta milestone: the app runs against the real production Supabase
backend end-to-end, and every screen has had a responsiveness/UI-polish
pass. No business logic changed as part of the polish work.

### Added
- Multi-environment configuration (`development` / `staging` / `production`)
  via `env/<name>.json` + `APP_ENV` dart-define, replacing the old
  single-file `env.json` convention. Only `production` is populated today;
  `development`/`staging` are ready for separate backends whenever they
  exist, with no code changes required.
- Real Supabase-backed catalog: `SupabaseCategoryRepository` and
  `SupabaseProductRepository` read the live `cms_categories`/`cms_products`
  tables. Home, Categories, Category Detail, Product Listing, Product
  Detail, and Search all run through them.
- Real Supabase Auth: `SupabaseAuthRepository` backs Login, Registration,
  Forgot Password, and Profile updates, including session restore on cold
  start, reacting to token refresh/expiry, and handling the production
  project's email-confirmation-required signup flow.
- Product/category images load from Supabase Storage via a new
  `ProductImage` widget (`cached_network_image`), with the existing
  gradient/icon treatment as the loading/error fallback.
- Product Detail's "Specifications" section now shows the product's real
  `features_en`/`features_ar` content instead of fabricated placeholder
  copy.
- `ResponsiveCenter` widget: caps content width past phone sizes (three
  shared widths — narrow/wide/grid) so no screen stretches edge-to-edge on
  tablets. Applied across every screen in the app.
- Consistent `BouncingScrollPhysics` on every scrollable surface.

### Fixed
- The categories rail's loading skeleton wasn't horizontally scrollable
  and overflowed the screen width for the brief instant before data
  arrived — found via a real-device run against production, not caught by
  the mock-data test suite. Fixed, with a regression test added.
- Search screen's "haven't typed yet" state was blank empty space; now
  shows a proper empty-state prompt.

### Changed
- `MockCatalogData`/`MockAuthRepository` are no longer used by the running
  app — kept solely as deterministic test fixtures (wired in via
  `ProviderScope` overrides in `widget_test.dart`) so the test suite stays
  offline and fast.
- iOS project synced to the current Flutter SDK's (3.44.8) scene-based
  app lifecycle (AppDelegate/SceneDelegate, Info.plist scene manifest).

### Verified
- `flutter analyze`: 0 issues.
- `flutter test`: 23/23 passing.
- Ran on real booted simulators (iPhone 17 Pro, iPad Pro 13") against
  production Supabase — real data and images load, no overflow, correct
  phone/tablet layout switching.

### Known gaps (tracked, not fixed in this milestone)
- No Admin or Favorites screens exist in the codebase — flagged as a
  scope question, not silently built.
- "Best Sellers" home rail has no real backing signal (no sales/order
  count in `cms_products`); currently derived from `display_order`.
- Login/Register error messages are generic rather than surfacing the
  specific Supabase error.
