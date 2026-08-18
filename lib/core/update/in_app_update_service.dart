import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import '../logging/app_logger.dart';

/// Outcome of a Google Play update check, reduced to the only decision the
/// app cares about: must the user be forced to update before continuing?
enum UpdateStatus {
  /// Carry on — Play reported no update, or we couldn't reach Play (offline,
  /// not a Play-distributed build, debug/sideload, API error). A failure to
  /// *reach* Play is never treated as "update required".
  none,

  /// Play affirmatively reports an available Immediate update (or one already
  /// in progress) — the user must complete it before using the app.
  forced,
}

/// Pure decision rule: force an update only when Google Play itself says an
/// Immediate update is available (or is already in progress and must be
/// resumed). Never a hardcoded version comparison — this keeps working for
/// every future release with no code change. Kept as a top-level function so
/// it can be unit-tested without the platform channel.
bool isMandatoryUpdate({
  required UpdateAvailability availability,
  required bool immediateAllowed,
}) {
  final available =
      availability == UpdateAvailability.updateAvailable ||
      availability == UpdateAvailability.developerTriggeredUpdateInProgress;
  return available && immediateAllowed;
}

/// Thin, testable wrapper over the official Google Play In-App Update API
/// (`in_app_update` → Play Core `AppUpdateManager`).
///
/// Android-only by construction: every method is a safe no-op on iOS, on the
/// web, and in the `flutter test` VM (host OS is not Android), so this can
/// never block a non-Play build or a test run. Overridable via
/// [inAppUpdateServiceProvider] so tests can drive the gate deterministically.
class InAppUpdateService {
  const InAppUpdateService();

  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Asks Google Play whether a mandatory (Immediate) update is available.
  /// Returns [UpdateStatus.none] on any unsupported platform and on ANY error
  /// — we only ever block when Play affirmatively confirms an update.
  Future<UpdateStatus> check() async {
    if (!_supported) return UpdateStatus.none;
    try {
      final info = await InAppUpdate.checkForUpdate();
      return isMandatoryUpdate(
            availability: info.updateAvailability,
            immediateAllowed: info.immediateUpdateAllowed,
          )
          ? UpdateStatus.forced
          : UpdateStatus.none;
    } catch (error, stackTrace) {
      // Offline, Play unavailable, not a Play build, API exception — all mean
      // "we don't know", which must NOT strand the user. Log and continue.
      AppLogger.instance.warning(
        'In-app update check skipped (Play unavailable or not a Play build)',
        error: error,
        stackTrace: stackTrace,
      );
      return UpdateStatus.none;
    }
  }

  /// Launches Google Play's official Immediate Update flow — a full-screen,
  /// Play-owned UI. Play restarts the app itself on success. Best-effort: a
  /// user cancellation or install failure is swallowed here so the caller can
  /// simply keep the user on the blocking screen and let them retry.
  Future<void> startImmediate() async {
    if (!_supported) return;
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (error, stackTrace) {
      AppLogger.instance.warning(
        'Immediate update flow did not complete',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final inAppUpdateServiceProvider = Provider<InAppUpdateService>(
  (ref) => const InAppUpdateService(),
);
