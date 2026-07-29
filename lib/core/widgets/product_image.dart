import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a product's real photo (Supabase Storage `media` bucket, always
/// a full public URL already) with disk+memory caching, falling back to
/// the existing icon-on-gradient placeholder while it loads, on error, or
/// when [imageUrl] is null/empty — same treatment [ProductCard] and
/// [ProductDetailScreen] used for the mock-only placeholder, so this is a
/// drop-in replacement rather than a new visual language.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.icon,
    required this.placeholderColor,
    this.iconSize = 48,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final IconData icon;
  final Color placeholderColor;
  final double iconSize;
  final BoxFit fit;

  Widget _placeholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          placeholderColor.withValues(alpha: 0.85),
          placeholderColor.withValues(alpha: 0.55),
        ],
      ),
    ),
    child: Icon(icon, size: iconSize, color: Colors.white),
  );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder();

    // Decodes (and caches) the bitmap at the size it's actually displayed
    // at, not the source photo's full resolution — Supabase Storage
    // product photos can be well over 1000px on a side, which uncapped
    // would eat several MB of decoded memory *per card* in a 200+ product
    // grid. LayoutBuilder gives the real render size for whatever context
    // this is used in (card thumbnail, product gallery, ...) so this
    // adapts automatically instead of needing per-call-site tuning.
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null;
        final cacheHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight * dpr).round()
            : null;

        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, _) => _placeholder(),
          errorWidget: (context, _, _) => _placeholder(),
        );
      },
    );
  }
}
