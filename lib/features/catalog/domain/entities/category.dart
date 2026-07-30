import 'package:flutter/material.dart';

/// Plain domain entity — no Flutter-beyond-IconData, no Supabase, no JSON
/// mapping. Field shape (nameEn/nameAr/descriptionEn/descriptionAr)
/// deliberately mirrors the confirmed `cms_categories` bilingual field
/// convention from docs/API_CONTRACT.md §1, so swapping the mock data
/// source for a real repository doesn't change this type. Populated from
/// either [MockCategoryRepository] or [SupabaseCategoryRepository] — see
/// domain/category_repository.dart.
///
/// [descriptionEn]/[descriptionAr] are nullable: per
/// docs/BACKEND_MAPPING_REPORT.md §2, the real `cms_categories` table has
/// no description column at all (confirmed absent, not just unpopulated).
/// The mock repository still supplies one; the Supabase repository leaves
/// it null, and [CategoryDetailScreen] omits that block when null rather
/// than inventing marketing copy client-side.
@immutable
class Category {
  const Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    required this.icon,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;

  /// Placeholder visual — the real `cms_categories` table has no
  /// image/icon column (confirmed, per docs/BACKEND_MAPPING_REPORT.md §2),
  /// so this stays a small client-side lookup keyed by category name
  /// rather than backend data.
  final IconData icon;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;

  String? description(Locale locale) =>
      locale.languageCode == 'ar' ? descriptionAr : descriptionEn;
}
