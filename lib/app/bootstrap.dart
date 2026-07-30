import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env_config.dart';
import '../core/logging/app_logger.dart';
import 'app.dart';

/// App entry sequence, per docs/ARCHITECTURE.md §9 and
/// docs/SUPABASE_INTEGRATION.md §1 — the single place Supabase is
/// initialized and the single place uncaught errors are caught, per
/// docs/IMPLEMENTATION_ROADMAP.md §12.
Future<void> bootstrap() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final logger = AppLogger.instance;

      FlutterError.onError = (details) {
        logger.error(
          'Uncaught Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // Flutter's own fallback for a widget that throws mid-build is a
      // bare, unstyled gray box — blank in release builds, since Flutter
      // deliberately hides the technical message there. FlutterError.onError
      // above only logs; it doesn't change what actually renders in place
      // of the failed widget. This is the last-resort UI for that case, so
      // it deliberately doesn't reach for Theme/AppLocalizations — by the
      // time this runs, something's already gone wrong in a way regular
      // error handling didn't catch, and depending on app context that may
      // not even be available here.
      ErrorWidget.builder = (details) {
        return const ColoredBox(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.black45,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Something went wrong displaying this. Please try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        );
      };

      logger.info('Environment: ${EnvConfig.environment.label}');

      if (!EnvConfig.isConfigured) {
        // Fails loudly and specifically rather than letting
        // Supabase.initialize throw an opaque error further down, per
        // EnvConfig's own documentation.
        logger.error(EnvConfig.missingConfigMessage);
      } else {
        await Supabase.initialize(
          url: EnvConfig.supabaseUrl,
          publishableKey: EnvConfig.supabaseAnonKey,
        );
        logger.info(
          'Supabase initialized (${EnvConfig.environment.label}).',
        );
      }

      runApp(const ProviderScope(child: BariqonApp()));
    },
    (error, stackTrace) {
      AppLogger.instance.error(
        'Uncaught zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
