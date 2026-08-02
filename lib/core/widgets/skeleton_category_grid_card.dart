import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'skeleton_box.dart';

/// Loading placeholder matching [CategoryGridCard]'s exact proportions,
/// per the Phase 2C brief's loading-state requirement — built from the
/// shared [SkeletonBox] shimmer primitive.
class SkeletonCategoryGridCard extends StatelessWidget {
  const SkeletonCategoryGridCard({super.key, this.width = 200});

  /// Matches whatever width [CategoryGridCard] is being rendered at, so
  /// the loading state doesn't visibly jump once real data arrives.
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: double.infinity, height: 108, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 100, height: 16),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: 90, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
