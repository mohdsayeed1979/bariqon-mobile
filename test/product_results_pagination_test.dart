// Regression guard for the "View All Products shows an incomplete catalog"
// production bug. [ProductResultsView] renders its results a page at a time
// and grows the window as the user scrolls — but it lives *inside* an
// enclosing scrollable (a ListView on Product Listing / Category Detail, a
// SingleChildScrollView on Search). The original implementation listened for
// scroll via a NotificationListener placed on itself; because scroll
// notifications only bubble up to ancestors, that listener never saw the
// parent scroll, so the window stayed pinned at the first page (24) forever
// and the rest of the catalog was unreachable no matter how far you scrolled.
//
// These tests mount the widget exactly the way the real screens do — as a
// child of a scrollable — and assert that scrolling actually reveals items
// past the first page, that a single-page result renders fully with no
// "load more" spinner, and that an empty result shows the empty state.

import 'package:bariqon_app/core/widgets/product_results_view.dart';
import 'package:bariqon_app/features/auth/data/mock_auth_repository.dart';
import 'package:bariqon_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bariqon_app/features/catalog/domain/entities/product.dart';
import 'package:bariqon_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic products with null image URLs — the card falls back to its
/// icon/placeholder, so no network image is attempted in the test.
List<Product> _products(int count) => [
  for (var i = 0; i < count; i++)
    Product(
      id: 'p$i',
      categoryId: 'c1',
      nameEn: 'Product ${i.toString().padLeft(3, '0')}',
      nameAr: 'منتج $i',
      descriptionEn: 'A test product.',
      descriptionAr: 'منتج اختباري.',
      price: 10 + i.toDouble(),
      icon: Icons.card_giftcard,
      placeholderColor: const Color(0xFF123456),
    ),
];

Future<void> _pumpInScrollable(
  WidgetTester tester,
  List<Product> products,
) async {
  await tester.pumpWidget(
    ProviderScope(
      // Default session is Signed Out, so wishlistControllerProvider resolves
      // to an empty set without ever touching Supabase — same override the
      // main widget suite uses.
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListView(
            children: [
              ProductResultsView(
                loading: false,
                products: products,
                locale: const Locale('en'),
                sendInquiryLabel: 'Send Inquiry',
                sendInquirySnackbarText: 'Added to your inquiry cart',
                emptyIcon: Icons.search_off_outlined,
                emptyMessage: 'No products found.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: while more products remain, the trailing "load more"
  // CircularProgressIndicator animates indefinitely and would never settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets(
    'View All reveals the entire multi-page catalog by scrolling, not just '
    'the first page',
    (tester) async {
      // A narrow, short viewport so the first page (24) definitely overflows
      // and the list is genuinely scrollable from the start.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpInScrollable(tester, _products(50));

      // First page is present...
      expect(find.text('Product 000'), findsOneWidget);
      // ...but items past the first page (24) are not built yet.
      expect(find.text('Product 040'), findsNothing);
      // The "loading more" affordance is shown because more remain.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Scrolling the ENCLOSING list must grow the window until the very last
      // product is reachable. Without the fix this throws (window never grew).
      await tester.scrollUntilVisible(
        find.text('Product 049'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Product 049'), findsOneWidget);
      // Everything is now loaded, so the trailing spinner is gone.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'A single-page result renders every product with no load-more spinner',
    (tester) async {
      await _pumpInScrollable(tester, _products(10));

      expect(find.text('Product 000'), findsOneWidget);
      expect(find.text('Product 009'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('An empty result shows the empty state', (tester) async {
    await _pumpInScrollable(tester, const []);

    expect(find.text('No products found.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
