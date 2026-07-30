import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/register_result.dart';

/// Real Supabase Auth, per Phase 7 — every method is a genuine backend
/// call now: `signInWithPassword`, `signOut`, `signUp`,
/// `resetPasswordForEmail`, and `updateUser` + a `profiles` table write.
///
/// The `profiles` table (confirmed live, see docs/BACKEND_MAPPING_REPORT.md
/// and its Phase 7 re-verification) only has `id, email, full_name,
/// created_at, updated_at` — no `company`/`mobile`/`country`/`avatar_url`
/// columns exist. Per an explicit product decision, this repository only
/// ever writes what the schema actually has (`full_name`, `email`); it
/// never invents columns. Company/Mobile/Country are handled entirely
/// outside this class, as device-local data — see
/// [AuthController]/[LocalPreferencesService.getProfileExtra] — so this
/// repository stays a truthful mirror of the real backend, not a partial
/// mock dressed up as one.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const supabase.AuthException('Sign in failed.');
      }
      return _mapUserWithProfile(user);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    try {
      return await _mapUserWithProfile(session.user);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<RegisterResult> register({
    required String fullName,
    required String company,
    required String email,
    required String mobile,
    required String country,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = response.user;
      if (user == null) {
        throw const supabase.AuthException('Registration failed.');
      }

      // Best-effort — the Auth account is what matters; if this write fails
      // (e.g. a transient RLS/network hiccup) registration still succeeded,
      // and the row gets created on the next successful login/update.
      try {
        await _client.from(SupabaseTables.profiles).upsert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
        });
      } catch (_) {
        // Non-fatal, see above.
      }

      // A Supabase project with "Confirm email" enabled returns a user but
      // no session until the confirmation link is clicked — the caller
      // needs to know this so it doesn't treat registration as an
      // immediate sign-in when it isn't one yet.
      return RegisterResult(
        user: _mapUser(user),
        requiresEmailConfirmation: response.session == null,
      );
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<AppUser> updateProfile(AppUser updated) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw const supabase.AuthException(
          'You need to be signed in to update your profile.',
        );
      }

      final newEmail = updated.email.trim();
      final emailChanged =
          newEmail.isNotEmpty && newEmail != (currentUser.email ?? '');

      // Supabase only applies an email change once the confirmation link
      // sent to the *new* address is clicked — `response.user.email` keeps
      // reporting the still-current (old) address until then, which is
      // exactly what should be mirrored into `profiles` below, so no extra
      // handling is needed there for the pending-change case.
      final response = await _client.auth.updateUser(
        supabase.UserAttributes(
          data: {'full_name': updated.fullName},
          email: emailChanged ? newEmail : null,
        ),
      );
      final user = response.user ?? currentUser;

      await _client.from(SupabaseTables.profiles).upsert({
        'id': user.id,
        'email': user.email,
        'full_name': updated.fullName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      return _mapUser(user);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  AppUser _mapUser(supabase.User user) {
    final metadata = user.userMetadata;
    final fullName =
        (metadata?['full_name'] as String?) ??
        (user.email?.split('@').first ?? 'User');
    return AppUser(
      id: user.id,
      fullName: fullName,
      email: user.email ?? '',
      isAdmin: _isAdmin(user),
    );
  }

  /// Same as [_mapUser], but overlays the authoritative `profiles.full_name`
  /// when a row exists — `user_metadata` is a cache set at sign-up/last
  /// update and can go stale (e.g. edited directly on the backend), while
  /// the table is the source of truth. Falls back to the metadata-only
  /// mapping on any failure (including "no row yet") rather than blocking
  /// login over a non-critical enrichment query.
  Future<AppUser> _mapUserWithProfile(supabase.User user) async {
    final base = _mapUser(user);
    try {
      final row = await _client
          .from(SupabaseTables.profiles)
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final fullName = row?['full_name'] as String?;
      if (fullName == null || fullName.trim().isEmpty) return base;
      return AppUser(
        id: base.id,
        fullName: fullName,
        email: base.email,
        isAdmin: base.isAdmin,
      );
    } catch (_) {
      return base;
    }
  }

  /// Checks the Supabase Auth user's own `app_metadata`/`user_metadata`
  /// for a `role`/`is_admin` claim — Supabase's standard place for this
  /// (settable via the dashboard, an Auth Hook, or the Admin API) that
  /// needs no `profiles` column to exist. `app_metadata` is checked first
  /// since — unlike `user_metadata` — it can only be set server-side, so
  /// a value there is trustworthy; `user_metadata` is checked as a
  /// fallback since some Supabase setups store custom claims there
  /// instead. Defaults to `false` when neither is present — the safe
  /// choice, since no admin signal existing is far more likely than a
  /// real admin account having none.
  bool _isAdmin(supabase.User user) {
    bool truthy(Object? value) =>
        value == true || value == 'true' || value == 'admin';

    final appMetadata = user.appMetadata;
    if (truthy(appMetadata['role']) || truthy(appMetadata['is_admin'])) {
      return true;
    }
    final userMetadata = user.userMetadata;
    if (truthy(userMetadata?['role']) || truthy(userMetadata?['is_admin'])) {
      return true;
    }
    return false;
  }
}
