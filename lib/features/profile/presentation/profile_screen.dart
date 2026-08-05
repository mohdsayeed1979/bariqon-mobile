import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/avatar_placeholder.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/error/user_facing_message.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/settings_list_tile.dart';
import '../../../core/widgets/sign_in_prompt_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../inquiry/presentation/controllers/inquiry_cart_controller.dart';

/// Profile tab root, redesigned per the Naqir-inspired brief — an avatar/
/// name/email header, then grouped navigation rows (reusing
/// [SettingsListTile], the same row shape Settings already uses) instead
/// of the previous plain [Card] of [ListTile]s. Still branches on
/// [AuthSession]: Signed Out/Guest show [SignInPromptView], Signed In
/// shows the real profile. Every existing route/action this screen led to
/// is unchanged — only the layout is new.
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
          // Signed-in users already have a "Settings" row in the list
          // below — this app bar action only appears for Guest/Signed
          // Out sessions, which show the sign-in prompt instead and have
          // no in-list rows of their own to reach Settings from.
          if (session is! SignedInSession)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settingsTitle,
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: switch (session) {
        SignedOutSession() => SignInPromptView(message: l10n.profileSignedOutMessage),
        GuestSession() => SignInPromptView(message: l10n.profileGuestMessage),
        SignedInSession(:final user) => _SignedInProfile(user: user),
      },
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                AvatarPlaceholder(radius: 32, name: user.fullName),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            children: [
              SettingsListTile(
                icon: Icons.person_outline,
                label: l10n.profileEditCta,
                onTap: () => context.push('/profile/edit', extra: user),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.receipt_long_outlined,
                label: l10n.profileOrdersTitle,
                onTap: () => context.push('/profile/orders'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.location_on_outlined,
                label: l10n.profileAddressesTitle,
                onTap: () => context.push('/profile/addresses'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.notifications_outlined,
                label: l10n.settingsNotificationsTitle,
                onTap: () => context.push('/settings/notifications'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.settings_outlined,
                label: l10n.settingsTitle,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            children: [
              SettingsListTile(
                icon: Icons.info_outline,
                label: l10n.settingsAboutTitle,
                onTap: () => context.push('/settings/about'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.contact_mail_outlined,
                label: l10n.settingsContactTitle,
                onTap: () => context.push('/settings/contact'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.help_outline,
                label: l10n.profileFaqTitle,
                onTap: () => context.push('/profile/faq'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.privacy_tip_outlined,
                label: l10n.settingsPrivacyTitle,
                onTap: () => context.push('/settings/privacy'),
              ),
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.description_outlined,
                label: l10n.settingsTermsTitle,
                onTap: () => context.push('/settings/terms'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            children: [
              SettingsListTile(
                icon: Icons.logout,
                label: l10n.profileSignOutAction,
                color: Theme.of(context).colorScheme.error,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
