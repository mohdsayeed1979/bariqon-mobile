// Smoke tests: splash → app shell → Home content → tab navigation →
// locale switching, all without touching Supabase — the catalog/auth
// repository providers are overridden below with fixture-backed fakes
// (see `_testOverrides`), so the suite stays deterministic and offline
// even though the app itself now runs on the real Supabase-backed
// repositories.

import 'package:bariqon_app/app/app.dart';
import 'package:bariqon_app/core/config/app_config.dart';
import 'package:bariqon_app/core/storage/local_preferences_service.dart';
import 'package:bariqon_app/core/widgets/quantity_stepper.dart';
import 'package:bariqon_app/features/auth/data/mock_auth_repository.dart';
import 'package:bariqon_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bariqon_app/features/catalog/data/mock_catalog_data.dart';
import 'package:bariqon_app/features/catalog/domain/category_repository.dart';
import 'package:bariqon_app/features/catalog/domain/entities/category.dart';
import 'package:bariqon_app/features/catalog/domain/entities/product.dart';
import 'package:bariqon_app/features/catalog/domain/product_repository.dart';
import 'package:bariqon_app/features/catalog/presentation/controllers/catalog_providers.dart';
import 'package:bariqon_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:bariqon_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> getCategories() async => MockCatalogData.categories;
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts() async => MockCatalogData.allProducts;
}

/// Fresh instances every call — a shared top-level list would let
/// [MockAuthRepository]'s signed-in state leak between test cases.
/// `Override` (the precise return element type) isn't exported by
/// flutter_riverpod's public API, so this can't be spelled explicitly.
// ignore: strict_top_level_inference
_testOverrides() => [
  categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
  productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
  authRepositoryProvider.overrideWithValue(MockAuthRepository()),
];

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(overrides: _testOverrides(), child: const BariqonApp()),
  );
  await tester.pump();
  // Splash fades in (600ms) then holds (700ms) before navigating — see
  // lib/app/splash_screen.dart.
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
}

