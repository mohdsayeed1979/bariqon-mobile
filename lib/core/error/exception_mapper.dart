import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Maps exceptions thrown by Supabase (or plain Dart networking) into the
/// app's [Failure] taxonomy — the one place this translation happens, per
/// docs/SUPABASE_INTEGRATION.md §8. Repository implementations should wrap
/// their Supabase calls in a try/catch that calls this, not invent their
/// own mapping per repository.
class ExceptionMapper {
  const ExceptionMapper._();

  static Failure map(Object error, [StackTrace? stackTrace]) {
    return switch (error) {
      AuthException e => AuthFailure(e.message),
      PostgrestException e => _mapPostgrestException(e),
      StorageException e => ServerFailure(e.message),
      SocketException _ => const NetworkFailure(),
      TimeoutException _ => const NetworkFailure(),
      Failure f => f, // already mapped upstream — pass through unchanged
      _ => const UnknownFailure(),
    };
  }

  static Failure _mapPostgrestException(PostgrestException e) {
    // Postgres error code '42501' is insufficient_privilege — the shape an
    // RLS-denied operation surfaces as. Called out explicitly per the
    // architecture doc's requirement that an RLS denial reads as a
    // distinct failure, not a generic one.
    if (e.code == '42501') {
      return ServerFailure(
        'You don\'t have permission to do that.',
      );
    }
    if (e.code == 'PGRST116') {
      return const NotFoundFailure();
    }
    return ServerFailure(e.message);
  }
}
