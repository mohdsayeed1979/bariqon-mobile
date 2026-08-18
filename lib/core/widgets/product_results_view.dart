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

  /// The *enclosing* scrollable's position (the ListView / SingleChildScroll-
  /// View this widget is embedded in on every screen that uses it). Windowing
  /// is driven off this rather than a self-owned NotificationListener: this
  /// widget is a descendant of that scrollable, and ScrollNotifications only
  /// bubble *up* to ancestors — a listener placed here would never see the
  /// parent's scroll, so incremental loading would silently never advance
  /// past the first page. Null when there is no enclosing scrollable (e.g.
  /// the Wishlist tab renders this in a plain column), in which case every
  /// item is rendered up front so nothing is ever unreachable.
  ScrollPosition? _scrollPosition;
  bool _fillScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scrollPosition) {
      _scrollPosition?.removeListener(_maybeLoadMore);
      _scrollPosition = position;
      _scrollPosition?.addListener(_maybeLoadMore);
    }
  }

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

  @override
  void dispose() {
    _scrollPosition?.removeListener(_maybeLoadMore);
    super.dispose();
  }

  bool _sameProductIds(List<Product> a, List<Product> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// Grows the visible window by one page when the enclosing scroll nears
  /// its end. Also fires once per frame while the rendered content is still
  /// shorter than the viewport (maxScrollExtent == 0) so a short-but-multi-
  /// page result fills the screen without needing a scroll gesture that
  /// isn't possible yet.
  void _maybeLoadMore() {
    final position = _scrollPosition;
    if (position == null || !mounted) return;
    if (_visibleCount >= widget.products.length) return;
    if (!position.hasContentDimensions || !position.hasPixels) return;
    if (position.maxScrollExtent - position.pixels < 600) {
      setState(() {
        _visibleCount = (_visibleCount + widget.pageSize).clamp(
          0,
          widget.products.length,
        );
      });
    }
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

    // With no enclosing scrollable there's no way to reveal more on scroll,
    // so windowing would permanently hide anything past the first page —
    // render every item instead.
    final effectiveCount = _scrollPosition == null
        ? widget.products.length
        : _visibleCount;
    final visibleProducts = widget.products.take(effectiveCount);
    final hasMore = effectiveCount < widget.products.length;

    // Fill the viewport when the current window is shorter than the screen
    // (so the user can't scroll to trigger the next page). Scheduled at most
    // once per frame; converges because each pass adds a bounded page.
    if (hasMore && _scrollPosition != null && !_fillScheduled) {
      _fillScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillScheduled = false;
        _maybeLoadMore();
      });
    }

    return Column(
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
        if (hasMore)
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
    );
  }
}
