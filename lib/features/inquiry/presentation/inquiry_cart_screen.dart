import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/inquiry_summary_card.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/inquiry_cart_controller.dart';
import 'widgets/inquiry_cart_item_tile.dart';

/// Inquiry tab root — the real Inquiry Cart, per the Phase 3 brief: add,
/// remove, update quantities, clear, empty state, and a summary leading
/// into the Inquiry Details Form. Backed by [inquiryCartProvider] — local
/// Riverpod state only, no Supabase, per the brief.
class InquiryCartScreen extends ConsumerWidget {
  const InquiryCartScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inquiryCartClearConfirmTitle),
        content: Text(l10n.inquiryCartClearConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.inquiryCartClearAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(inquiryCartProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final items = ref.watch(inquiryCartProvider);
    final itemCount = ref.watch(inquiryCartItemCountProvider);
    final subtotal = ref.watch(inquiryCartSubtotalProvider);

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.inquiryCartTitle,
        showSearchAction: false,
        extraActions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.inquiryCartClearAction,
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: EmptyStateView(
                  icon: Icons.shopping_bag_outlined,
                  message: l10n.inquiryCartEmptyMessage,
                  actionLabel: l10n.inquiryCartEmptyCta,
                  onAction: () => context.push('/products'),
                ),
              )
            : ResponsiveCenter(
                width: ContentWidth.wide,
                child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return InquiryCartItemTile(
                              item: item,
                              title: item.product.name(locale),
                              removeTooltip: l10n.inquiryRemoveItemTooltip,
                              onQuantityChanged: (quantity) => ref
                                  .read(inquiryCartProvider.notifier)
                                  .updateQuantity(item.product.id, quantity),
                              onRemove: () => ref
                                  .read(inquiryCartProvider.notifier)
                                  .removeProduct(item.product.id),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            InquirySummaryCard(
                              itemsLabel: l10n.inquiryCartItemsLabel(itemCount),
                              totalLabel: l10n.inquiryEstimatedTotalLabel,
                              estimatedTotal: subtotal,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: () => context.push('/inquiry/details'),
                                child: Text(l10n.inquiryProceedButton),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ),
      ),
    );
  }
}
