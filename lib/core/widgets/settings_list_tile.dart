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
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
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
          // no onTap shouldn't imply it does something. When shown, it
          // points the way the row's disclosure actually reads for the
          // current text direction.
          if (onTap != null)
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
