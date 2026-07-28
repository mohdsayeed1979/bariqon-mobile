import 'package:flutter/material.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/mock_catalog_data.dart';
import 'widgets/categories_section.dart';
import 'widgets/hero_banner_section.dart';
import 'widgets/home_footer_section.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/product_section.dart';
import 'widgets/promo_banner_section.dart';
import 'widgets/welcome_section.dart';
import 'widgets/why_choose_us_section.dart';

/// Home tab root — the permanent Home screen, per
/// docs/SCREEN_SPECIFICATIONS.md §3, built out in Phase 2B. UI only: every
/// list below is local mock data (see mock_catalog_data.dart); no
/// Supabase, no repository, no cart/inquiry logic. Replacing the mock
/// data source with real repository calls in a later phase shouldn't
/// require touching this composition — each section already takes data
/// as a parameter.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
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
              ProductSection(
                title: l10n.homeSectionFeaturedProducts,
                products: MockCatalogData.featured,
              ),
              const SizedBox(height: 24),
              ProductSection(
                title: l10n.homeSectionNewArrivals,
                products: MockCatalogData.newArrivals,
              ),
              const SizedBox(height: 24),
              const PromoBannerSection(),
              const SizedBox(height: 24),
              ProductSection(
                title: l10n.homeSectionBestSellers,
                products: MockCatalogData.bestSellers,
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
