import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/register_result.dart';

/// Local-only mock: no network, no validation of credentials against any
/// real account (any email/password combination "succeeds"), just a
/// simulated delay so loading states feel real. Per the Phase 4 brief,
/// this is a placeholder for the eventual Supabase Auth-backed repository.
class MockAuthRepository implements AuthRepository {
  static const _simulatedDelay = Duration(milliseconds: 600);

  @override
  Future<AppUser> login({required String email, required String password}) async {
    await Future.delayed(_simulatedDelay);
    return AppUser(
      id: 'mock-user-${email.hashCode}',
      fullName: email.split('@').first,
      email: email,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<RegisterResult> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  }) async {
    await Future.delayed(_simulatedDelay);
    return RegisterResult(
      user: AppUser(
        id: 'mock-user-${email.hashCode}',
        fullName: fullName,
        email: email,
        company: company,
        mobile: mobile,
        country: country,
      ),
      requiresEmailConfirmation: false,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(_simulatedDelay);
  }

  @override
  Future<AppUser> updateProfile(AppUser updated) async {
    await Future.delayed(_simulatedDelay);
    return updated;
  }
}
