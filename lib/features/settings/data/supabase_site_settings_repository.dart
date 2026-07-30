import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/site_contact_settings.dart';
import '../domain/site_settings_repository.dart';

/// Reads `cms_site_settings` — a key/value table, not columns (confirmed
/// per docs/BACKEND_MAPPING_REPORT.md's follow-up query: rows like
/// `{"key": "whatsapp_number", "value": "97333621109"}`). Every field
/// falls back to [SiteContactSettings.fallback] individually, so a
/// missing/renamed key degrades gracefully instead of breaking the whole
/// footer.
class SupabaseSiteSettingsRepository implements SiteSettingsRepository {
  SupabaseSiteSettingsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SiteContactSettings> getContactSettings() async {
    try {
      final rows = await _client
          .from(SupabaseTables.siteSettings)
          .select('key, value');
      final byKey = <String, String>{
        for (final row in rows as List<dynamic>)
          if ((row as Map<String, dynamic>)['key'] is String &&
              row['value'] is String)
            row['key'] as String: row['value'] as String,
      };
      const fallback = SiteContactSettings.fallback;
      return SiteContactSettings(
        phoneNumber: byKey['phone_number'] ?? fallback.phoneNumber,
        whatsappNumber: byKey['whatsapp_number'] ?? fallback.whatsappNumber,
        emailAddress: byKey['email_address'] ?? fallback.emailAddress,
        instagramUrl: byKey['instagram_url'] ?? fallback.instagramUrl,
        addressEn: byKey['address_en'] ?? fallback.addressEn,
        addressAr: byKey['address_ar'] ?? fallback.addressAr,
      );
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }
}
