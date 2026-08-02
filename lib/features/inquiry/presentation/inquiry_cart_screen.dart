import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/contact_links.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/presentation/controllers/catalog_providers.dart';
import '../../catalog/presentation/utils/catalog_selectors.dart';
import '../../settings/domain/site_contact_settings.dart';
import '../../settings/presentation/controllers/site_settings_controller.dart';
import '../domain/entities/inquiry_item.dart';
import 'controllers/inquiry_cart_controller.dart';
import 'utils/whatsapp_message_builder.dart';
import 'widgets/inquiry_cart_item_tile.dart';

/// Inquiry tab root — the real Inquiry Cart, matching the website's own
/// cart drawer: product rows (image/category/SKU/name/quantity/remove),
/// a unique-items/total-quantity summary (no pricing — this is a
/// wholesale quote request, not a checkout), and two ways to send it:
/// WhatsApp (instant, no form) or Email (via the Inquiry Details Form).
/// Backed by [inquiryCartProvider] — local Riverpod state only.
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

  Future<void> _requestQuoteOnWhatsApp(
    BuildContext context,
    WidgetRef ref,
    List<InquiryItem> items,
    Locale locale,
  ) async {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.read(siteContactSettingsProvider).value ?? SiteContactSettings.fallback;
    final message = buildWhatsAppQuoteMessage(items, locale);
    final opened = await ContactLinks.launch(
      ContactLinks.whatsappWithMessage(settings, message),
    );
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.contactLinkFailedMessage)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final items = ref.watch(inquiryCartProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value;

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
                            final category = categories == null
                                ? null
                                : categoryById(categories, item.product.categoryId);
                            return InquiryCartItemTile(
                              item: item,
                              title: item.product.name(locale),
                              categoryLabel: category?.name(locale),
                              removeLabel: l10n.inquiryRemoveLabel,
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
                            _CartCountSummary(
                              uniqueItems: items.length,
                              totalQuantity: items.fold(
                                0,
                                (sum, item) => sum + item.quantity,
                              ),
                              uniqueItemsLabel: l10n.inquiryCartTotalUniqueItems,
                              totalQuantityLabel: l10n.inquiryCartEstimatedTotalQty,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: () =>
                                    _requestQuoteOnWhatsApp(context, ref, items, locale),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: AppColors.primary,
                                ),
                                child: _ActionButtonLabel(
                                  icon: Icons.chat_bubble_outline,
                                  label: l10n.inquiryWhatsappButton,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => context.push('/inquiry/details'),
                                child: _ActionButtonLabel(
                                  icon: Icons.description_outlined,
                                  label: l10n.inquiryEmailQuoteButton,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: TextButton(
                                    onPressed: () => context.push('/products'),
                                    child: Text(
                                      l10n.inquiryCartContinueShoppingLink,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: TextButton(
                                    onPressed: () => _confirmClear(context, ref),
                                    child: Text(
                                      l10n.inquiryCartClearAllLink,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
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

/// Icon + label for the cart's two action buttons, with the label
/// wrapped in [Flexible]/ellipsis so a long translated string (e.g.
/// "Request Quote on WhatsApp") shrinks to fit instead of overflowing the
/// button at narrow widths — `FilledButton.icon`/`OutlinedButton.icon`
/// don't guard against that on their own.
class _ActionButtonLabel extends StatelessWidget {
  const _ActionButtonLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// "Total Unique Items" / "Estimated Total Qty" — counts only, no price,
/// matching the website's own cart summary (this is a wholesale quote
/// request, not a checkout with totals).
class _CartCountSummary extends StatelessWidget {
  const _CartCountSummary({
    required this.uniqueItems,
    required this.totalQuantity,
    required this.uniqueItemsLabel,
    required this.totalQuantityLabel,
  });

  final int uniqueItems;
  final int totalQuantity;
  final String uniqueItemsLabel;
  final String totalQuantityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _row(theme, uniqueItemsLabel, uniqueItems, background: theme.colorScheme.surface),
          const Divider(height: AppSpacing.lg),
          _row(theme, totalQuantityLabel, totalQuantity, background: AppColors.gold.withValues(alpha: 0.12)),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, int value, {required Color background}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$value',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
