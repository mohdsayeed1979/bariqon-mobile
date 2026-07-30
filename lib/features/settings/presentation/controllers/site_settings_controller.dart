import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/supabase_service.dart';
import '../../data/mock_site_settings_repository.dart';
import '../../data/supabase_site_settings_repository.dart';
import '../../domain/site_contact_settings.dart';
import '../../domain/site_settings_repository.dart';

/// Same env-conditional selection as every other repository in this app —
/// see catalog_providers.dart/auth_controller.dart for the identical
/// pattern.
final siteSettingsRepositoryProvider = Provider<SiteSettingsRepository>((
  ref,
) {
  if (!EnvConfig.isConfigured) return MockSiteSettingsRepository();
  return SupabaseSiteSettingsRepository(ref.watch(supabaseClientProvider));
});

final siteContactSettingsProvider = FutureProvider<SiteContactSettings>((
  ref,
) {
  return ref.watch(siteSettingsRepositoryProvider).getContactSettings();
});
