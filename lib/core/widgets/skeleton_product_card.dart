import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'skeleton_box.dart';

/// Loading placeholder matching [ProductCard]'s exact proportions, per
/// docs/IMPLEMENTATION_ROADMAP.md §14 and the Phase 2C brief's "skeleton
/// cards, smooth shimmer animation" requirement — built from the shared
/// [SkeletonBox] shimmer primitive rather than a one-off implementation.
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  // Matches ProductCard's dimensions exactly (see its `_width`/
  // `_imageAspectRatio`) so the loading → loaded transition doesn't jump.
  static const double _width = 156;
  static const double _imageAspectRatio = 1.4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: _imageAspectRatio,
              child: const SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 100, height: 14),
                  const SizedBox(height: 4),
                  const SkeletonBox(width: double.infinity, height: 10),
                  const SizedBox(height: 4),
                  const SkeletonBox(width: 80, height: 10),
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
