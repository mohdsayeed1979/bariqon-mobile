import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// Section title + optional trailing action ("View all"), per
/// docs/IMPLEMENTATION_ROADMAP.md §2 — used across Home and, later,
/// Catalog screens so every horizontally-scrolling section introduces
/// itself the same way.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded + maxLines/ellipsis: a long translated title (Arabic
          // section titles run longer than their English source) shrinks
          // instead of pushing the trailing action off the Row's bounds.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
