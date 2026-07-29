import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "Why Choose Bariqon" value-proposition grid, per the Phase 2B brief —
/// static content, no data source.
///
/// Two [Row]s of two [Expanded] cells rather than a [GridView] with a
/// fixed `childAspectRatio` — a GridView cell has a *forced* height, and
/// content taller than that guess overflows with no way to recover
/// (exactly what happened here in the first Phase 2B pass). Each cell's
/// height is content-driven instead (`mainAxisSize.min`), wrapped in
/// [IntrinsicHeight] per row so the two cells in a row still match
/// visually without either one dictating a height the other must fit.
class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final reasons = [
      (
        icon: Icons.verified_outlined,
        title: l10n.homeWhyReason1Title,
        desc: l10n.homeWhyReason1Desc,
      ),
      (
        icon: Icons.handshake_outlined,
        title: l10n.homeWhyReason2Title,
        desc: l10n.homeWhyReason2Desc,
      ),
      (
        icon: Icons.design_services_outlined,
        title: l10n.homeWhyReason3Title,
        desc: l10n.homeWhyReason3Desc,
      ),
      (
        icon: Icons.local_shipping_outlined,
        title: l10n.homeWhyReason4Title,
        desc: l10n.homeWhyReason4Desc,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.homeWhyChooseTitle),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: AppSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _ReasonCard(reasons[row * 2])),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _ReasonCard(reasons[row * 2 + 1])),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard(this.reason);

  final ({IconData icon, String title, String desc}) reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(reason.icon, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            reason.desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
