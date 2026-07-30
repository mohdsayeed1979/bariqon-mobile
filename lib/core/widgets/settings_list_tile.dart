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
    // Row already reorders its children for RTL automatically, but the
    // chevron *glyph* doesn't — a disclosure indicator pointing "forward"
    // needs to point left in RTL, not stay pointing right just because
    // that's what looks right in LTR. Same pattern already used by
    // CategoryDetailScreen's breadcrumb chevron.
    final disclosureIcon = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
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
            const SizedBox(width: 4),
          ],
          Icon(disclosureIcon),
        ],
      ),
      onTap: onTap,
    );
  }
}
