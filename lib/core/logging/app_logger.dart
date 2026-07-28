import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Riverpod access point for [AppLogger]. Hand-written (no codegen) — see
/// docs/PACKAGE_SELECTION.md deviation note in the Phase 1 summary for why.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.instance);

/// Structured, leveled logging wrapper, per docs/ARCHITECTURE.md §15.
///
/// Nothing else in the app should import `package:logger` directly — this
/// is the single access point, so log verbosity/format/destination can
/// change in one place (e.g. wiring in Crashlytics later) without touching
/// call sites.
class AppLogger {
  AppLogger._(this._logger);

  final Logger _logger;

  static final AppLogger instance = AppLogger._(
    Logger(
      // Verbose in debug builds, minimal noise in release, per the
      // architecture doc's logging strategy.
      level: kDebugMode ? Level.debug : Level.warning,
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0,
        errorMethodCount: 5,
        colors: kDebugMode,
        printEmojis: kDebugMode,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    ),
  );

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// For unrecoverable/unexpected errors. Intentionally the hook point for
  /// wiring in crash reporting (e.g. Crashlytics, per the architecture
  /// doc's logging strategy) once that's approved and added — not done here.
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
