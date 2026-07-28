import 'app_user.dart';

/// The app's current auth session, per the Phase 4 brief's three states:
/// Signed Out, Guest, and Signed In. A sealed class (not a bool/enum pair)
/// so the Signed In case can carry its [AppUser] and every consumer is
/// forced to handle all three explicitly (e.g. Profile's branching UI)
/// rather than juggling separate `isGuest`/`user` fields that could drift
/// out of sync.
sealed class AuthSession {
  const AuthSession();
}

class SignedOutSession extends AuthSession {
  const SignedOutSession();
}

class GuestSession extends AuthSession {
  const GuestSession();
}

class SignedInSession extends AuthSession {
  const SignedInSession(this.user);

  final AppUser user;
}
