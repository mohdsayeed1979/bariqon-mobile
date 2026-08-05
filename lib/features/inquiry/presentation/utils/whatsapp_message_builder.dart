import 'package:flutter/widgets.dart';

import '../../domain/entities/inquiry_item.dart';

/// Builds the WhatsApp quote-request message — same wording and format as
/// the website's own "Request Quote on WhatsApp" button (confirmed by
/// reading the live site's bundled JS): a greeting, one line per cart
/// item (`• {quantity} x {name} (SKU: {sku})`), then a closing line.
/// Pure function, not a widget method, so the exact text can be tested in
/// isolation.
String buildWhatsAppQuoteMessage(List<InquiryItem> items, Locale locale) {
  final isArabic = locale.languageCode == 'ar';
  final buffer = StringBuffer(
    isArabic
        ? 'مرحباً باريقون للتجارة، أود طلب تسعيرة للمستلزمات التالية:\n\n'
        : 'Hello Bariqon Trading, I would like to request a quotation for:\n\n',
  );

  for (final item in items) {
    final sku = item.product.sku;
    final skuSuffix = (sku != null && sku.isNotEmpty) ? ' (SKU: $sku)' : '';
    buffer.writeln('• ${item.quantity} x ${item.product.name(locale)}$skuSuffix');
  }

  buffer.write(
    isArabic
        ? '\nيرجى تزويدنا بأسعار الجملة، خيارات التخصيص، ومواعيد التسليم المتوقعة. شكراً لكم!'
        : '\nPlease provide bulk pricing, customization options, and delivery timelines. Thank you!',
  );

  return buffer.toString();
}
