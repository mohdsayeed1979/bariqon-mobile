import 'package:bariqon_app/features/catalog/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  double price = 10,
  bool discountEnabled = false,
  double? discountPercentage,
  double? discountPrice,
  DateTime? discountStartDate,
  DateTime? discountEndDate,
}) => Product(
  id: '1',
  categoryId: 'cat-1',
  nameEn: 'Test Product',
  nameAr: 'منتج',
  descriptionEn: '',
  descriptionAr: '',
  price: price,
  icon: Icons.card_giftcard,
  placeholderColor: Colors.brown,
  discountEnabled: discountEnabled,
  discountPercentage: discountPercentage,
  discountPrice: discountPrice,
  discountStartDate: discountStartDate,
  discountEndDate: discountEndDate,
);

void main() {
  group('Product discount fields', () {
    test('no discount by default — effectivePrice is the base price', () {
      final product = _product(price: 10);
      expect(product.hasActiveDiscount, isFalse);
      expect(product.effectivePrice, 10);
      expect(product.discountBadgePercent, isNull);
    });

    test(
      'discount_enabled without discount_price does not activate — missing '
      'the required sale price',
      () {
        final product = _product(price: 10, discountEnabled: true);
        expect(product.hasActiveDiscount, isFalse);
        expect(product.effectivePrice, 10);
      },
    );

    test('active discount overrides the effective price and badge percent', () {
      final product = _product(
        price: 10,
        discountEnabled: true,
        discountPercentage: 20,
        discountPrice: 8,
      );
      expect(product.hasActiveDiscount, isTrue);
      expect(product.effectivePrice, 8);
      expect(product.discountBadgePercent, 20);
    });

    test(
      'badge percent is derived from price vs discount_price when '
      'discount_percentage is left null',
      () {
        final product = _product(
          price: 10,
          discountEnabled: true,
          discountPrice: 7.5,
        );
        expect(product.discountBadgePercent, 25);
      },
    );

    test('a future start date keeps the discount inactive', () {
      final product = _product(
        price: 10,
        discountEnabled: true,
        discountPrice: 8,
        discountStartDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(product.hasActiveDiscount, isFalse);
      expect(product.effectivePrice, 10);
    });

    test('a past end date keeps the discount inactive', () {
      final product = _product(
        price: 10,
        discountEnabled: true,
        discountPrice: 8,
        discountEndDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(product.hasActiveDiscount, isFalse);
    });

    test('discount_enabled=false always wins, even with a valid price/window', () {
      final product = _product(
        price: 10,
        discountEnabled: false,
        discountPrice: 8,
        discountStartDate: DateTime.now().subtract(const Duration(days: 1)),
        discountEndDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(product.hasActiveDiscount, isFalse);
    });
  });
}
