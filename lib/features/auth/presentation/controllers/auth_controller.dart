import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_service.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Session state per the Phase 4 brief: Signed Out (app default), Guest
/// (browsing without an account), Signed In (real Supabase user attached).
/// Screens own their own loading/error UI around each call (same pattern
/// as the Inquiry Details form) — this notifier only ever holds the
/// resulting session, never an in-flight/error status.
///
/// [build] restores whatever session the repository already has (cold
/// start after a previous sign-in — `supabase_flutter` persists sessions
/// locally on its own), then listens to
/// [AuthRepository.authStateChanges] for anything that changes the
/// session out from under the app afterwards (token refresh, an
/// out-of-band sign-out). Goes through the repository rather than
/// Supabase directly, same as every other method here, so this class
/// stays backend-agnostic.
class AuthController extends Notifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthSession build() {
    final subscription = _repository.authStateChanges.listen((user) {
      if (user == null) {
        // Only overwrite an existing Signed In session — a sign-out event
        // while Guest/Signed Out is already the state is a no-op, not a
        // reason to reset an intentional Guest choice.
        if (state is SignedInSession) {
          state = const SignedOutSession();
        }
        return;
      }
      state = SignedInSession(user);
    });
    ref.onDispose(subscription.cancel);

    final currentUser = _repository.currentUser;
    return currentUser == null
        ? const SignedOutSession()
        : SignedInSession(currentUser);
  }

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

  Future<void> signOut() async {
    await _repository.signOut();
    state = const SignedOutSession();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);
