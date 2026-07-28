import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';

/// Generic scrollable legal-text screen — Privacy Policy and Terms &
/// Conditions are the same shape (title + long-form body), so both reuse
/// this rather than each being its own near-duplicate screen.
class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(title: title, showSearchAction: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
