import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/entities/category.dart';
import '../domain/entities/product.dart';

/// Local, static mock data for the Phase 2B Home screen — per the brief,
/// no backend, no Supabase, no API. Category/product names are drawn from
/// Bariqon's real, publicly-known business lines (confirmed in
/// docs/BACKEND_INTEGRATION_REPORT.md) so the UI feels authentic rather
/// than generic, but every id/description/price here is placeholder
/// content for layout purposes — none of it is read from or written to
/// any backend. Swapped for `ProductRepository`/`CategoryRepository` calls
/// once Supabase is connected.
class MockCatalogData {
  const MockCatalogData._();

  static const List<Category> categories = [
    Category(
      id: 'luxury-gift-boxes',
      nameEn: 'Luxury Gift Boxes',
      nameAr: 'صناديق الهدايا الفاخرة',
      icon: Icons.card_giftcard_outlined,
    ),
    Category(
      id: 'hospitality',
      nameEn: 'Hospitality Amenities',
      nameAr: 'مستلزمات الضيافة',
      icon: Icons.hotel_outlined,
    ),
    Category(
      id: 'perfumery-cosmetics',
      nameEn: 'Perfumery & Cosmetics',
      nameAr: 'العطور ومستحضرات التجميل',
      icon: Icons.spa_outlined,
    ),
    Category(
      id: 'toiletries',
      nameEn: 'Toiletries',
      nameAr: 'مستلزمات الحمام',
      icon: Icons.soap_outlined,
    ),
    Category(
      id: 'general-trading',
      nameEn: 'General Trading',
      nameAr: 'التجارة العامة',
      icon: Icons.storefront_outlined,
    ),
  ];

  static const List<Product> featured = [
    Product(
      id: 'p-featured-1',
      nameEn: 'Woven Fabric Gift Box',
      nameAr: 'صندوق هدايا بنسيج مضفور',
      descriptionEn: 'Wooden gift box wrapped in premium woven fabric.',
      descriptionAr: 'صندوق هدايا خشبي ملفوف بنسيج مضفور فاخر.',
      price: 10.00,
      icon: Icons.card_giftcard,
      placeholderColor: AppColors.primary,
    ),
    Product(
      id: 'p-featured-2',
      nameEn: 'Signature Amenity Set',
      nameAr: 'طقم مستلزمات الضيافة المميز',
      descriptionEn: 'Curated hotel amenity set with an elegant finish.',
      descriptionAr: 'طقم مستلزمات فندقية منسق بلمسة أنيقة.',
      price: 24.50,
      icon: Icons.hotel,
      placeholderColor: AppColors.gold,
    ),
    Product(
      id: 'p-featured-3',
      nameEn: 'Artisan Fragrance Bottle',
      nameAr: 'زجاجة عطر حرفية',
      descriptionEn: 'Hand-finished bottle with a botanical-inspired cap.',
      descriptionAr: 'زجاجة عطر مصنوعة يدويًا بغطاء مستوحى من الطبيعة.',
      price: 32.00,
      icon: Icons.local_florist_outlined,
      placeholderColor: AppColors.goldLight,
    ),
    Product(
      id: 'p-featured-4',
      nameEn: 'Travel Toiletry Kit',
      nameAr: 'طقم مستلزمات السفر',
      descriptionEn: 'Compact toiletry kit designed for travel comfort.',
      descriptionAr: 'طقم مستلزمات حمام مدمج مصمم لراحة السفر.',
      price: 15.75,
      icon: Icons.soap,
      placeholderColor: AppColors.primary,
    ),
  ];

  static const List<Product> newArrivals = [
    Product(
      id: 'p-new-1',
      nameEn: 'Emerald Ribbon Box',
      nameAr: 'صندوق بشريط زمردي',
      descriptionEn: 'A fresh addition to our gifting collection.',
      descriptionAr: 'إضافة جديدة إلى مجموعة الهدايا لدينا.',
      price: 12.50,
      icon: Icons.redeem_outlined,
      placeholderColor: AppColors.gold,
    ),
    Product(
      id: 'p-new-2',
      nameEn: 'Gold Leaf Candle Set',
      nameAr: 'طقم شموع بأوراق ذهبية',
      descriptionEn: 'Newly sourced candle set with a refined scent.',
      descriptionAr: 'طقم شموع جديد بعطر راقٍ.',
      price: 18.00,
      icon: Icons.local_fire_department_outlined,
      placeholderColor: AppColors.goldLight,
    ),
    Product(
      id: 'p-new-3',
      nameEn: 'Botanical Soap Trio',
      nameAr: 'ثلاثية الصابون النباتي',
      descriptionEn: 'Three-piece botanical soap set, newly stocked.',
      descriptionAr: 'طقم صابون نباتي من ثلاث قطع، وصل حديثًا.',
      price: 9.00,
      icon: Icons.eco_outlined,
      placeholderColor: AppColors.primary,
    ),
  ];

  static const List<Product> bestSellers = [
    Product(
      id: 'p-best-1',
      nameEn: 'Classic Wooden Gift Box',
      nameAr: 'صندوق هدايا خشبي كلاسيكي',
      descriptionEn: 'Our most requested gift box, in three sizes.',
      descriptionAr: 'صندوق الهدايا الأكثر طلبًا لدينا، بثلاثة أحجام.',
      price: 8.50,
      icon: Icons.inventory_2_outlined,
      placeholderColor: AppColors.primary,
    ),
    Product(
      id: 'p-best-2',
      nameEn: 'Deluxe Amenity Tray',
      nameAr: 'طقم مستلزمات ديلوكس',
      descriptionEn: 'A hospitality favorite, trusted across venues.',
      descriptionAr: 'المفضل لدى قطاع الضيافة والموثوق في مختلف الفعاليات.',
      price: 27.00,
      icon: Icons.room_service_outlined,
      placeholderColor: AppColors.gold,
    ),
    Product(
      id: 'p-best-3',
      nameEn: 'Everyday Fragrance Set',
      nameAr: 'طقم العطور اليومي',
      descriptionEn: 'A best-selling fragrance pairing, year-round.',
      descriptionAr: 'أفضل طقم عطور مبيعًا على مدار العام.',
      price: 21.00,
      icon: Icons.wb_sunny_outlined,
      placeholderColor: AppColors.goldLight,
    ),
  ];
}
