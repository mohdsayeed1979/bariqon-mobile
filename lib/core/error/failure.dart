/// App-wide failure taxonomy, per docs/ARCHITECTURE.md §14 and
/// docs/IMPLEMENTATION_ROADMAP.md §12.
///
/// Repositories translate raw exceptions (Supabase's `PostgrestException`,
/// `AuthException`, `StorageException`, connectivity timeouts, etc.) into
/// one of these via [ExceptionMapper] — presentation code should never see
/// a raw backend exception type, only a [Failure].
///
/// Plain sealed class (no `freezed`) — see the Phase 1 summary for why
/// codegen was deferred; this reads and behaves the same either way.
sealed class Failure {
  const Failure(this.message);

  /// User-legible message. Screens may show this directly or use it to
  /// pick a localized string — kept plain-English here since Phase 1 has
  /// no feature screens yet to wire actual localized copy through.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Connectivity/timeout failures — the request never reached the server,
/// or the server never responded in time.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection.']);
}

/// Supabase Auth failures (invalid credentials, expired session, etc.).
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Requested resource doesn't exist (e.g. a product id that's been deleted).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

/// Client-side input failed validation before ever reaching the backend.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// The backend rejected the request (RLS denial, constraint violation,
/// 5xx, etc.) — distinct from [NetworkFailure], which never got a response
/// at all.
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Anything that doesn't map cleanly to the above — logged with full detail
/// via AppLogger at the point of mapping, shown to the user as a generic
/// message.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
