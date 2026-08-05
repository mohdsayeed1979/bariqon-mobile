import 'package:flutter/material.dart';

/// A circular profile-photo placeholder (Phase 4 has no real photo upload
/// yet) — reused by the Profile and Edit Profile screens so the avatar
/// treatment stays identical between them.
class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({super.key, this.radius = 40, this.name});

  final double radius;

  /// When supplied, shows the name's first letter instead of the generic
  /// person icon — matches the Naqir-inspired Profile redesign. Null
  /// (e.g. no session yet) falls back to the icon.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: initial != null
          ? Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            )
          : Icon(Icons.person, size: radius, color: theme.colorScheme.primary),
    );
  }
}
