import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/domain/entities/product.dart';
import '../../features/inquiry/presentation/controllers/inquiry_cart_controller.dart';
import 'empty_state_view.dart';
import 'product_card.dart';
import 'skeleton_product_card.dart';

/// Shared loading / empty / results rendering for any screen that shows a
/// filtered product list — Category Detail and Product Listing both use
/// this instead of each re-implementing the same skeleton-Wrap /
/// EmptyStateView / product-Wrap logic, per the Phase 2D reusability
/// requirement. "Send Inquiry" adds the product to [inquiryCartProvider]
/// (Phase 3) — local state only, no backend.
class ProductResultsView extends ConsumerWidget {
  const ProductResultsView({
    super.key,
    required this.loading,
    required this.products,
    required this.locale,
    required this.sendInquiryLabel,
    required this.sendInquirySnackbarText,
    this.onProductTap,
    required this.emptyIcon,
    required this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.skeletonCount = 4,
  });

  final bool loading;
  final List<Product> products;
  final Locale locale;
  final String sendInquiryLabel;
  final String sendInquirySnackbarText;
  final ValueChanged<Product>? onProductTap;

  final IconData emptyIcon;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  final int skeletonCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < skeletonCount; i++) const SkeletonProductCard(),
        ],
      );
    }

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyStateView(
          icon: emptyIcon,
          message: emptyMessage,
          actionLabel: emptyActionLabel,
          onAction: onEmptyAction,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final product in products)
          ProductCard(
            title: product.name(locale),
            description: product.description(locale),
            price: product.price,
            icon: product.icon,
            placeholderColor: product.placeholderColor,
            imageUrl: product.imageUrl,
            sendInquiryLabel: sendInquiryLabel,
            onTap: onProductTap == null ? null : () => onProductTap!(product),
            onSendInquiry: () {
              ref.read(inquiryCartProvider.notifier).addProduct(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(sendInquirySnackbarText)),
              );
            },
          ),
      ],
    );
  }
}
