/// A signed-in (or registering) user's profile fields, per the Phase 4
/// brief's Registration/Profile field set. Local-mock only for
/// registration/profile data today — this shape is what a future
/// Supabase-backed [AuthRepository] would populate from the real
/// `profiles` table without any UI change.
///
/// [isAdmin] is real, not mock: it's derived from the signed-in Supabase
/// Auth user's `app_metadata`/`user_metadata` `role`/`is_admin` claim (see
/// [SupabaseAuthRepository._mapUser]) — the `profiles` table has no role
/// column (confirmed by schema probe, see docs/BACKEND_MAPPING_REPORT.md),
/// so this is the one mechanism that can actually reflect a real admin
/// account today, and needs no app change if/when a `profiles.role`
/// column is added later (the mapping only needs to change in one place).
/// Always `false` for the mock repository/guest/registration.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.company = '',
    this.mobile = '',
    this.country = '',
    this.avatarUrl,
    this.isAdmin = false,
  });

  final String id;
  final String fullName;
  final String email;
  final String company;
  final String mobile;
  final String country;
  final String? avatarUrl;
  final bool isAdmin;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? company,
    String? mobile,
    String? country,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      company: company ?? this.company,
      mobile: mobile ?? this.mobile,
      country: country ?? this.country,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin,
    );
  }
}
