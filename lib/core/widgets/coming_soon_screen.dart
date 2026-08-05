import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'branded_app_bar.dart';
import 'empty_state_view.dart';

/// Placeholder screen for a Profile menu entry that doesn't have a real
/// feature yet (Orders, Addresses, FAQ) — prepares the navigation entry
/// point per the brief ("prepare for future") without fabricating fake
/// data or functionality.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BrandedAppBar(title: title, showSearchAction: false),
      body: Center(
        child: EmptyStateView(icon: icon, message: l10n.comingSoonMessage),
      ),
    );
  }
}
