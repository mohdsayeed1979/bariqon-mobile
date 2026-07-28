import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auto_carousel.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Home screen hero banner — auto-sliding carousel per the Phase 2B brief.
/// Slides are gradient brand-toned cards with a headline, not real
/// photography (none exists yet — see AutoCarousel's own doc comment).
///
/// Visual/behavioral implementation is intentionally unchanged from the
/// first Phase 2B pass, per your "keep the current implementation"
/// instruction — the only addition is [_HeroSlide.imageUrl], reserved for
/// when a slide's picture comes from Supabase Storage (Phase 3+). It's
/// always null today, so nothing renders differently yet; no network call
/// is made, no backend is touched.
class HeroBannerSection extends StatelessWidget {
  const HeroBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      (
        title: l10n.homeHeroSlide1Title,
        subtitle: l10n.homeHeroSlide1Subtitle,
        icon: Icons.card_giftcard_outlined,
        colors: [AppColors.primary, const Color(0xFF1B5A44)],
        imageUrl: null as String?,
      ),
      (
        title: l10n.homeHeroSlide2Title,
        subtitle: l10n.homeHeroSlide2Subtitle,
        icon: Icons.hotel_outlined,
        colors: [AppColors.gold, AppColors.goldLight],
        imageUrl: null as String?,
      ),
      (
        title: l10n.homeHeroSlide3Title,
        subtitle: l10n.homeHeroSlide3Subtitle,
        icon: Icons.auto_awesome_outlined,
        colors: [const Color(0xFF0F3D2E), AppColors.gold],
        imageUrl: null as String?,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AutoCarousel(
        itemCount: slides.length,
        height: 190,
        itemBuilder: (context, index) {
          final slide = slides[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: slide.colors,
                  ),
                  // Reserved for Phase 3+: once a slide carries a real
                  // Supabase Storage URL, its photo renders under the same
                  // gradient (kept as a legibility scrim for the text
                  // above it) instead of the icon watermark below.
                  image: slide.imageUrl == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(slide.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                ),
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        slide.icon,
                        size: 110,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
