import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../error/user_facing_message.dart';

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
    this.actionLabel,
  });

  /// Builds from a caught error/[Failure] rather than a caller-chosen
  /// message — a [NetworkFailure] reads as "check your connection" instead
  /// of the generic fallback, which matters to a user (one says try later,
  /// the other says check your wifi). Other [Failure] subtypes still fall
  /// through to the generic message: their `.message` strings are plain
  /// English, not localized or written for end users — see failure.dart.
  factory ErrorStateView.forError(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    String? actionLabel,
  }) {
    return ErrorStateView(
      message: userFacingErrorMessage(context, error),
      onRetry: onRetry,
      actionLabel: actionLabel,
    );
  }

  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  /// Overrides the button's default "Retry" label — e.g. "Go Back" when
  /// the error is an unrecoverable bad id/link rather than something a
  /// retry could actually fix.
  final String? actionLabel;

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
            OutlinedButton(
              onPressed: onRetry,
              child: Text(actionLabel ?? l10n.retry),
            ),
          ],
        ],
      ),
    );
  }
}
