import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';

/// About Bariqon screen, per the Phase 4 brief — premium layout using the
/// Bariqon logo and company copy. Static content; no backend/CMS behind it.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.settingsAboutTitle, showSearchAction: false),
      body: SafeArea(
        child: ResponsiveCenter(
          width: ContentWidth.wide,
          child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Center(child: BrandLogo(size: BrandLogoSize.medium)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.aboutTagline,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.aboutDescription,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                l10n.aboutVersionLabel(_appVersion),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
