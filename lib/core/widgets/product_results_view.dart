import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/domain/entities/product.dart';
import '../../features/inquiry/presentation/controllers/inquiry_cart_controller.dart';
import '../../features/wishlist/presentation/controllers/wishlist_controller.dart';
import '../../features/wishlist/presentation/utils/wishlist_toggle.dart';
import '../constants/app_sizes.dart';
import 'empty_state_view.dart';
import 'product_card.dart';
import 'skeleton_product_card.dart';

/// Shared loading / empty / results rendering for any screen that shows a
/// filtered product list — Category Detail, Product Listing, and Search
/// all use this instead of each re-implementing the same skeleton-Wrap /
/// EmptyStateView / product-Wrap logic, per the Phase 2D reusability
/// requirement. "Send Inquiry" adds the product to [inquiryCartProvider]
/// (Phase 3) — local state only, no backend.
///
/// [products] is rendered [pageSize] at a time, growing as the ancestor
/// scrollable nears its end, rather than mounting every result up front —
/// the production catalog is 200+ products, and building/decoding that
/// many [ProductCard]s (each with a network image) on first frame is real,
/// measurable jank and memory pressure for what's usually an unfiltered
/// "browse everything" view. The `Wrap` layout itself is unchanged — this
/// only caps how many of its children exist at once.
class ProductResultsView extends ConsumerStatefulWidget {
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
    this.pageSize = 24,
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
  final int pageSize;

  @override
  ConsumerState<ProductResultsView> createState() => _ProductResultsViewState();
}

class _ProductResultsViewState extends ConsumerState<ProductResultsView> {
  late int _visibleCount = widget.pageSize;

  @override
  void didUpdateWidget(covariant ProductResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new result set (search/filter/sort changed) starts over at one
    // page. Compared by id sequence, not list identity/reference — the
    // caller recomputes `products` via applyProductFilters on every
    // rebuild regardless of whether the filter actually changed, so a
    // reference check would reset (and visibly shrink) an already
    // scroll-grown list on any unrelated rebuild.
    if (!_sameProductIds(oldWidget.products, widget.products)) {
      _visibleCount = widget.pageSize;
    }
  }

  bool _sameProductIds(List<Product> a, List<Product> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_visibleCount >= widget.products.length) return false;
    final metrics = notification.metrics;
    if (metrics.maxScrollExtent - metrics.pixels < 600) {
      setState(() {
        _visibleCount = (_visibleCount + widget.pageSize).clamp(
          0,
          widget.products.length,
        );
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < widget.skeletonCount; i++)
            const SkeletonProductCard(),
        ],
      );
    }

    final wishlistedIds = ref.watch(wishlistControllerProvider).value ?? const {};

    if (widget.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyStateView(
          icon: widget.emptyIcon,
          message: widget.emptyMessage,
          actionLabel: widget.emptyActionLabel,
          onAction: widget.onEmptyAction,
        ),
      );
    }

    final visibleProducts = widget.products.take(_visibleCount);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final product in visibleProducts)
                // Isolates each card's own repaints (e.g. its image
                // fade-in) from its neighbors — without this, one card
                // updating can force the whole Wrap's paint layer to
                // redraw.
                RepaintBoundary(
                  key: ValueKey(product.id),
                  child: ProductCard(
                    title: product.name(widget.locale),
                    description: product.description(widget.locale),
                    price: product.effectivePrice,
                    originalPrice: product.hasActiveDiscount ? product.price : null,
                    discountBadgePercent: product.discountBadgePercent,
                    stockStatus: product.stockStatus,
                    icon: product.icon,
                    placeholderColor: product.placeholderColor,
                    imageUrl: product.imageUrl,
                    sendInquiryLabel: widget.sendInquiryLabel,
                    isWishlisted: wishlistedIds.contains(product.id),
                    onToggleWishlist: () => toggleWishlist(context, ref, product),
                    onTap: widget.onProductTap == null
                        ? null
                        : () => widget.onProductTap!(product),
                    onSendInquiry: () {
                      ref.read(inquiryCartProvider.notifier).addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.sendInquirySnackbarText)),
                      );
                    },
                  ),
                ),
            ],
          ),
          if (_visibleCount < widget.products.length)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
