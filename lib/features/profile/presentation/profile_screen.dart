import 'package:flutter/material.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/coming_soon_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Profile tab root — Phase 2A placeholder. Becomes the real Profile
/// screen (docs/SCREEN_SPECIFICATIONS.md §18) once auth exists; that
/// screen's own spec also covers the guest/unauthenticated state, which
/// isn't distinguished yet here since there's no auth in this phase.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BrandedAppBar(title: l10n.navProfile),
      body: ComingSoonPlaceholder(
        title: l10n.navProfile,
        icon: Icons.person_outline,
      ),
    );
  }
}
