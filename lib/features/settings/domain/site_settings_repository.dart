import 'site_contact_settings.dart';

/// The stable contract the footer/Contact screen depend on — same
/// Mock/Supabase-swap pattern as every other repository in this app.
abstract class SiteSettingsRepository {
  Future<SiteContactSettings> getContactSettings();
}
