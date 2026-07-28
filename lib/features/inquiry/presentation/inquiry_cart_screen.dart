import 'package:flutter/material.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/coming_soon_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Inquiry tab root — Phase 2A placeholder. Becomes the real Inquiry Cart
/// screen (docs/SCREEN_SPECIFICATIONS.md §9) in a later phase, once cart
/// state and submission are in scope.
class InquiryCartScreen extends StatelessWidget {
  const InquiryCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BrandedAppBar(title: l10n.navInquiry),
      body: ComingSoonPlaceholder(
        title: l10n.navInquiry,
        icon: Icons.shopping_bag_outlined,
      ),
    );
  }
}
