import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'skeleton_box.dart';

/// Loading placeholder matching [ProductCard]'s exact proportions, per
/// docs/IMPLEMENTATION_ROADMAP.md §14 and the Phase 2C brief's "skeleton
/// cards, smooth shimmer animation" requirement — built from the shared
/// [SkeletonBox] shimmer primitive rather than a one-off implementation.
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: double.infinity, height: 120, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 110, height: 14),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: double.infinity, height: 10),
                  const SizedBox(height: 4),
                  const SkeletonBox(width: 90, height: 10),
                  const SizedBox(height: AppSpacing.xs),
                  const SkeletonBox(width: 50, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonBox(
                    width: double.infinity,
                    height: 34,
                    borderRadius: AppRadius.md,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
