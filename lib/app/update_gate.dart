import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/update/in_app_update_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Enforces a mandatory Google Play update at startup, above everything else.
///
/// Wraps `MaterialApp.router`'s `builder` *outside* [AppLockGate] (see
/// app.dart), so the update requirement sits above the Navigator — and above
/// the lock screen — and can't be routed around. It asks Google Play once on
/// cold start; if, and only if, Play reports an available Immediate update, it
/// launches Play's official full-screen update flow and holds the user on a
/// non-dismissable screen (no Skip, no Later, no back button) until the update
/// completes. On every non-Play platform, debug/sideloaded build, offline
/// state, or Play error, it renders the app normally — Play never confirmed an
/// update, so nothing is forced (Phases 5–7, 10).
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _forced = false;

  @override
  void initState() {
    super.initState();
    // After the first frame so the app renders immediately; the check is
    // async and only ever *adds* a blocking overlay, never delays startup.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final status = await ref.read(inAppUpdateServiceProvider).check();
    if (!mounted || status != UpdateStatus.forced) return;
    setState(() => _forced = true);
    // Immediately hand off to Play's official Immediate flow. On success Play
    // installs and restarts the app; on cancel/failure the blocking screen
    // below stays up with a Retry action — the user never reaches the app.
    unawaited(ref.read(inAppUpdateServiceProvider).startImmediate());
  }

  void _retry() {
    unawaited(ref.read(inAppUpdateServiceProvider).startImmediate());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_forced) _MandatoryUpdateScreen(onUpdate: _retry),
      ],
    );
  }
}

/// Minimal fallback shown behind Play's own update UI — visible only if the
/// user backs out of the official flow. Blocks back navigation so a mandatory
/// update can't be dismissed.
class _MandatoryUpdateScreen extends StatelessWidget {
  const _MandatoryUpdateScreen({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Material(
        color: theme.colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.system_update,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.updateRequiredTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.updateRequiredMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onUpdate,
                  child: Text(l10n.updateNowCta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
