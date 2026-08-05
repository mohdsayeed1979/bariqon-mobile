import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/controllers/app_lock_controller.dart';
import '../features/settings/presentation/widgets/lock_screen.dart';

/// Enforces App Lock across the whole app, regardless of which route is
/// current — wraps `MaterialApp.router`'s `builder`, per app.dart, so it
/// sits above the [Navigator] rather than needing every screen to check
/// lock state itself.
///
/// Locks on cold start (if enabled) and again on resume once the
/// configured [AppLockTimeout] has elapsed since the app was last
/// backgrounded — a plain `WidgetsBindingObserver`, no new architecture.
/// A no-op (never locks) when App Lock is disabled — true for every
/// `flutter test` run today, since App Lock defaults to off and tests
/// never enable it.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  late bool _locked = ref.read(appLockControllerProvider).enabled;
  DateTime? _pausedAt;

  /// True for the whole span of a biometric prompt (see
  /// [LockScreen.onAuthenticatingChanged]). Showing the OS biometric UI
  /// itself drives this app through `inactive`/`paused` → `resumed` — that
  /// is the system prompt taking focus, not the user backgrounding the
  /// app, and treating it as the latter was the exact cause of the
  /// infinite re-lock loop: a *successful* unlock's own prompt would
  /// immediately trigger another "resumed" event, which (especially with
  /// the "Immediately" timeout) re-locked before the unlock ever had a
  /// chance to render, prompting again forever. Lifecycle changes are
  /// ignored outright while this is true, so a prompt can never re-lock
  /// the app it's in the middle of unlocking.
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setAuthenticating(bool value) {
    _authenticating = value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;

    final settings = ref.read(appLockControllerProvider);
    if (!settings.enabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt == null) return;
      if (DateTime.now().difference(pausedAt) >= settings.timeout.duration) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockControllerProvider).enabled;
    // App Lock turned off (from inside a still-open Settings screen, say)
    // while locked — nothing to protect anymore, drop the overlay.
    if (!enabled && _locked) {
      _locked = false;
    }

    return Stack(
      children: [
        widget.child,
        if (_locked)
          LockScreen(
            onUnlocked: () => setState(() => _locked = false),
            onAuthenticatingChanged: _setAuthenticating,
          ),
      ],
    );
  }
}
