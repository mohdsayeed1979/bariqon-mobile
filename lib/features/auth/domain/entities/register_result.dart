import 'package:flutter/foundation.dart';

import 'app_user.dart';

/// Outcome of a real registration attempt. Supabase Auth projects can
/// require the new user to click an email confirmation link before a
/// session exists — [requiresEmailConfirmation] tells the caller whether
/// [user] is actually signed in yet or just created and pending
/// verification, so the UI can show the right screen instead of assuming
/// registration always means "signed in immediately" (it doesn't, when
/// email confirmation is on). Always `false` for [MockAuthRepository],
/// which has no such concept.
@immutable
class RegisterResult {
  const RegisterResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AppUser user;
  final bool requiresEmailConfirmation;
}
