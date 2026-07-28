import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Session state per the Phase 4 brief: Signed Out (app default), Guest
/// (browsing without an account), Signed In (mock user attached). Screens
/// own their own loading/error UI around each call (same pattern as the
/// Inquiry Details form in Phase 3) — this notifier only ever holds the
/// resulting session, never an in-flight/error status.
class AuthController extends Notifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthSession build() => const SignedOutSession();

  Future<void> login({required String email, required String password}) async {
    final user = await _repository.login(email: email, password: password);
    state = SignedInSession(user);
  }

  Future<void> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  }) async {
    final user = await _repository.register(
      fullName: fullName,
      company: company,
      email: email,
      mobile: mobile,
      country: country,
      password: password,
    );
    state = SignedInSession(user);
  }

  Future<void> sendPasswordReset(String email) {
    return _repository.sendPasswordReset(email);
  }

  Future<void> updateProfile(AppUser updated) async {
    final saved = await _repository.updateProfile(updated);
    state = SignedInSession(saved);
  }

  void continueAsGuest() {
    state = const GuestSession();
  }

  void signOut() {
    state = const SignedOutSession();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);
