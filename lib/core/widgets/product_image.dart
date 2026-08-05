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
    this.memCacheWidth,
  });

  final String? imageUrl;
  final IconData icon;
  final Color placeholderColor;
  final double iconSize;
  final BoxFit fit;

  /// Decodes the source image down to roughly this physical-pixel width
  /// instead of its full resolution — a real performance/memory win for
  /// small tiles (product cards) fed a source photo that may be much
  /// larger than what's ever displayed. Left null (full resolution) for
  /// callers that show the image at a large size, e.g. Product Detail.
  final int? memCacheWidth;

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

    // An explicit memCacheWidth from the caller is honored as-is (e.g. a
    // fixed thumbnail size). Callers that don't specify one get a size
    // computed from the actual render constraints instead of the source
    // photo's full resolution — Supabase Storage product photos can be
    // well over 1000px on a side, which uncapped would eat several MB of
    // decoded memory *per card* in a 200+ product grid.
    if (memCacheWidth != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: memCacheWidth,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, _) => _placeholder(),
        errorWidget: (context, _, _) => _placeholder(),
      );
    }

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
