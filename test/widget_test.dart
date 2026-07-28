// Smoke tests: splash → app shell → Home content → tab navigation →
// locale switching, all without touching Supabase (still unconfigured in
// tests) — Home's mock-data sections don't call a repository either, per
// the Phase 2B brief.

import 'package:bariqon_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Coming soon'), findsOneWidget);

    await tester.tap(find.text('Inquiry'));
    await tester.pumpAndSettle();
    expect(find.text('Inquiry'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Send Inquiry on a product card shows placeholder feedback', (
    tester,
  ) async {
    await _pumpPastSplash(tester);
    await _scrollHome(tester, 500);

    await tester.tap(find.text('Send Inquiry').first);
    await tester.pump(); // start the SnackBar animation
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Inquiry cart — coming soon'), findsOneWidget);
  });

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
}
