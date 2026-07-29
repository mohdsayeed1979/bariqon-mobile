import 'package:flutter/material.dart';

/// Plain domain entity, populated from the real `cms_categories` table
/// (see [SupabaseCategoryRepository][supabase_category_repository.dart]).
/// That table has no description or icon column, so both are optional
/// here: [descriptionEn]/[descriptionAr] are `null` unless a future CMS
/// change adds them, and [icon] is a presentation-only fallback chosen by
/// the repository from [key] (see `category_icon_utils.dart`) rather than
/// backend data.
@immutable
class Category {
  const Category({
    required this.id,
    required this.key,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    this.descriptionEn,
    this.descriptionAr,
    this.displayOrder = 0,
  });

  final String id;

  /// Raw `key` column from `cms_categories` — stable even if display
  /// names change; used to pick [icon].
  final String key;

  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final int displayOrder;

  /// Placeholder visual — real category imagery/description doesn't exist
  /// in `cms_categories` today; an icon is an honest placeholder rather
  /// than a stand-in photo.
  final IconData icon;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;

  /// Empty when the backend has no description for this category —
  /// callers should conditionally render, not fall back to placeholder
  /// copy.
  String description(Locale locale) {
    final value = locale.languageCode == 'ar' ? descriptionAr : descriptionEn;
    return value ?? '';
  }
}
