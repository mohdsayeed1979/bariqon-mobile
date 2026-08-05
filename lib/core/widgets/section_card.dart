import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// Rounded card wrapper around a group of rows (typically
/// [SettingsListTile]s) — the "cleaner spacing, grouped menu sections,
/// rounded cards" look shared by the redesigned Profile and Settings
/// screens, in one place rather than each screen laying it out itself.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}
