import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Scoped error surface with a retry action, per docs/DESIGN_SYSTEM.md §8
/// and docs/IMPLEMENTATION_ROADMAP.md §12 — used inline within a screen
/// section, not as a full-screen takeover (that's reserved for the rare
/// unrecoverable case, per the roadmap's error-handling principle).
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            title ?? l10n.genericErrorTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message ?? l10n.genericErrorMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ],
      ),
    );
  }
}
