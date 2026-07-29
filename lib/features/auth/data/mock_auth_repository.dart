import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';

/// Local-only, offline-safe [AuthRepository] — no network, no validation
/// of credentials against any real account (any email/password
/// combination "succeeds"), just a simulated delay so loading states feel
/// real. No longer used by the app itself (real sign-in runs through
/// [SupabaseAuthRepository][supabase_auth_repository.dart] since the
/// Supabase connection pass); kept as the fixture `test/widget_test.dart`
/// serves through a `ProviderScope` override so auth flows stay testable
/// without live network access.
class MockAuthRepository implements AuthRepository {
  static const _simulatedDelay = Duration(milliseconds: 600);

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  // Never emits — every state change here happens synchronously through
  // an explicit method call that AuthController already reflects into its
  // own state, so there's nothing external for this to report.
  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> login({required String email, required String password}) async {
    await Future.delayed(_simulatedDelay);
    final user = AppUser(
      id: 'mock-user-${email.hashCode}',
      fullName: email.split('@').first,
      email: email,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  }) async {
    await Future.delayed(_simulatedDelay);
    final user = AppUser(
      id: 'mock-user-${email.hashCode}',
      fullName: fullName,
      email: email,
      company: company,
      mobile: mobile,
      country: country,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(_simulatedDelay);
  }

  @override
  Future<AppUser> updateProfile(AppUser updated) async {
    await Future.delayed(_simulatedDelay);
    _currentUser = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(_simulatedDelay);
    _currentUser = null;
  }
}
