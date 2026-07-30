import 'package:url_launcher/url_launcher.dart';

import '../../features/settings/domain/site_contact_settings.dart';

/// Builds the actual launchable [Uri]s for the app's contact/social
/// actions from [SiteContactSettings] — the one place `wa.me`/`mailto:`/
/// `tel:`/Instagram URL shapes are constructed, so the footer and Contact
/// screen never duplicate this string-building logic (the exact
/// "hardcoded in multiple places" this was written to avoid).
class ContactLinks {
  const ContactLinks._();

  static Uri whatsapp(SiteContactSettings settings) =>
      Uri.parse('https://wa.me/${settings.whatsappNumber}');

  static Uri instagram(SiteContactSettings settings) =>
      Uri.parse(settings.instagramUrl);

  static Uri email(SiteContactSettings settings) =>
      Uri(scheme: 'mailto', path: settings.emailAddress);

  static Uri phone(SiteContactSettings settings) => Uri(
    scheme: 'tel',
    path: settings.phoneNumber.replaceAll(RegExp(r'\s+'), ''),
  );

  /// Launches [uri] in the appropriate external app (WhatsApp, Instagram,
  /// the mail client, the dialer). Returns whether it succeeded — callers
  /// show their own feedback (a SnackBar) on failure rather than this
  /// throwing, since "no app installed to handle this" is a normal,
  /// expected outcome, not an error.
  static Future<bool> launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
