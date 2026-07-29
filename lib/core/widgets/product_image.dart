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

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => _placeholder(),
      errorWidget: (context, _, _) => _placeholder(),
    );
  }
}
