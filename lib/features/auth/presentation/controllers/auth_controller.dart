import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/storage/local_preferences_service.dart';
import '../../data/mock_auth_repository.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';

/// Same env-conditional selection as the catalog repositories
/// (catalog_providers.dart) — unconfigured (every `flutter test` run, or
/// any dev run without `--dart-define` credentials) falls back to the
/// mock repository; a configured build talks to real Supabase Auth for
/// login/logout/session-restore.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!EnvConfig.isConfigured) return MockAuthRepository();
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Session state per the Phase 4 brief: Signed Out (app default), Guest
/// (browsing without an account), Signed In. Screens own their own
/// loading/error UI around each call (same pattern as the Inquiry Details
/// form in Phase 3) — this notifier only ever holds the resulting
/// session, never an in-flight/error status.
///
/// Phase 5B adds real session restore: when Supabase is configured,
/// [build] fires an async check of Supabase's own already-persisted
/// session (fast — `currentSession` is an in-memory getter, no network
/// call) and updates [state] if one exists and Remember Me was on for it.
/// This mirrors the "sync build() returns a safe default, then updates
/// state once async work resolves" shape already used for App Lock's
/// `hasPin` check — no `AsyncNotifier` conversion needed, so nothing that
/// watches this provider (Profile, the app shell) had to change.
class AuthController extends Notifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  LocalPreferencesService get _prefs => ref.read(localPreferencesServiceProvider);

  @override
  AuthSession build() {
    if (EnvConfig.isConfigured) {
      _restoreSession();
    }
    return const SignedOutSession();
  }

  Future<void> _restoreSession() async {
    if (!_prefs.getRememberMe()) {
      // Remember Me was off for whatever session Supabase persisted —
      // honor that by clearing it now instead of silently restoring a
      // session the user asked not to be kept.
      await _repository.logout();
      return;
    }
    final user = await _repository.restoreSession();
    if (user != null) state = SignedInSession(_withLocalExtras(user));
  }

  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final user = await _repository.login(email: email, password: password);
    await _prefs.setRememberMe(rememberMe);
    state = SignedInSession(_withLocalExtras(user));
  }

  /// Returns `true` if registration also signed the user in immediately,
  /// `false` if Supabase requires email confirmation first (no session yet
  /// — [state] is left as-is, still Signed Out) — see [RegisterResult].
  /// Company/Mobile/Country are saved locally regardless of which case
  /// this is, so they're already there once the user does sign in.
  Future<bool> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  }) async {
    final result = await _repository.register(
      fullName: fullName,
      company: company,
      email: email,
      mobile: mobile,
      country: country,
      password: password,
    );
    await _prefs.setProfileExtra(
      result.user.id,
      company: company,
      mobile: mobile,
      country: country,
    );
    if (result.requiresEmailConfirmation) return false;
    state = SignedInSession(_withLocalExtras(result.user));
    return true;
  }

  Future<void> sendPasswordReset(String email) {
    return _repository.sendPasswordReset(email);
  }

  Future<void> updateProfile(AppUser updated) async {
    final saved = await _repository.updateProfile(updated);
    await _prefs.setProfileExtra(
      saved.id,
      company: updated.company,
      mobile: updated.mobile,
      country: updated.country,
    );
    state = SignedInSession(_withLocalExtras(saved));
  }

  /// Overlays device-local Company/Mobile/Country onto a user built from
  /// the real backend — see [LocalPreferencesService.getProfileExtra] for
  /// why these three fields live here instead of in `profiles`.
  AppUser _withLocalExtras(AppUser user) {
    final extra = _prefs.getProfileExtra(user.id);
    if (extra.isEmpty) return user;
    return user.copyWith(
      company: extra['company'],
      mobile: extra['mobile'],
      country: extra['country'],
    );
  }

  void continueAsGuest() {
    state = const GuestSession();
  }

  Future<void> signOut() async {
    await _repository.logout();
    state = const SignedOutSession();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);
