import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// Shimmering placeholder box, per docs/DESIGN_SYSTEM.md §6/§8 — the base
/// primitive behind screen-specific skeletons (e.g. a future
/// `SkeletonProductCard` composes several of these). Deliberately dependency
/// -free (no shimmer package) — a simple opacity pulse is enough for now and
/// avoids pulling in another package for a purely cosmetic effect.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface.withValues(
      alpha: 0.06,
    );
    final highlightColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(baseColor, highlightColor, _controller.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
