import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/product.dart';

/// Generic horizontally-scrolling product rail — reused for Featured
/// Products, New Arrivals, and Best Sellers on Home (same shape, per the
/// Phase 2B brief, just different mock data/title each time).
///
/// Deliberately no fixed-height container around the row: [ProductCard]
/// sizes itself to its own content, and [IntrinsicHeight] sizes this
/// scroller to whatever that turns out to be. A guessed pixel height here
/// was the exact cause of the RenderFlex overflow flagged in the first
/// Phase 2B pass — this shape can't drift out of sync with the card again.
class ProductSection extends StatelessWidget {
  const ProductSection({
    super.key,
    required this.title,
    required this.products,
  });

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final product = products[i];
                      return ProductCard(
                        title: product.name(locale),
                        description: product.description(locale),
                        price: product.price,
                        icon: product.icon,
                        placeholderColor: product.placeholderColor,
                        sendInquiryLabel: l10n.homeSendInquiry,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.homeProductDetailSnackbar)),
                        ),
                        onSendInquiry: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.homeSendInquirySnackbar),
                              ),
                            ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
