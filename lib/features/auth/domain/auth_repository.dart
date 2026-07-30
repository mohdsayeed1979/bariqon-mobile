import 'entities/app_user.dart';

/// The stable contract [AuthController] depends on — real sign-in/sign-up/
/// password reset is backed by [SupabaseAuthRepository][supabase_auth_repository.dart]
/// today; a test-only [MockAuthRepository][mock_auth_repository.dart] fixture
/// implements the same contract without touching the controller or any
/// screen.
abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<AppUser> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<AppUser> updateProfile(AppUser updated);

  Future<void> signOut();

  /// The currently signed-in user, if any — used to restore session state
  /// on app start (e.g. after a cold start with a persisted Supabase
  /// session).
  AppUser? get currentUser;

  /// Emits whenever the backend's own notion of the signed-in user changes
  /// out from under the app — a token refresh, an out-of-band sign-out, a
  /// session expiring. `null` means signed out. [AuthController] listens
  /// to this instead of reaching into Supabase directly, so it stays
  /// backend-agnostic like the rest of this repository's contract.
  Stream<AppUser?> get authStateChanges;
}
