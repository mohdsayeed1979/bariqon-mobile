import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/entities/category.dart';
import '../domain/entities/product.dart';

/// Local, static mock data for the Home and Categories screens — per the
/// Phase 2B/2C briefs, no backend, no Supabase, no API. Category/product
/// names are drawn from Bariqon's real, publicly-known business lines
/// (confirmed in docs/BACKEND_INTEGRATION_REPORT.md) so the UI feels
/// authentic rather than generic, but every id/description/price here is
/// placeholder content for layout purposes — none of it is read from or
/// written to any backend. Swapped for `ProductRepository`/
/// `CategoryRepository` calls once Supabase is connected.
class MockCatalogData {
  const MockCatalogData._();

  static const List<Category> categories = [
    Category(
      id: 'luxury-gift-boxes',
      nameEn: 'Luxury Gift Boxes',
      nameAr: 'صناديق الهدايا الفاخرة',
      descriptionEn:
          'Elegantly crafted boxes for weddings, corporate gifting, and every '
          'occasion in between.',
      descriptionAr: 'صناديق مصممة بأناقة لحفلات الزفاف والهدايا المؤسسية وكل مناسبة.',
      icon: Icons.card_giftcard_outlined,
    ),
    Category(
      id: 'hospitality',
      nameEn: 'Hospitality Amenities',
      nameAr: 'مستلزمات الضيافة',
      descriptionEn:
          'Curated amenity sets and trays trusted by leading hotels and '
          'venues across the region.',
      descriptionAr: 'أطقم ومستلزمات ضيافة موثوقة لدى كبرى الفنادق والمنشآت في المنطقة.',
      icon: Icons.hotel_outlined,
    ),
    Category(
      id: 'perfumery-cosmetics',
      nameEn: 'Perfumery & Cosmetics',
      nameAr: 'العطور ومستحضرات التجميل',
      descriptionEn:
          'Fine fragrances and cosmetics, thoughtfully sourced for a refined '
          'finish.',
      descriptionAr: 'عطور ومستحضرات تجميل فاخرة، مُنتقاة بعناية للمسة راقية.',
      icon: Icons.spa_outlined,
    ),
    Category(
      id: 'toiletries',
      nameEn: 'Toiletries',
      nameAr: 'مستلزمات الحمام',
      descriptionEn: 'Everyday bath and travel essentials with a premium finish.',
      descriptionAr: 'مستلزمات حمام وسفر يومية بلمسة نهائية فاخرة.',
      icon: Icons.soap_outlined,
    ),
    Category(
      id: 'general-trading',
      nameEn: 'General Trading',
      nameAr: 'التجارة العامة',
      descriptionEn:
          'Reliable sourcing across a broad range of goods, tailored to your '
          'business needs.',
      descriptionAr: 'توريد موثوق لمجموعة واسعة من البضائع، بما يلائم احتياجات عملك.',
      icon: Icons.storefront_outlined,
    ),
  ];

  static const List<Product> featured = [
    Product(
      id: 'p-featured-1',
      categoryId: 'luxury-gift-boxes',
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
      categoryId: 'hospitality',
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
      categoryId: 'perfumery-cosmetics',
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
      categoryId: 'toiletries',
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
      categoryId: 'luxury-gift-boxes',
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
      categoryId: 'hospitality',
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
      categoryId: 'toiletries',
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
      categoryId: 'luxury-gift-boxes',
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
      categoryId: 'hospitality',
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
      categoryId: 'perfumery-cosmetics',
      nameEn: 'Everyday Fragrance Set',
      nameAr: 'طقم العطور اليومي',
      descriptionEn: 'A best-selling fragrance pairing, year-round.',
      descriptionAr: 'أفضل طقم عطور مبيعًا على مدار العام.',
      price: 21.00,
      icon: Icons.wb_sunny_outlined,
      placeholderColor: AppColors.goldLight,
    ),
  ];

  /// All mock products across every rail, deduplicated by id — the source
  /// list [CategoryDetailScreen] filters by `categoryId`. `general-trading`
  /// deliberately has zero products among these, so that category
  /// demonstrates the real Empty State (Phase 2C requirement) rather than
  /// every category conveniently having content.
  static List<Product> get allProducts => [
    ...featured,
    ...newArrivals,
    ...bestSellers,
  ];

  static List<Product> productsForCategory(String categoryId) =>
      allProducts.where((p) => p.categoryId == categoryId).toList();

  static Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static Product? productById(String id) {
    for (final product in allProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  /// Other products in the same category, excluding [product] itself —
  /// backs Product Detail's Related Products rail.
  static List<Product> relatedProducts(Product product, {int limit = 6}) {
    final related = productsForCategory(
      product.categoryId,
    ).where((p) => p.id != product.id).toList();
    return related.length > limit ? related.sublist(0, limit) : related;
  }
}
