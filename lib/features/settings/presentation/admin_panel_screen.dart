import 'package:flutter/material.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/coming_soon_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Admin Panel entry point — only reachable via Settings' conditional
/// "Admin Panel" row (admin accounts only). Catalog/inquiry management
/// itself is a separate, future phase (already scoped in the roadmap as
/// deferred mobile Admin); this is the access-gated placeholder that
/// proves the visibility gating works end to end.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.adminPanelTitle,
        showSearchAction: false,
      ),
      body: ComingSoonPlaceholder(
        title: l10n.adminPanelTitle,
        icon: Icons.admin_panel_settings_outlined,
      ),
    );
  }
}
