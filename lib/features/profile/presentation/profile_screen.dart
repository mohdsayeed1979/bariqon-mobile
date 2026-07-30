import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/avatar_placeholder.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/error/user_facing_message.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../inquiry/presentation/controllers/inquiry_cart_controller.dart';

/// Profile tab root, per docs/SCREEN_SPECIFICATIONS.md §18 and the Phase 4
/// brief — branches on [AuthSession] rather than being a single fixed
/// layout: Signed Out and Guest both show a sign-in prompt (Guest's is
/// softer, since they chose to browse without an account), Signed In shows
/// the real profile fields + Edit Profile. Settings is reachable from every
/// branch via the app bar action, since Language/Theme/About/Contact don't
/// require an account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.navProfile,
        showSearchAction: false,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: switch (session) {
        SignedOutSession() => _SignedOutPrompt(
          message: l10n.profileSignedOutMessage,
        ),
        GuestSession() => _SignedOutPrompt(message: l10n.profileGuestMessage),
        SignedInSession(:final user) => _SignedInProfile(user: user),
      },
    );
  }
}

class _SignedOutPrompt extends StatelessWidget {
  const _SignedOutPrompt({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ResponsiveCenter(
      width: ContentWidth.narrow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push('/auth/login'),
                child: Text(l10n.authSignInCta),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/auth/register'),
                child: Text(l10n.authRegisterCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInProfile extends ConsumerWidget {
  const _SignedInProfile({required this.user});

  final AppUser user;

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileSignOutConfirmTitle),
        content: Text(l10n.profileSignOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profileSignOutAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(authControllerProvider.notifier).signOut();
        // The inquiry cart is local, session-only state (see
        // InMemoryInquiryCartRepository) — not tied to any account, so it
        // survives sign-out on its own. On a shared device, the next
        // person to sign in would otherwise see (and could submit an
        // inquiry with) the previous user's cart.
        ref.read(inquiryCartProvider.notifier).clear();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ResponsiveCenter(
      width: ContentWidth.narrow,
      child: ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: Column(
            children: [
              const AvatarPlaceholder(radius: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                user.fullName,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (user.company.isNotEmpty)
                Text(
                  user.company,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.authEmailLabel),
                subtitle: Text(user.email),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(l10n.inquiryFormMobile),
                subtitle: Text(
                  user.mobile.isEmpty ? l10n.profileNotProvided : user.mobile,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public_outlined),
                title: Text(l10n.inquiryFormCountry),
                subtitle: Text(
                  user.country.isEmpty ? l10n.profileNotProvided : user.country,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.tonal(
          onPressed: () => context.push('/profile/edit', extra: user),
          child: Text(l10n.profileEditCta),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => _confirmSignOut(context, ref),
          child: Text(l10n.profileSignOutAction),
        ),
      ],
      ),
    );
  }
}
