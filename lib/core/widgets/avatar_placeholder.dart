import 'package:flutter/material.dart';

/// A circular profile-photo placeholder (Phase 4 has no real photo upload
/// yet) — reused by the Profile and Edit Profile screens so the avatar
/// treatment stays identical between them.
class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({super.key, this.radius = 40});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: radius,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
