import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Home screen footer, per the Phase 2B brief — brand mark, tagline,
/// contact/social icons, and a copyright line, kept deliberately compact
/// (tight spacing, dense icon row) per the polish request rather than the
/// first pass's generous padding. The icons are visually present but not
/// wired to real actions (no url_launcher, no contact flow) — this is UI
/// scaffolding, not a functioning Contact screen.
class HomeFooterSection extends StatelessWidget {
  const HomeFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    void showComingSoon() {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.homeFooterLinkSnackbar)));
    }

    Widget compactIcon(IconData icon, String tooltip) => IconButton(
      onPressed: showComingSoon,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandLogo(size: BrandLogoSize.small, padding: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.homeFooterTagline,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              compactIcon(Icons.chat_outlined, 'WhatsApp'),
              compactIcon(Icons.camera_alt_outlined, 'Instagram'),
              compactIcon(Icons.mail_outline, 'Email'),
              compactIcon(Icons.call_outlined, 'Call'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.homeFooterRights, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
