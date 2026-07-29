import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Compact +/- quantity control, per the Phase 3 brief's "update
/// quantities" requirement — used on Inquiry Cart line items today,
/// generic enough to reuse anywhere a bounded integer needs stepping.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 1,
    this.maxQuantity,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int minQuantity;
  final int? maxQuantity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDecrease = quantity > minQuantity;
    final canIncrease = maxQuantity == null || quantity < maxQuantity!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: l10n.quantityDecreaseTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: canDecrease ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: l10n.quantityIncreaseTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: canIncrease ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}
