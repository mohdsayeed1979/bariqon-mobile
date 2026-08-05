import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_sizes.dart';
import '../../l10n/generated/app_localizations.dart';
import 'responsive_center.dart';

/// Shared "sign in to continue" prompt — used by every screen that needs
/// an account (Profile, Wishlist) when the session is Guest/Signed Out,
/// so the icon/copy/buttons/navigation only live in one place.
class SignInPromptView extends StatelessWidget {
  const SignInPromptView({super.key, required this.message, this.icon = Icons.account_circle_outlined});

  final String message;
  final IconData icon;

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
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
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
