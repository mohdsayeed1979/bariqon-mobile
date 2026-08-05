import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/sign_in_prompt_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'controllers/inquiry_history_controller.dart';

/// "My Orders" — real, functional Inquiry History. `cms_contact_messages`
/// has no order/user-ownership concept (this is a wholesale quote-request
/// table, not e-commerce orders), so this lists what's actually
/// recordable: every inquiry this account has submitted from this
/// device, via [inquiryHistoryControllerProvider].
class InquiryHistoryScreen extends ConsumerWidget {
  const InquiryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.profileOrdersTitle, showSearchAction: false),
      body: session is! SignedInSession
          ? SignInPromptView(message: l10n.profileSignedOutMessage)
          : _HistoryList(),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final historyAsync = ref.watch(inquiryHistoryControllerProvider);
    final dateFormat = intl.DateFormat.yMMMd(locale.toString()).add_jm();

    return AsyncValueView(
      value: historyAsync,
      onRetry: () => ref.invalidate(inquiryHistoryControllerProvider),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              message: l10n.ordersEmptyMessage,
            ),
          );
        }
        return ResponsiveCenter(
          width: ContentWidth.wide,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text('${l10n.ordersReferenceLabel}: ${entry.referenceNumber}'),
                  subtitle: Text(
                    '${dateFormat.format(entry.submittedAt)}\n'
                    '${l10n.ordersEntrySummary(entry.itemCount, entry.totalQuantity)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
