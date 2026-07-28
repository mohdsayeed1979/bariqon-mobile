import 'package:flutter/material.dart';

/// BHD price display, per docs/DESIGN_SYSTEM.md §8 — two-decimal formatting
/// matching the live site's own "BD 10.00" style
/// (docs/SCREEN_SPECIFICATIONS.md §18). One place to change if the real
/// currency formatting convention is confirmed differently later.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.price, this.style});

  final double price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'BD ${price.toStringAsFixed(2)}',
      style:
          style ??
          theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
