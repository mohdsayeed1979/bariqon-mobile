/// Named references to Supabase tables/buckets confirmed to exist in the
/// production project, per docs/BACKEND_INTEGRATION_REPORT.md and
/// docs/API_CONTRACT.md. These are constants pointing at an *existing*
/// backend — nothing here creates, alters, or assumes a schema.
///
/// Column-level detail is intentionally not encoded here; see
/// docs/API_CONTRACT.md for what's confirmed vs. still open per table
/// (notably: the product variant/option structure is not yet known).
class SupabaseTables {
  const SupabaseTables._();

  static const String categories = 'cms_categories';
  static const String products = 'cms_products';
  static const String contactMessages = 'cms_contact_messages';
  static const String profiles = 'profiles';
  static const String gallery = 'cms_gallery';
  static const String galleryAlbums = 'cms_gallery_albums';

  // Optional / "mirror if useful" tables per SUPABASE_INTEGRATION.md §4 —
  // not required for the app's core loop, referenced here only so a future
  // feature doesn't have to re-derive the name from the discovery report.
  static const String testimonials = 'cms_testimonials';
  static const String clients = 'cms_clients';
  static const String heroSlides = 'cms_hero_slides';
  static const String homepageLayout = 'cms_homepage_layout';
  static const String aboutSections = 'cms_about_sections';
  static const String siteSettings = 'cms_site_settings';
  static const String analyticsVisits = 'cms_analytics_visits';
}

class SupabaseBuckets {
  const SupabaseBuckets._();

  /// Public bucket serving product/gallery imagery, confirmed via
  /// `storage/v1/object/public/media/uploads/{id}.{ext}` URLs.
  static const String media = 'media';
}
