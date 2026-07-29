/// Thrown by [AuthRepository.register] when Supabase Auth requires the
/// user to confirm their email before a session exists (the production
/// project has `mailer_autoconfirm: false`) — a distinct, expected outcome
/// rather than a failure, so [RegistrationScreen] can show "check your
/// email" instead of treating it as an error.
class EmailConfirmationRequiredException implements Exception {
  const EmailConfirmationRequiredException(this.email);

  final String email;
}
