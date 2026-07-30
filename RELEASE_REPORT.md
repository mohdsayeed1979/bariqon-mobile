# Bariqon Mobile — Release Candidate 1 (RC1) Audit Report

**Date:** 2026-07-30
**Baseline tag:** `v1.0.0-beta.1` (+ 6 commits, HEAD `9ecf81d`)
**Scope:** Full project review per the RC1 audit checklist below. No new
features added. No business logic changed except the one release-blocking
issue documented in §0 (found, not fixed — see why).

---

## §0. The one thing to read before anything else

**Sending an inquiry does not actually reach Bariqon.** The entire
"Send Inquiry → fill contact details → Submit" flow is still exactly what
it was scaffolded as in Phase 3: a local-only UI exercise. `Submit Inquiry`
generates a client-side reference number, clears the cart, and shows a
success screen — but **no data is ever sent to Supabase or anywhere else.**
A real customer would believe their inquiry was sent and never hear back,
because the business never received it.

This was **found, not fixed**, and here's exactly why:

- `SupabaseTables.contactMessages` (`cms_contact_messages`) already exists
  in the production schema and is clearly the intended target — but a live
  test insert against it with the production anon key returned:
  ```
  {"code":"42501", "message":"new row violates row-level security policy
  for table \"cms_contact_messages\""}
  ```
  Row-level security rejects the anon role outright. There's no
  documentation in this repo (the `docs/` folder every code comment
  references has never existed in this project — see the very first
  Supabase-connection commit's notes) confirming whether the intended path
  is an authenticated insert, a Postgres RPC/Edge Function, or something
  else.
- Guessing would mean either writing to columns whose names aren't
  confirmed, or silently failing in a *different, less visible* way than
  today's honest "this doesn't call any backend" state — worse than
  leaving it alone, because it would look fixed without being fixed.
- Per this audit's own instruction ("do not change business logic unless
  it's a release-blocking bug"): this **is** one, but fixing it correctly
  needs one input only the backend owner can give — the intended write
  path for `cms_contact_messages` (or confirmation that a different
  mechanism should be used). That's a five-minute conversation with
  whoever manages the Supabase project's RLS policies, not a guess I
  should make against production.

**This blocks release by itself, independent of every other item below.**
Everything else in this report describes a genuinely production-grade app
around that one gap.

---

## Audit checklist

### 1–3. Project review, TODOs/FIXMEs/placeholders/mock data/dead code, dev-only code removal

- **TODO/FIXME/XXX/HACK:** zero found across `lib/`.
- **`print()`/`debugPrint()`:** zero found — all logging already goes
  through the single `AppLogger` access point, release-gated to
  warning+ severity.
- **Dead code removed:**
  - `lib/core/widgets/app_buttons.dart` and `app_scaffold.dart` —
    confirmed zero references anywhere in `lib/` or `test/`; both were
    early scaffolding superseded by screens using `Scaffold`/
    `FilledButton`/`OutlinedButton`/`TextButton` directly.
  - 9 unused `l10n` keys removed from both `app_en.arb`/`app_ar.arb`
    (`appName`, `categoryEmptyFilteredTitle`, `categoryEmptyNoProductsTitle`,
    `close`, `comingSoonBadge`, `loading`, `offlineBannerMessage`, `ok`,
    `productDetailCategoryLabel`) — cross-checked against every `l10n.`
    reference in the codebase.
- **Mock data:** `MockCatalogData`/`MockAuthRepository` still exist by
  design — they're the deterministic test fixtures the widget-test suite
  runs against (via `ProviderScope` overrides), not live app code. Verified
  zero references from any non-test file.
- **Stale/misleading comments fixed:** several dartdoc comments still said
  "mock auth only" / "no real email is sent" after the app was connected to
  real Supabase Auth in an earlier session — one of these was actively
  wrong (Forgot Password *does* send a real email now). Updated to match
  reality.

### 4. Hardcoded credentials

**None found.** Swept `lib/` and the full git history for Supabase URLs,
JWT-shaped strings, and generic API-key patterns — zero hits outside
`EnvConfig` (which reads from `--dart-define`, never a literal). The one
place real production credentials exist on disk (`env/production.json`)
is git-ignored and was never committed — confirmed against full git
history, not just current `git status`.

### 5. Production environment configuration

Verified sound: `env/production.json` → `EnvConfig` → `Supabase.initialize()`
wiring is intact, `development`/`staging` remain ready-but-empty for
whenever separate backends exist for them, per the multi-environment setup
built earlier this project.

### 6–7. Asset verification and image optimization

- Bundled assets total **352KB** (just the brand logo JPEG at a
  reasonable 1023×417 for its largest display size; icon/launch-screen
  source files aren't bundled into the binary, only their generated
  platform-native outputs are). Nothing to trim.
- Generated iOS icon set: 436KB, all 25 required sizes present, 1024
  marketing icon confirmed alpha-free (a common App Store rejection
  cause — already clean).
- Remote product images (the real lever here, since the catalog is
  200+ photos from Supabase Storage) already had memory-safe decode
  sizing (`memCacheWidth`/`Height`) and paginated loading fixed in the
  prior production-readiness pass — re-verified still in place.

### 8–9. Startup performance and memory usage

`bootstrap.dart` reviewed fresh: no blocking work beyond the necessary
`Supabase.initialize()` await (a local session-restore operation, not a
network round-trip). Logger construction is cheap and release-gated.
No eager, unnecessary provider reads at the app root. Nothing to change.

### 10–12. Package versions, pubspec dependencies, unused packages

- `flutter pub outdated`: only a trivial `intl` patch (0.20.2→0.20.3) is
  available and it's SDK-locked; everything else is already at the
  newest resolvable version. Dependency tree is healthy.
- **Removed `cupertino_icons`** — confirmed zero use of `CupertinoIcons`
  anywhere (the app exclusively uses Material Icons). Leftover from the
  default `flutter create` template, never actually needed.
- Every remaining declared dependency confirmed actually imported and
  used somewhere in `lib/`.

### 13–15. Localization, Arabic RTL, English layout

- **EN/AR key parity: 315/315**, exact match both directions — nothing
  missing a translation, nothing orphaned in one language only.
- Swept for hardcoded English string literals bypassing `l10n` (in
  `Text()`, `tooltip:`, `label:`, `hintText:`, etc.) — zero found.
  Everything user-facing is localized; the only literal strings left are
  genuinely non-localizable data (email/phone/address values on the
  Contact screen).
- **RTL layout**: rendered Home, Categories, Product Detail, Login,
  Settings, and Inquiry Cart forced into Arabic/RTL and checked
  structurally (no live touch access to the simulator this session, same
  limitation as prior audits) — mirroring is correct throughout (app bar
  actions, section header actions, price/chip rows, breadcrumbs, form
  checkboxes).
  - **Found and fixed one real bug**: `SettingsListTile`'s disclosure
    chevron was hardcoded to `Icons.chevron_right` regardless of text
    direction, so it visually pointed the wrong way in Arabic. The exact
    same icon is already handled correctly elsewhere in the app
    (`category_detail_screen.dart`'s breadcrumb, which explicitly checks
    `Directionality.of(context)`) — this one spot was simply missed.
    Fixed with the same established pattern.

### 16. Navigation flows

Cross-checked **every** `context.go/push/pushReplacement` call site in the
app against **every** route declared in `router.dart` — full match, every
navigation target resolves to a real route, nothing orphaned or typo'd.

### 17. Logout / login / session recovery

- **Login/Register/Forgot Password**: real Supabase Auth, verified in the
  prior session (live production data, email-confirmation-required flow
  handled).
- **Session restore on cold start**: `AuthController.build()` reads
  `supabase_flutter`'s own persisted session synchronously after
  `Supabase.initialize()` resolves, then listens to
  `authStateChanges` for anything that changes afterward (token refresh,
  out-of-band expiry). Verified correct.
- **Found and fixed a real bug**: signing out cleared the auth session
  but not the local Inquiry Cart (which is intentionally
  account-independent, session-only state). On a shared device, the next
  person to sign in would see — and could submit an inquiry containing —
  the previous user's cart. Now cleared alongside sign-out.

### 18. Every exception is user-friendly

- Audited all 14 `catch` blocks across the app. Every UI-level catch
  (Login, Registration, Forgot Password, Edit Profile, Profile sign-out)
  routes through the shared `userFacingErrorMessage()` helper — a
  `NetworkFailure` reads as "check your connection," everything else as a
  calm generic message. None display a raw `error.toString()` or
  technical exception text.
- **Added one more layer**: Flutter's own default fallback for a widget
  that throws mid-build is a bare, unstyled gray box (blank in release
  builds). `FlutterError.onError` already logs these but doesn't change
  what actually renders. Added a proper `ErrorWidget.builder` as the true
  last-resort UI.

---

## Verification performed

Run after every batch of changes, per the audit instructions:

- `flutter analyze` — **0 issues**, every time.
- `flutter test` — **23/23 passing**, every time.
- `flutter build ipa --no-codesign --dart-define-from-file=env/production.json`
  — archives cleanly (`Runner.xcarchive`, 179.5MB; version 1.0.0, build 1,
  bundle ID `com.bariqon.mobile` all confirmed correct).
- Real-device simulator runs (iPhone 17 Pro) against production Supabase
  for spot verification; forced-RTL and forced-dark-mode widget renders
  for coverage the live simulator couldn't reach without touch access.

Three commits this session: `dcb48d5` (dead code/dependency/RTL fix),
`9ecf81d` (session-recovery fix/error UI). `7c1664b` (TestFlight prep) and
earlier commits predate this specific audit but are part of the same
release candidate.

---

## Production Readiness Score: **58 / 100**

This number is dominated entirely by §0. Every dimension this audit
checked — dead code, credentials, dependencies, localization, RTL,
navigation, session handling, exception messaging, startup performance —
is genuinely clean or was fixed on the spot. But a B2B catalog app whose
core, only conversion action (send an inquiry) silently does nothing is
not production-ready, full stop, regardless of how polished everything
around it is. Once §0 is resolved, this app is realistically in the
85–90 range — the fix required is narrow and everything else has already
been through three separate audit passes this project.

## Release-Blocking Issues

1. **Inquiry submission doesn't reach the backend** (§0). Blocks release
   on its own. Needs: confirmation of the correct write path for
   `cms_contact_messages` (or an alternative) from whoever manages the
   Supabase project's RLS policies, then a small, well-scoped follow-up
   to wire `InquiryDetailsFormScreen._submit()` to it.

No other release-blocking issues were found in this pass.

## Nice-to-have Improvements

(Carried forward from earlier audits, still accurate; none block release)

- No Admin or Favorites screens exist — a scope question raised early in
  this project and never resolved either way.
- Theme preference doesn't persist across app restarts (resets to
  system default) — needs a storage dependency (`shared_preferences` or
  similar) not currently in `pubspec.yaml`.
