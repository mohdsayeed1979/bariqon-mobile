import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env_config.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/local_preferences_service.dart';
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
        logger.info('Supabase initialized.');
      }

      // Loaded once, up front — SharedPreferences caches everything in
      // memory after this, so every read through LocalPreferencesService
      // afterward is synchronous (no FutureProvider/AsyncValue needed for
      // theme/App Lock/remember-me state).
      final sharedPreferences = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const BariqonApp(),
        ),
      );
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
