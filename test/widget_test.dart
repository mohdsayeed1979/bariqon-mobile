// Smoke tests: splash → app shell → Home content → tab navigation →
// locale switching, all without touching Supabase (still unconfigured in
// tests) — Home's mock-data sections don't call a repository either, per
// the Phase 2B brief.

import 'package:bariqon_app/app/app.dart';
import 'package:bariqon_app/core/config/app_config.dart';
import 'package:bariqon_app/core/storage/local_preferences_service.dart';
import 'package:bariqon_app/core/theme/app_colors.dart';
import 'package:bariqon_app/features/catalog/data/catalog_cache_service.dart';
import 'package:bariqon_app/core/widgets/product_card.dart';
import 'package:bariqon_app/core/widgets/settings_list_tile.dart';
import 'package:bariqon_app/core/widgets/product_results_view.dart';
import 'package:bariqon_app/features/catalog/domain/entities/product.dart';
import 'package:bariqon_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:bariqon_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: BariqonApp()));
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
      expect(find.text('1 item selected'), findsOneWidget);

      // Bump the quantity via the stepper.
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('2 items selected'), findsOneWidget);

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

      final proceedButton = find.widgetWithText(FilledButton, 'Proceed to Inquiry');
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
      expect(find.text('Specifications'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('Origin'), findsOneWidget);
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
      expect(find.text('Specifications'), findsOneWidget);
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
        // ancestor even in this isolated render.
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

      final proceedButton = find.byType(FilledButton).last;
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

  testWidgets(
    'App Lock: Create PIN dialog validates length and mismatch',
    (tester) async {
      await _pumpPastSplash(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Enable App Lock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PIN Lock'));
      await tester.pumpAndSettle();
      expect(find.text('Create PIN'), findsOneWidget);

      // Too short — rejected before the "confirm" step even exists.
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('PIN must be at least 4 digits.'), findsOneWidget);

      // Long enough — advances to the confirmation step.
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm PIN'), findsOneWidget);

      // Mismatched confirmation.
      await tester.enterText(find.byType(TextField), '9999');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text("PINs don't match."), findsOneWidget);

      // Dismissing here never reaches secure storage (only a matching
      // confirmation does) — the actual persisted-PIN read/write path is
      // OS-backed (Keychain/EncryptedSharedPreferences on iOS/Android) and
      // is verified on-device instead, same as the biometric path below.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Authentication Method'), findsNothing);
    },
  );

  testWidgets(
    'App Lock: choosing Biometric on a device without it stays disabled, '
    'no crash',
    (tester) async {
      await _pumpPastSplash(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable App Lock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Biometric Lock'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The test host has no biometric hardware, so this stays disabled
      // rather than silently claiming to be on.
      expect(find.text('Authentication Method'), findsNothing);
    },
  );

  testWidgets('Theme selection persists across a simulated restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    Future<void> boot() async {
      // pumpWidget reuses the existing ProviderScope element (and its
      // ProviderContainer/GoRouter/notifier state) when the new tree's
      // root widget type matches the old one's — pumping a dummy widget
      // first forces a real unmount, so this is an actual fresh
      // `ProviderContainer` each time, not just a rebuild of the same one
      // that happens to still remember where it navigated to.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const BariqonApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
    }

    Future<void> openThemeRow() async {
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
    }

    await boot();
    await openThemeRow();
    expect(find.text('System'), findsOneWidget); // default, nothing saved yet

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);

    // Simulate a cold restart: a brand-new widget tree, backed by the same
    // (now-populated) SharedPreferences instance — exactly what a real
    // restart looks like, since the plugin persists to disk.
    await boot();
    await openThemeRow();
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsNothing);
  });

  // Same regression guard as every other phase's, applied to the new
  // Security (App Lock) screen and its Create PIN dialog.
  testWidgets(
    'Security screen has zero overflow exceptions at a narrow width, in '
    'EN and AR',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPastSplash(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Arabic on the plain Security screen (no dialog open yet
      // — a dialog's modal barrier would otherwise block the app bar's
      // language icon underneath it).
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Enable App Lock, choose PIN, and get partway through Create PIN —
      // all rendered in Arabic/RTL.
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(SimpleDialogOption).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "ProductResultsView passes each product's imageUrl through to "
    'ProductCard — regression test for the bug where Product Listing/'
    'Category Detail always showed the placeholder',
    (tester) async {
      const productWithImage = Product(
        id: 'p1',
        categoryId: 'c1',
        nameEn: 'Test Product',
        nameAr: 'منتج تجريبي',
        descriptionEn: 'Desc',
        descriptionAr: 'وصف',
        price: 10,
        icon: Icons.card_giftcard,
        placeholderColor: AppColors.primary,
        imageUrl: 'https://example.com/real-photo.png',
      );

      // A single pump (not pumpAndSettle) — this only needs the widget
      // tree built once to inspect ProductCard's configuration; letting
      // CachedNetworkImage actually attempt that fake URL over the
      // network would just make the test slow/flaky for no benefit.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProductResultsView(
                loading: false,
                products: [productWithImage],
                locale: Locale('en'),
                sendInquiryLabel: 'Send Inquiry',
                sendInquirySnackbarText: 'Added',
                emptyIcon: Icons.search_off,
                emptyMessage: 'Empty',
              ),
            ),
          ),
        ),
      );

      final card = tester.widget<ProductCard>(find.byType(ProductCard));
      expect(card.imageUrl, 'https://example.com/real-photo.png');
    },
  );

  testWidgets(
    'App Lock: a resume with no corresponding prior pause does not '
    'spuriously re-lock (guards the infinite-relock loop fix)',
    (tester) async {
      // The full biometric-prompt-induced lifecycle race that caused the
      // original loop needs a real OS prompt to reproduce and is verified
      // on-device instead (see the completion report) — this covers the
      // `pausedAt == null` guard specifically: any resume event that
      // doesn't correspond to a real, tracked backgrounding must be a
      // no-op, which is what stops that kind of spurious event from ever
      // compounding into a loop.
      SharedPreferences.setMockInitialValues({
        'app_lock_enabled': true,
        'app_lock_method': 'pin',
        'app_lock_timeout': 0,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const BariqonApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();

      // Locked on cold start, since App Lock is enabled.
      expect(find.text('Bariqon is Locked'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Still just the one lock screen — not rebuilt/duplicated/looping.
      expect(find.text('Bariqon is Locked'), findsOneWidget);
    },
  );

  test(
    'CatalogCacheService round-trips rows through SharedPreferences '
    '(the offline-fallback snapshot used by the Supabase catalog repos)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = CatalogCacheService(prefs);

      expect(cache.getCategories(), isNull);
      expect(cache.getProducts(), isNull);

      final categoryRows = [
        {'id': 1, 'name_en': 'Luxury Gift Boxes', 'name_ar': 'علب الهدايا'},
      ];
      final productRows = [
        {
          'id': 42,
          'category_id': 1,
          'name_en': 'Gift Box',
          'name_ar': 'صندوق هدايا',
          'desc_en': 'A box',
          'desc_ar': 'صندوق',
          'price': '7.500',
          'img': 'https://example.com/img.png',
        },
      ];

      await cache.setCategories(categoryRows);
      await cache.setProducts(productRows);
      await cache.setFeaturedProducts(productRows);
      await cache.setNewArrivals(productRows);
      await cache.setBestSellers(productRows);

      expect(cache.getCategories(), categoryRows);
      expect(cache.getProducts(), productRows);
      expect(cache.getFeaturedProducts(), productRows);
      expect(cache.getNewArrivals(), productRows);
      expect(cache.getBestSellers(), productRows);
    },
  );

  testWidgets(
    'SettingsListTile disclosure chevron mirrors for RTL '
    '(regression test for the Settings/RTL polish pass — Row already '
    'reorders children for RTL, but the chevron glyph itself did not)',
    (tester) async {
      // Directionality goes *inside* `home`, not wrapped around MaterialApp
      // — MaterialApp establishes its own Directionality from its locale,
      // which would otherwise shadow an outer one entirely.
      Future<void> pump(TextDirection direction) => tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SettingsListTile(
                icon: Icons.info_outline,
                label: 'Test',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await pump(TextDirection.ltr);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsNothing);

      await pump(TextDirection.rtl);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    },
  );
}
