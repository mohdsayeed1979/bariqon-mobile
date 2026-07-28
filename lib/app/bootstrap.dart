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
