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
      width: 228,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: double.infinity, height: 198, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 140, height: 18),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: 120, height: 12),
                  const SizedBox(height: AppSpacing.sm),
                  const SkeletonBox(width: 60, height: 18),
                  const SizedBox(height: AppSpacing.md),
                  SkeletonBox(
                    width: double.infinity,
                    height: 42,
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
