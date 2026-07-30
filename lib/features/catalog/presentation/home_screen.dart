import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import 'widgets/async_product_rail.dart';
import 'widgets/categories_section.dart';
import 'widgets/hero_banner_section.dart';
import 'widgets/home_footer_section.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/promo_banner_section.dart';
import 'widgets/welcome_section.dart';
import 'widgets/why_choose_us_section.dart';

/// Home tab root — the permanent Home screen, per
/// docs/SCREEN_SPECIFICATIONS.md §3. Featured/New Arrivals/Best Sellers
/// and Categories are backed by real repositories as of Phase 5 (Supabase
/// when configured, mock otherwise — see catalog_providers.dart); this
/// composition itself didn't need to change, since each section already
/// took its data as a parameter/provider rather than reaching into mock
/// data directly.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.entranceFade,
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.03),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final bestSellersAsync = ref.watch(bestSellersProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.navHome),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            key: const Key('home_scroll_view'),
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const HeroBannerSection(),
              const WelcomeSection(),
              const HomeSearchBar(),
              const SizedBox(height: 8),
              const CategoriesSection(),
              const SizedBox(height: 24),
              AsyncProductRail(
                title: l10n.homeSectionFeaturedProducts,
                productsAsync: featuredAsync,
              ),
              const SizedBox(height: 24),
              AsyncProductRail(
                title: l10n.homeSectionNewArrivals,
                productsAsync: newArrivalsAsync,
              ),
              const SizedBox(height: 24),
              const PromoBannerSection(),
              const SizedBox(height: 24),
              AsyncProductRail(
                title: l10n.homeSectionBestSellers,
                productsAsync: bestSellersAsync,
              ),
              const SizedBox(height: 24),
              const WhyChooseUsSection(),
              const SizedBox(height: 24),
              const HomeFooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}
