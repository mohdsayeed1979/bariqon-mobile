import 'package:flutter/material.dart';

/// Plain domain entity — no Flutter-beyond-IconData, no Supabase, no JSON
/// mapping. Field shape (nameEn/nameAr) deliberately mirrors the confirmed
/// `cms_categories` bilingual field convention from
/// docs/API_CONTRACT.md §1, so swapping the mock data source for a real
/// repository later doesn't change this type. Phase 2B populates instances
/// from local mock data only — see mock_catalog_data.dart.
@immutable
class Category {
  const Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
  });

  final String id;
  final String nameEn;
  final String nameAr;

  /// Placeholder visual — real category imagery comes from Supabase Storage
  /// once the backend is connected (Phase 3+); an icon is a deliberate,
  /// honest placeholder rather than a stand-in photo.
  final IconData icon;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;
}
