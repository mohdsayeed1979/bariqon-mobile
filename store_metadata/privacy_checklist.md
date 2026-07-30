# App Privacy Checklist (for App Store Connect's "App Privacy" nutrition label)

This is a guide for filling in App Store Connect's own privacy
questionnaire — it isn't the questionnaire itself, and it's derived only
from what this codebase actually does (checked against every dependency in
`pubspec.yaml` and every form field in the app). Confirm against your
actual Supabase project configuration before submitting — this can only
account for what the client app does, not any server-side processing,
Supabase project settings, or third-party integrations added outside this
codebase.

## Data this app collects

All of it is entered directly by the user (registration, profile, login,
or an inquiry submission) and sent to Supabase (this app's backend —
see `lib/core/network/supabase_service.dart`), which is the sole data
processor. Nothing is sent to any other third party — there is no
analytics, advertising, or crash-reporting SDK in this app (verified
against `pubspec.yaml`: Flutter core, Riverpod, go_router, supabase_flutter,
logger, intl, cached_network_image — none of these collect or transmit
user data on their own).

| Data type | Where collected | Purpose | Linked to identity? | Used for tracking? |
|---|---|---|---|---|
| Email address | Registration, Login, Inquiry form | Account creation/authentication, inquiry follow-up | Yes | No |
| Name | Registration, Profile, Inquiry form | Personalization, inquiry follow-up | Yes | No |
| Phone number | Registration, Profile, Inquiry form | Inquiry follow-up | Yes | No |
| Physical address (country only, not street-level) | Registration, Profile, Inquiry form | Inquiry follow-up | Yes | No |
| Other user content (company name, inquiry notes) | Registration, Profile, Inquiry form | Inquiry follow-up | Yes | No |
| Password | Registration, Login | Authentication (handled entirely by Supabase Auth — this app never stores or sees it beyond the input field) | Yes | No |
| User ID | Assigned by Supabase Auth on sign-up | Session/account management | Yes | No |

## Data this app does NOT collect

- **Precise or coarse location** — no location package in `pubspec.yaml`,
  no location permission in `Info.plist`.
- **Photos/Camera** — no image picker or camera package; profile
  `avatarUrl` exists in the data model but nothing in the app currently
  sets it (no upload UI).
- **Contacts, Calendar, Health, Financial/Payment info** — not collected;
  the app has no in-app purchase or payment flow (it's inquiry/quote
  based, not e-commerce checkout).
- **Browsing/search history tied to identity** — search queries are used
  live to filter the product list and are not persisted or sent anywhere
  beyond the standard product-fetch API call.
- **Advertising data / identifiers for advertising** — no ad SDK is
  present.
- **Analytics/usage data** — no analytics SDK is present. (`logger` is
  local-console-only; it does not ship logs anywhere.)
- **Diagnostics/crash data** — no crash-reporting SDK is present.

## Notes for whoever fills in App Store Connect's actual form

1. **"Data Used to Track You"**: should be **None** — nothing here meets
   Apple's definition of tracking (linking data across apps/websites
   owned by other companies for advertising).
2. **"Data Linked to You"**: the table above (email, name, phone,
   country, other user content, password/user ID) — all of it is tied to
   the account the user creates.
3. **"Data Not Linked to You"**: none identified in this codebase.
4. **Third-party processor disclosure**: Supabase (supabase.com) is the
   backend/database/auth/storage provider — confirm their own data
   processing terms are referenced in whatever privacy policy URL you
   submit to App Store Connect (a privacy policy is required for
   submission and isn't something this checklist produces — that's a
   legal document, not app configuration).
5. If notification permissions or an image-upload feature are added
   later, this checklist needs updating before the next submission —
   it's accurate to the app as of this build, not a permanent document.
