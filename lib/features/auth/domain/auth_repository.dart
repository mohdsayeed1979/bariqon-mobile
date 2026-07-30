import 'entities/app_user.dart';
import 'entities/register_result.dart';

/// The stable contract [AuthController] depends on. As of Phase 7,
/// [SupabaseAuthRepository] backs every method for real: `login`/`logout`/
/// `restoreSession` (since Phase 5B), and now `register` (real
/// `auth.signUp`), `sendPasswordReset` (real `resetPasswordForEmail`), and
/// `updateProfile` (real Auth + `profiles` table write) — see
/// [SupabaseAuthRepository]'s doc comment for exactly what each writes and
/// the schema limits that shape it.
abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<void> logout();

  /// Resolves the current signed-in user from an already-persisted session
  /// (e.g. Supabase's own local session storage), or null if there isn't
  /// one — backs [AuthController]'s startup session restore. The mock
  /// repository never has a persisted session, so it always returns null.
  Future<AppUser?> restoreSession();

  Future<RegisterResult> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<AppUser> updateProfile(AppUser updated);
}
