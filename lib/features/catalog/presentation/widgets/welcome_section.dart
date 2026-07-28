import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Home screen welcome block — brand greeting + short tagline, per the
/// Phase 2B brief.
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeWelcomeTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            l10n.homeWelcomeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
