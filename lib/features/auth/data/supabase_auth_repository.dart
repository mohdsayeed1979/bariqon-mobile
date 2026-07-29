import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/auth_exceptions.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';

/// Real Supabase Auth-backed [AuthRepository]. Replaces the Phase 4 mock
/// — same interface, so no screen needed to change to pick this up.
///
/// `profiles` column shape isn't documented anywhere in this repo (see
/// the Supabase connection pass notes), so this repository never assumes
/// specific columns exist beyond `id` — it reads whatever's there
/// (`full_name`/`company`/`mobile`/`country`/`avatar_url`, if present) as
/// a best-effort enrichment on top of Supabase Auth's own user metadata,
/// which is always available regardless of what (if anything) `profiles`
/// contains. A `profiles` read/write failure never fails sign-in/sign-up
/// itself.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : _mapUserMetadataOnly(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user == null ? null : _mapUserMetadataOnly(user);
    });
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Sign-in failed.');
      }
      return _buildUser(user);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
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
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'company': company,
          'mobile': mobile,
          'country': country,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Registration failed.');
      }
      if (response.session == null) {
        // Production has `mailer_autoconfirm: false` — signUp succeeds but
        // returns no session until the user confirms via the email link.
        throw EmailConfirmationRequiredException(email);
      }
      return _buildUser(user);
    } on EmailConfirmationRequiredException {
      rethrow;
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
      final currentEmail = _client.auth.currentUser?.email;
      final response = await _client.auth.updateUser(
        UserAttributes(
          // Only included when it actually changed — Supabase sends a
          // confirm-the-new-address email as soon as this is non-null, so
          // re-submitting the same email on every profile save must not
          // trigger that.
          email: (updated.email.isNotEmpty && updated.email != currentEmail)
              ? updated.email
              : null,
          data: {
            'full_name': updated.fullName,
            'company': updated.company,
            'mobile': updated.mobile,
            'country': updated.country,
          },
        ),
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Profile update failed.');
      }

      try {
        await _client.from(SupabaseTables.profiles).upsert({
          'id': user.id,
          'full_name': updated.fullName,
          'company': updated.company,
          'mobile': updated.mobile,
          'country': updated.country,
        });
      } catch (_) {
        // Best-effort mirror — an unconfirmed/unknown `profiles` schema
        // (or an RLS policy that only allows reads) must not fail the
        // update; Auth's own metadata (just written above) is already the
        // source of truth this app reads back.
      }

      return _buildUser(user);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  AppUser _mapUserMetadataOnly(User user) {
    final metadata = user.userMetadata ?? const {};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: (metadata['full_name'] as String?) ?? '',
      company: (metadata['company'] as String?) ?? '',
      mobile: (metadata['mobile'] as String?) ?? '',
      country: (metadata['country'] as String?) ?? '',
      avatarUrl: metadata['avatar_url'] as String?,
    );
  }

  Future<AppUser> _buildUser(User user) async {
    var appUser = _mapUserMetadataOnly(user);

    try {
      final row = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        appUser = AppUser(
          id: appUser.id,
          email: appUser.email,
          fullName: _stringOrFallback(row['full_name'], appUser.fullName),
          company: _stringOrFallback(row['company'], appUser.company),
          mobile: _stringOrFallback(row['mobile'], appUser.mobile),
          country: _stringOrFallback(row['country'], appUser.country),
          avatarUrl: (row['avatar_url'] as String?) ?? appUser.avatarUrl,
        );
      }
    } catch (_) {
      // profiles enrichment is best-effort — the metadata-only AppUser
      // above is already valid and complete.
    }

    return appUser;
  }

  String _stringOrFallback(Object? value, String fallback) {
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }
}
