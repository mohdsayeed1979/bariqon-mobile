/// A signed-in (or registering) user's profile fields, per the Phase 4
/// brief's Registration/Profile field set. Local-mock only today — this
/// shape is what a future Supabase-backed [AuthRepository] would populate
/// from the real `users`/`profiles` table without any UI change.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.company = '',
    this.mobile = '',
    this.country = '',
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String company;
  final String mobile;
  final String country;
  final String? avatarUrl;

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
    );
  }
}
