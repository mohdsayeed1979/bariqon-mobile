import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Premium Home header, per the Naqir-inspired redesign — logo, a
/// personalized greeting ("Hello, {name}"/"Hello, Guest"), a notification
/// icon, and the existing language toggle (moved here from the app bar,
/// since Home no longer uses [BrandedAppBar]). Replaces the previous
/// plain "Home" app bar + separate [WelcomeSection] title.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final session = ref.watch(authControllerProvider);
    final name = switch (session) {
      SignedInSession(:final user) => user.fullName,
      _ => l10n.homeGuestName,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const BrandLogo(
            size: BrandLogoSize.small,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.homeGreeting(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.homeNotificationsTooltip,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.homeFooterLinkSnackbar)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.toggleLanguageTooltip,
            onPressed: () {
              ref.read(localeProvider.notifier).state = locale.languageCode == 'en'
                  ? const Locale('ar')
                  : const Locale('en');
            },
          ),
        ],
      ),
    );
  }
}
