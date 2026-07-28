import 'package:flutter/material.dart';

/// Material 3 sort selector, per the Phase 2C brief — a thin wrapper
/// around [DropdownMenu] so every screen that needs a "Sort by" control
/// looks the same. Purely local UI state, same as [FilterChipRow]: the
/// caller decides what re-sorting the selection actually triggers.
class SortDropdown<T> extends StatelessWidget {
  const SortDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      initialSelection: value,
      label: Text(label),
      dropdownMenuEntries: entries,
      onSelected: onChanged,
      textStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
