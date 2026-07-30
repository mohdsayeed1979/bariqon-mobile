import '../domain/site_contact_settings.dart';
import '../domain/site_settings_repository.dart';

/// Backs tests and any unconfigured run — see the catalog/auth mock
/// repositories for the same pattern. Returns the real, confirmed contact
/// info as a static value (not fake placeholder data — this is genuine
/// stable company info, safe to ship as the offline/test default).
class MockSiteSettingsRepository implements SiteSettingsRepository {
  @override
  Future<SiteContactSettings> getContactSettings() async =>
      SiteContactSettings.fallback;
}
