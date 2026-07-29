import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';

/// Category tile for the Categories screen's responsive grid, per the
/// Phase 2C brief — icon placeholder, title, short description, and a
/// subtle hover lift (desktop/web pointers) on top of the standard
/// [InkWell] press ripple. Distinct from [CategoryCard] (the compact
/// icon-only tile used in Home's category rail) — this one carries a
/// description and is sized for a grid, not a horizontal rail.
///
/// Sizes itself to its content (`mainAxisSize.min`, `maxLines` on every
/// text row) so it's safe inside a [Wrap] with no forced cell height —
/// the exact pattern that fixed the Phase 2B overflow.
class CategoryGridCard extends StatefulWidget {
  const CategoryGridCard({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.onTap,
  });

  final String title;

  /// Null/empty when the backend has no description for this category —
  /// the description row is omitted entirely rather than showing
  /// placeholder copy.
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<CategoryGridCard> createState() => _CategoryGridCardState();
}

class _CategoryGridCardState extends State<CategoryGridCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 108,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.12),
                AppColors.gold.withValues(alpha: 0.20),
              ],
            ),
          ),
          child: Icon(widget.icon, size: 42, color: theme.colorScheme.primary),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              if (widget.description != null && widget.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return SizedBox(
      width: 200,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedScale(
          scale: _hovering ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedPhysicalModel(
            duration: const Duration(milliseconds: 150),
            color: theme.colorScheme.surface,
            shadowColor: Colors.black,
            elevation: _hovering ? 6 : 1,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: widget.onTap, child: card),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
