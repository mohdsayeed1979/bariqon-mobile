import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import 'utils/catalog_selectors.dart';
import 'widgets/categories_section.dart';
import 'widgets/hero_banner_section.dart';
import 'widgets/home_footer_section.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/product_section.dart';
import 'widgets/promo_banner_section.dart';
import 'widgets/why_choose_us_section.dart';

/// Home tab root — premium shopping-app layout per the Naqir-inspired
/// redesign: a custom header (logo/greeting/notifications/language)
/// instead of a plain title bar, the search bar moved directly beneath
/// it, then the hero carousel, "Shop by Category", and the product
/// rails. Wired to the real `cms_products` catalog; each product rail
/// derives from [productsProvider] via `catalog_selectors.dart`
/// (Featured/New Arrivals/Best Sellers) rather than each section taking
/// its own mock list — unchanged by this redesign, only the surrounding
/// layout is new.
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
      body: SafeArea(
        child: ResponsiveCenter(
          width: ContentWidth.grid,
          child: Column(
            children: [
              // Pinned above the scroll area — per the redesign brief's
              // header/search requirements, but critically also so the
              // language toggle (and notifications) stay reachable no
              // matter how far the user has scrolled, unlike the
              // previous scoped-to-the-list-item attempt.
              const HomeHeader(),
              const HomeSearchBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ListView(
                      key: const Key('home_scroll_view'),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        const HeroBannerSection(),
                        const SizedBox(height: AppSpacing.lg),
                        const CategoriesSection(),
                        const SizedBox(height: AppSpacing.xl),
                        AsyncValueView(
                          value: productsAsync,
                          onRetry: () => ref.invalidate(productsProvider),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xxxl,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          data: (products) => Column(
                            children: [
                              ProductSection(
                                title: l10n.homeSectionFeaturedProducts,
                                products: featuredProducts(products),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ProductSection(
                                title: l10n.homeSectionNewArrivals,
                                products: newArrivalProducts(products),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              const PromoBannerSection(),
                              const SizedBox(height: AppSpacing.xl),
                              ProductSection(
                                title: l10n.homeSectionBestSellers,
                                products: bestSellerProducts(products),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const WhyChooseUsSection(),
                        const SizedBox(height: AppSpacing.xl),
                        const HomeFooterSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
