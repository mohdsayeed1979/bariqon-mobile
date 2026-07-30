import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/entities/inquiry.dart';

/// Inquiry Confirmation, per the Phase 3 brief — premium success layout
/// with a mock reference number. Reached only via
/// [InquiryDetailsFormScreen]'s local "submission" (see that screen's doc
/// comment — no backend call happens there either); the [inquiry] snapshot
/// is passed through go_router's `extra`, not persisted anywhere.
class InquiryConfirmationScreen extends StatelessWidget {
  const InquiryConfirmationScreen({super.key, this.inquiry});

  final Inquiry? inquiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.inquiryConfirmationTitle,
        showSearchAction: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: inquiry == null
                ? ErrorStateView(
                    message: l10n.genericErrorMessage,
                    actionLabel: l10n.inquiryConfirmationContinueCta,
                    onRetry: () => context.go('/home'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: AppIconSize.avatar,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.inquiryConfirmationHeading,
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.inquiryConfirmationMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.inquiryConfirmationReferenceLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inquiry!.referenceNumber,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => context.go('/home'),
                          child: Text(l10n.inquiryConfirmationContinueCta),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
