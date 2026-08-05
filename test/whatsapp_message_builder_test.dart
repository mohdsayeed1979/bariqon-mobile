import 'package:bariqon_app/features/catalog/domain/entities/product.dart';
import 'package:bariqon_app/features/inquiry/domain/entities/inquiry_item.dart';
import 'package:bariqon_app/features/inquiry/presentation/utils/whatsapp_message_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required String id,
  required String nameEn,
  required String nameAr,
  String? sku,
}) => Product(
  id: id,
  categoryId: 'cat-1',
  nameEn: nameEn,
  nameAr: nameAr,
  descriptionEn: '',
  descriptionAr: '',
  price: 10,
  icon: Icons.card_giftcard,
  placeholderColor: Colors.brown,
  sku: sku,
);

void main() {
  group('buildWhatsAppQuoteMessage', () {
    test('matches the website\'s exact English format, including SKU', () {
      final items = [
        InquiryItem(
          product: _product(id: '1', nameEn: 'Woven Fabric Gift Box', nameAr: 'صندوق', sku: 'T03-green'),
          quantity: 3,
        ),
      ];

      final message = buildWhatsAppQuoteMessage(items, const Locale('en'));

      expect(
        message,
        'Hello Bariqon Trading, I would like to request a quotation for:\n\n'
        '• 3 x Woven Fabric Gift Box (SKU: T03-green)\n'
        '\nPlease provide bulk pricing, customization options, and delivery timelines. Thank you!',
      );
    });

    test('matches the website\'s exact Arabic format', () {
      final items = [
        InquiryItem(
          product: _product(id: '1', nameEn: 'Woven Fabric Gift Box', nameAr: 'صندوق هدايا', sku: 'T03-green'),
          quantity: 2,
        ),
      ];

      final message = buildWhatsAppQuoteMessage(items, const Locale('ar'));

      expect(
        message,
        'مرحباً باريقون للتجارة، أود طلب تسعيرة للمستلزمات التالية:\n\n'
        '• 2 x صندوق هدايا (SKU: T03-green)\n'
        '\nيرجى تزويدنا بأسعار الجملة، خيارات التخصيص، ومواعيد التسليم المتوقعة. شكراً لكم!',
      );
    });

    test('omits the SKU suffix when a product has none', () {
      final items = [
        InquiryItem(
          product: _product(id: '1', nameEn: 'Custom Box', nameAr: 'صندوق'),
          quantity: 1,
        ),
      ];

      final message = buildWhatsAppQuoteMessage(items, const Locale('en'));

      expect(message, contains('• 1 x Custom Box\n'));
      expect(message, isNot(contains('SKU')));
    });

    test('lists every cart item on its own line, once each', () {
      final items = [
        InquiryItem(product: _product(id: '1', nameEn: 'Box A', nameAr: 'أ'), quantity: 1),
        InquiryItem(product: _product(id: '2', nameEn: 'Box B', nameAr: 'ب'), quantity: 5),
      ];

      final message = buildWhatsAppQuoteMessage(items, const Locale('en'));

      expect('• 1 x Box A'.allMatches(message).length, 1);
      expect('• 5 x Box B'.allMatches(message).length, 1);
    });
  });
}