/// Home is a long scrolling page (default test viewport is 800x600) — this
/// drags the named Home ListView down so below-the-fold sections are
/// actually mounted before a finder looks for them.
Future<void> _scrollHome(WidgetTester tester, double offset) async {
  await tester.drag(
    find.byKey(const Key('home_scroll_view')),
    Offset(0, -offset),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Boots to the Home tab with real Home content after splash', (
    tester,
  ) async {
    await _pumpPastSplash(tester);

    expect(find.text('Home'), findsWidgets); // app bar title + tab label
    expect(find.text('Welcome to Bariqon'), findsOneWidget);

    await _scrollHome(tester, 500);
    expect(find.text('Featured Products'), findsOneWidget);

    await _scrollHome(tester, 1500);
    expect(find.text('Why Choose Bariqon'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs correctly', (tester) async {
    await _pumpPastSplash(tester);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Luxury Gift Boxes'), findsOneWidget);

    await tester.tap(find.text('Inquiry'));
    await tester.pumpAndSettle();
    expect(find.text('Inquiry'), findsWidgets);
    expect(find.text('Your inquiry cart is empty.'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Tapping a category opens its Category Detail screen', (
    tester,
  ) async {
    await _pumpPastSplash(tester);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luxury Gift Boxes').first);
    await tester.pumpAndSettle();

    // App bar title + banner + breadcrumb all show the category name.
    expect(find.text('Luxury Gift Boxes'), findsWidgets);
    expect(find.text('Products'), findsOneWidget);
    // 3 mock products are assigned to this category — see
    // mock_catalog_data.dart.
    expect(find.text('Woven Fabric Gift Box'), findsOneWidget);
  });

  testWidgets('Category Detail search filters the local product list', (
    tester,
  ) async {
    await _pumpPastSplash(tester);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luxury Gift Boxes').first);
    await tester.pumpAndSettle();

    expect(find.text('Woven Fabric Gift Box'), findsOneWidget);
    expect(find.text('Emerald Ribbon Box'), findsOneWidget);

    // The hint is rendered via InputDecoration, not a separate Text widget
    // enterText could target — find the TextField itself instead. `.first`
    // because the sort DropdownMenu also contains a TextField internally;
    // the search field is the one earlier in the tree.
    await tester.enterText(find.byType(TextField).first, 'Emerald');
    await tester.pumpAndSettle();

    expect(find.text('Emerald Ribbon Box'), findsOneWidget);
    expect(find.text('Woven Fabric Gift Box'), findsNothing);
  });

  testWidgets('A category with no mock products shows the empty state', (
    tester,
  ) async {
    await _pumpPastSplash(tester);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('General Trading').first);
    await tester.pumpAndSettle();

    expect(
      find.text(
        "We don't have products listed in this category yet — check back "
        'soon, or explore another category.',
      ),
      findsOneWidget,
    );
    expect(find.text('Browse Other Categories'), findsOneWidget);
  });

  testWidgets(
    'Send Inquiry adds the product to the cart, visible on the Inquiry tab',
    (tester) async {
      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);

      await tester.tap(find.text('Send Inquiry').first);
      await tester.pump(); // start the SnackBar animation
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Added to your inquiry cart'), findsOneWidget);

      // The Inquiry nav destination badges with the cart's item count.
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Inquiry'));
      await tester.pumpAndSettle();

      expect(find.text('Your inquiry cart is empty.'), findsNothing);
      // First Featured Products card, per mock_catalog_data.dart.
      expect(find.text('Woven Fabric Gift Box'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(QuantityStepper),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // Bump the quantity via the stepper.
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(QuantityStepper),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // Remove the item — back to the empty state.
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('Your inquiry cart is empty.'), findsOneWidget);
    },
  );

  testWidgets(
    'Inquiry form validates required fields and completes the mock flow',
    (tester) async {
      // Taller than the suite's default 800x600 — the Cart screen's
      // "Proceed" button sits right at the bottom edge of the default
      // viewport, where hit-testing has proven unreliable in this test
      // environment; more vertical room sidesteps that entirely rather
      // than fighting it.
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);

      await tester.tap(find.text('Send Inquiry').first);
      await tester.pump();
      // SnackBars live in the app-wide Overlay (from MaterialApp's
      // Navigator), not scoped to whichever tab showed them — so it stays
      // on top of every tab's content, absorbing taps aimed at whatever
      // sits beneath it, until it's gone. Waiting out its auto-dismiss
      // timer via pump(duration) proved unreliable in this test
      // environment, so dismiss it directly and deterministically instead.
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .clearSnackBars();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inquiry'));
      await tester.pumpAndSettle();

      final proceedButton = find.widgetWithText(
        OutlinedButton,
        'Submit Quote via Email',
      );
      await tester.ensureVisible(proceedButton);
      await tester.pumpAndSettle();
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();
      expect(find.text('Inquiry Details'), findsOneWidget);

      // Submitting empty surfaces validation errors, no navigation.
      await tester.tap(find.text('Submit Inquiry'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsWidgets);
      expect(find.text('Inquiry Details'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Corporate Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile Number'),
        '+973 3362 1109',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Country'),
        'Bahrain',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Inquiry'));
      await tester.pumpAndSettle();

      expect(find.text('Thank You!'), findsOneWidget);
      expect(find.textContaining('INQ-'), findsOneWidget);

      // Submitting clears the cart.
      await tester.tap(find.text('Continue Browsing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inquiry'));
      await tester.pumpAndSettle();
      expect(find.text('Your inquiry cart is empty.'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping a Home product card opens Product Detail with specs and category',
    (tester) async {
      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);

      await tester.tap(find.text('Woven Fabric Gift Box').first);
      await tester.pumpAndSettle();

      expect(find.text('Woven Fabric Gift Box'), findsWidgets);
      expect(find.text('Features'), findsOneWidget);
      expect(find.text('Premium woven fabric'), findsOneWidget);
      // The category chip on Product Detail navigates to that category.
      await tester.tap(find.text('Luxury Gift Boxes').first);
      await tester.pumpAndSettle();
      expect(find.text('Products'), findsOneWidget); // Category Detail heading
    },
  );

  testWidgets(
    'Product Detail shows Related Products and tapping one navigates to it',
    (tester) async {
      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);

      await tester.tap(find.text('Woven Fabric Gift Box').first);
      await tester.pumpAndSettle();

      // Related Products sits below the gallery/description/specs — off
      // the default 600px test viewport until scrolled into view.
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Related Products'), findsOneWidget);
      // Other luxury-gift-boxes products, per mock_catalog_data.dart.
      expect(find.text('Emerald Ribbon Box'), findsOneWidget);

      await tester.tap(find.text('Emerald Ribbon Box').first);
      await tester.pumpAndSettle();
      expect(find.text('Emerald Ribbon Box'), findsWidgets);
    },
  );

  testWidgets('Product Detail shows an error state for an unknown product id', (
    tester,
  ) async {
    // Isolated render (not routed through the full app) — this is a
    // defensive edge case (a bad/stale product id) that the app's own
    // navigation never actually produces, so there's no in-app tap that
    // reaches it.
    await tester.pumpWidget(
      ProviderScope(
        // BrandedAppBar watches localeProvider — needs a ProviderScope
        // ancestor even in this isolated render. catalogProvider needs the
        // repository overrides too, same as every other test.
        overrides: _testOverrides(),
        child: MaterialApp(
          locale: AppConfig.defaultLocale,
          supportedLocales: AppConfig.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ProductDetailScreen(productId: 'does-not-exist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product not found'), findsOneWidget);
    expect(
      find.text("We couldn't find that product. It may have been removed."),
      findsOneWidget,
    );
  });

  testWidgets(
    'Product Listing screen filters by category and shows all mock products',
    (tester) async {
      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);
      // Index 1, not 0: the Categories section has its own "View All"
      // (→ /categories) earlier in the page — this is Featured Products'
      // (→ /products). ensureVisible scrolls it precisely into the
      // viewport so the tap's hit-test doesn't land just outside it.
      final viewAllProducts = find.text('View All').at(1);
      await tester.ensureVisible(viewAllProducts);
      await tester.pumpAndSettle();

      await tester.tap(viewAllProducts);
      await tester.pumpAndSettle();

      expect(find.text('All Products'), findsWidgets);
      // Products from multiple categories should all be visible unfiltered.
      expect(find.text('Woven Fabric Gift Box'), findsOneWidget);
      expect(find.text('Signature Amenity Set'), findsOneWidget);

      // Filter down to just Hospitality Amenities.
      await tester.tap(find.text('Hospitality Amenities').first);
      await tester.pumpAndSettle();

      expect(find.text('Signature Amenity Set'), findsOneWidget);
      expect(find.text('Woven Fabric Gift Box'), findsNothing);
    },
  );

  testWidgets('App bar search icon opens the search UI shell', (
    tester,
  ) async {
    await _pumpPastSplash(tester);

    // find.byIcon(Icons.search) would also match the decorative icon in
    // Home's own tappable search bar — target the app bar action
    // specifically via its tooltip instead.
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsWidgets);
    expect(find.text('Search products…'), findsOneWidget);
  });

  testWidgets("Home's own search bar also opens the search UI shell", (
    tester,
  ) async {
    await _pumpPastSplash(tester);

    await tester.tap(find.text('Search products…').first);
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsWidgets);
  });

  testWidgets('Language toggle switches the shell and Home content to Arabic', (
    tester,
  ) async {
    await _pumpPastSplash(tester);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('مرحبًا بكم في بريقون'), findsOneWidget);
  });

  // Regression guard for the RenderFlex overflow found in review: a narrow
  // phone width (360px — narrower than this suite's other tests implicitly
  // use) combined with Arabic's typically-longer translated strings is
  // exactly the combination that exposed the original bug. This scrolls
  // the full Home page, a few hundred pixels at a time, in both languages,
  // and fails on *any* exception raised during layout/paint — not just a
  // missing widget, which is what the other tests check for.
  testWidgets(
    'Home has zero overflow/layout exceptions at a narrow width, in EN and AR',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);
      // Regression guard for a real bug found on-device: the categories
      // rail's loading skeleton (briefly visible between navigating past
      // splash and categoriesProvider resolving) wasn't horizontally
      // scrollable, so it overflowed at this width before any data even
      // arrived — catch that transient frame here, not just the settled
      // "loaded" state the checks below cover.
      expect(tester.takeException(), isNull);

      Future<void> scrollFullyAndCheck() async {
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            find.byKey(const Key('home_scroll_view')),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow/layout exception after scroll step $i',
          );
        }
      }

      await scrollFullyAndCheck();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await scrollFullyAndCheck();
    },
  );

  // Same regression guard as Home's, applied to the two new Phase 2C
  // screens: the Categories grid and a Category Detail page (banner,
  // filter chips, sort dropdown, product Wrap) — at a narrow width, in
  // both languages, failing on any layout exception.
  testWidgets(
    'Categories and Category Detail have zero overflow exceptions at a '
    'narrow width, in EN and AR',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Luxury Gift Boxes').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  // Same regression guard again, for the two Phase 2D screens: Product
  // Listing (search + two filter chip rows + sort dropdown + grid) and
  // Product Detail (gallery, specs table, Related Products rail) — the
  // two most visually dense screens added this phase.
  testWidgets(
    'Product Listing and Product Detail have zero overflow exceptions at a '
    'narrow width, in EN and AR',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);
      final viewAllProducts = find.text('View All').at(1);
      await tester.ensureVisible(viewAllProducts);
      await tester.pumpAndSettle();

      await tester.tap(viewAllProducts);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Woven Fabric Gift Box').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  // Same regression guard again, for the three Phase 3 screens: Inquiry
  // Cart (summary card, quantity stepper, remove), the Inquiry Details
  // form (six fields + validation errors), and the Confirmation screen
  // (reference-number card).
  testWidgets(
    'Inquiry Cart, Details form and Confirmation have zero overflow '
    'exceptions at a narrow width, in EN and AR',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);
      await _scrollHome(tester, 500);

      await tester.tap(find.text('Send Inquiry').first);
      await tester.pump();
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .clearSnackBars();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Inquiry'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The Cart's "Submit Quote via Email" action (an OutlinedButton,
      // unlike the gold-filled WhatsApp action) leads to the form — see
      // InquiryCartScreen.
      final proceedButton = find.byType(OutlinedButton).last;
      await tester.ensureVisible(proceedButton);
      await tester.pumpAndSettle();
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Submit empty (in Arabic) to surface validation errors.
      final formList = find.byType(ListView).first;
      await tester.drag(formList, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(2), 'test@example.com');
      await tester.enterText(fields.at(3), '+973 3362 1109');
      await tester.enterText(fields.at(4), 'Bahrain');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(formList, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('INQ-'), findsOneWidget);

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Login screen signs in with mock auth; Profile, Edit Profile, and Sign '
    'Out all reflect the session',
    (tester) async {
      // Taller than the suite's default 800x600 — the Signed In Profile's
      // Sign Out button sits below the fold otherwise, and (per Phase 3's
      // Inquiry Cart test) the sliver machinery behind a plain
      // `ListView(children: ...)` only inflates elements within the
      // viewport, so an off-screen widget isn't just untappable, it isn't
      // found by the finder at all.
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'jane@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Login navigates to Home on success.
      expect(find.text('Welcome to Bariqon'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      // MockAuthRepository derives the display name from the email prefix.
      expect(find.text('jane'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
      await tester.pumpAndSettle();

      // Mock login only populates name/email (Registration is what collects
      // Mobile/Country) — both are required on this form, so a real save
      // needs them filled in too, not just the field being changed.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Jane Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile Number'),
        '+973 3300 1122',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Country'),
        'Bahrain',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);

      final signOutButton = find.widgetWithText(OutlinedButton, 'Sign Out');
      await tester.ensureVisible(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Sign in to view your profile, saved details, and inquiry history.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "Inquiry Details Form uses a signed-in user's email automatically, "
    'with an explicit way to change it',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'jane@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Bariqon'), findsOneWidget);

      await _scrollHome(tester, 500);
      await tester.tap(find.text('Send Inquiry').first);
      await tester.pump();
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .clearSnackBars();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inquiry'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Submit Quote via Email'));
      await tester.pumpAndSettle();
      expect(find.text('Inquiry Details'), findsOneWidget);

      // Signed-in email is used automatically — no editable email field,
      // and the account email is shown read-only.
      expect(find.text('Logged in as:'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Corporate Email'), findsNothing);
      // Name/mobile/country were prefilled from the account too.
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.text('jane'), findsOneWidget);

      // Tapping "Change" reveals the normal editable field, still
      // prefilled with the account email.
      await tester.tap(find.widgetWithText(TextButton, 'Change'));
      await tester.pumpAndSettle();
      expect(find.text('Logged in as:'), findsNothing);
      final emailField = find.widgetWithText(TextFormField, 'Corporate Email');
      expect(emailField, findsOneWidget);
      expect(
        tester.widget<TextFormField>(emailField).controller?.text,
        'jane@example.com',
      );
    },
  );

  testWidgets(
    'Continue as Guest works from Login, and Registration completes the '
    'mock flow',
    (tester) async {
      // Taller than the suite's default 800x600 — Login's "Continue as
      // Guest" button and Registration's fields run past the default
      // viewport's bottom edge.
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Continue as Guest'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Bariqon'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "You're browsing as a guest. Sign in or create an account to save "
          'your profile.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Register'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile Number'),
        '+973 3300 1122',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Country'),
        'Bahrain',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Bariqon'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('John Smith'), findsOneWidget);
    },
  );

  testWidgets('Forgot Password screen completes the mock flow', (tester) async {
    await _pumpPastSplash(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'jane@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Check Your Email'), findsOneWidget);
    expect(find.textContaining('jane@example.com'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back to Sign In'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Settings screen reaches every sub-screen and the Language/Theme rows '
    'work',
    (tester) async {
      await _pumpPastSplash(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);

      await tester.tap(find.text('About Bariqon'));
      await tester.pumpAndSettle();
      expect(find.text('About Bariqon'), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contact Us'));
      await tester.pumpAndSettle();
      expect(find.text('info@bariqon.bh'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.textContaining('placeholder Privacy Policy'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms & Conditions'));
      await tester.pumpAndSettle();
      expect(find.textContaining('placeholder Terms'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Order & Inquiry Updates'), findsOneWidget);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsOneWidget);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      expect(find.text('العربية'), findsWidgets);
    },
  );

  testWidgets(
    'Theme preference persists across a simulated app restart '
    '(regression guard for the Light-resets-to-Dark bug)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      Future<void> pumpApp() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._testOverrides(),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const BariqonApp(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1400));
        await tester.pumpAndSettle();
      }

      Future<void> openSettings() async {
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
      }

      await pumpApp();
      await openSettings();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsOneWidget);

      // Simulate a real app restart: tear down the widget tree/provider
      // container entirely, then rebuild from scratch against the same
      // (now-persisted) SharedPreferences instance — reproduces exactly
      // what the user reported: "Light Mode → Restart app → Theme
      // automatically becomes Dark again." Fails if themeModeProvider
      // ever regresses to being in-memory only.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp();
      await openSettings();

      expect(find.text('Light'), findsOneWidget);
    },
  );

  // Same regression guard again, for the Phase 4 auth/profile/settings
  // screens: Login, Registration, Forgot Password (form + success state),
  // Profile (guest and signed-in branches), Edit Profile, Settings, and
  // its five sub-screens.
  testWidgets(
    'Auth, Profile, and Settings screens have zero overflow exceptions at '
    'a narrow width, in EN and AR',
    (tester) async {
      // Taller than the other narrow-width regression tests' 740 — auth
      // screens (logo + message + fields + footer link) run past that at
      // this width, unlike the shorter catalog/inquiry screens.
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Login screen, EN then AR.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Registration screen, EN then AR.
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Forgot Password screen (form + success state), EN then AR.
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'jane@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Back to Sign In'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Sign in for real to reach Profile's Signed In branch + Edit Profile.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'jane@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Edit Profile screen, EN then AR.
      await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Settings + its five sub-screens, EN then AR each.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final label in [
        'About Bariqon',
        'Contact Us',
        'Privacy Policy',
        'Terms & Conditions',
        'Notifications',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
