import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import 'utils/catalog_selectors.dart';
import 'widgets/categories_section.dart';
import 'widgets/hero_banner_section.dart';
import 'widgets/home_footer_section.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/product_section.dart';
import 'widgets/promo_banner_section.dart';
import 'widgets/welcome_section.dart';
import 'widgets/why_choose_us_section.dart';

/// Home tab root — the permanent Home screen, per
/// docs/SCREEN_SPECIFICATIONS.md §3, built out in Phase 2B, wired to the
/// real `cms_products` catalog in the Supabase connection pass. Each
/// product rail derives from [productsProvider] via `catalog_selectors.dart`
/// (Featured/New Arrivals/Best Sellers) rather than each section taking
/// its own mock list.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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
    final productsAsync = ref.watch(productsProvider);

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
              AsyncValueView(
                value: productsAsync,
                onRetry: () => ref.invalidate(productsProvider),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                data: (products) => Column(
                  children: [
                    ProductSection(
                      title: l10n.homeSectionFeaturedProducts,
                      products: featuredProducts(products),
                    ),
                    const SizedBox(height: 24),
                    ProductSection(
                      title: l10n.homeSectionNewArrivals,
                      products: newArrivalProducts(products),
                    ),
                    const SizedBox(height: 24),
                    const PromoBannerSection(),
                    const SizedBox(height: 24),
                    ProductSection(
                      title: l10n.homeSectionBestSellers,
                      products: bestSellerProducts(products),
                    ),
                  ],
                ),
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
