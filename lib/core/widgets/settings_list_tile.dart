import 'package:flutter/material.dart';

/// A single Settings row (icon + label + optional trailing value/chevron),
/// per the Phase 4 brief's Settings screen. Extracted since the same shape
/// repeats for every one of Settings' seven rows.
class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailingText,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;

  /// Overrides the icon/label color — e.g. the destructive red on a
  /// "Log out" row. Null (the common case) uses the theme's normal
  /// primary/on-surface colors.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: color ?? theme.colorScheme.primary),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Flexible(
              child: Text(
                trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onTap != null) const SizedBox(width: 4),
          ],
          // Only a real navigation/action row gets the "you can tap this"
          // chevron — an informational-only row (e.g. app version) with
          // no onTap shouldn't imply it does something.
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
