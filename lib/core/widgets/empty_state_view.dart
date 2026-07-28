import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Icon + message (+ optional action) empty-state surface, per
/// docs/DESIGN_SYSTEM.md §8 and docs/IMPLEMENTATION_ROADMAP.md §13.
/// Every screen-specific empty condition in SCREEN_SPECIFICATIONS.md
/// renders through this, parameterized differently — not a bespoke widget
/// per screen.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message ?? l10n.emptyStateGenericMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
