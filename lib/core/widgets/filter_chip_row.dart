import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// Single-select horizontal filter chip row, per docs/IMPLEMENTATION_ROADMAP.md
/// §16 and the Phase 2C brief. Purely local UI state — [onSelected] just
/// reports which index is chosen; whatever it filters (a local mock list
/// today) is the caller's concern, not this widget's.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            ChoiceChip(
              label: Text(labels[i]),
              labelStyle: labelStyle,
              selected: selectedIndex == i,
              onSelected: (_) => onSelected(i),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }
}
