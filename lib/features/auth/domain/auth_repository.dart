import 'entities/app_user.dart';

/// The stable contract [AuthController] depends on — a future
/// Supabase-backed implementation (real sign-in/sign-up/password reset)
/// can replace [MockAuthRepository] without changing the controller or
/// any screen, mirroring the pattern established for the Inquiry Cart in
/// Phase 3.
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
}
