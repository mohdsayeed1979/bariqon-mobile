import 'package:flutter/material.dart';

/// Sizing presets for [BrandLogo], covering the places it's expected to
/// appear per the Foundation Health Check brief: splash, app branding,
/// a future auth header, future About screen, and general placeholder
/// branding. Each preset is a max width — the logo always scales down to
/// fit via [BoxFit.contain], preserving its aspect ratio, never stretched.
enum BrandLogoSize {
  /// Compact usage — a future auth header, nav branding, dense contexts.
  small(120),

  /// Default usage — general branding placement, About screen.
  medium(220),

  /// Splash screen / hero branding moments.
  large(320);

  const BrandLogoSize(this.maxWidth);

  final double maxWidth;
}

/// The single, reusable rendering of the official Bariqon logo
/// (assets/logos/bariqon_logo.jpeg). Every place the logo appears in the
/// app — splash, branding, and later the auth header / About screen —
/// should use this widget rather than referencing the asset path directly,
/// so sizing/padding/aspect-ratio handling stays consistent and the asset
/// is never duplicated.
///
/// The source file is a wide horizontal lockup (mark + wordmark + tagline)
/// on a white background — [BoxFit.contain] is used deliberately so it's
/// never cropped or stretched into a shape it wasn't designed for.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = BrandLogoSize.medium,
    this.padding = const EdgeInsets.all(16),
  });

  final BrandLogoSize size;
  final EdgeInsets padding;

  static const String _assetPath = 'assets/logos/bariqon_logo.jpeg';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: size.maxWidth),
        child: Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          semanticLabel: 'Bariqon',
        ),
      ),
    );
  }
}