- Quantity stepper's tap targets use `VisualDensity.compact`, under the
  48dp accessibility guideline — flagged rather than resized, since
  that's a visible layout change outside a "don't redesign" audit.
- "Best Sellers" home rail has no real backing signal (no sales/order
  count column in `cms_products`); currently derived from `display_order`.
- No true offline/cached-content mode — errors are clear, but there's no
  local persistence to browse previously-seen data with zero connection.

## App Store Readiness Score: **80 / 100**

Distinct from the Production Readiness score above: this specifically
measures "would Apple reject the submission," not "does the app work
correctly." On that narrower question, the app is close:

- Signing, bundle ID, version/build, Info.plist, app icons (including the
  alpha-channel check on the 1024 marketing icon), launch screen, export
  compliance, and `ExportOptions.plist` are all verified correct.
- Store metadata (description, keywords, release notes, privacy
  checklist) exists in `store_metadata/`, cross-checked against the app's
  actual dependencies and data collection — accurate, not aspirational.
- The 20-point gap is **not** a technical blocker for Apple's review
  process — it's that a reviewer testing the core "send an inquiry" flow
  would find it completes successfully with no visible sign anything is
  wrong, which is a worse outcome than a visible error: **a passing
  Apple review here would not mean the feature works.** Apple's review
  guidelines (2.1) also require that apps "perform as advertised" — an
  inquiry flow that silently discards user input risks rejection or
  removal even if it slips through initial review. Fix §0 before
  submitting, not just before telling users it's ready.
