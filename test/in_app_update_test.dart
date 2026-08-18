// Tests for the mandatory Google Play In-App Update gate.
//
// The decision rule (isMandatoryUpdate) is unit-tested directly against the
// plugin's UpdateAvailability enum. The UpdateGate widget is driven through a
// fake InAppUpdateService so both the "no update → app is usable" path (which
// also covers offline / non-Play / debug / already-latest, since all of those
// resolve to UpdateStatus.none) and the "forced → non-dismissable block +
// Immediate flow launched" path are verified deterministically, without the
// platform channel. The real Google Play Immediate flow itself can only be
// verified on a Play-distributed build (see the report).

import 'package:bariqon_app/app/update_gate.dart';
import 'package:bariqon_app/core/update/in_app_update_service.dart';
import 'package:bariqon_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

class _FakeUpdateService extends InAppUpdateService {
  _FakeUpdateService(this._status);

  final UpdateStatus _status;
  int immediateCalls = 0;

  @override
  Future<UpdateStatus> check() async => _status;

  @override
  Future<void> startImmediate() async => immediateCalls++;
}

Future<void> _pumpGate(WidgetTester tester, InAppUpdateService service) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inAppUpdateServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: UpdateGate(child: Scaffold(body: Text('APP BODY'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('isMandatoryUpdate (Play-reported, never a hardcoded version)', () {
    test('forces when Play reports an available Immediate update', () {
      expect(
        isMandatoryUpdate(
          availability: UpdateAvailability.updateAvailable,
          immediateAllowed: true,
        ),
        isTrue,
      );
    });

    test('does not force when an Immediate update is not allowed', () {
      expect(
        isMandatoryUpdate(
          availability: UpdateAvailability.updateAvailable,
          immediateAllowed: false,
        ),
        isFalse,
      );
    });

    test('does not force when Play reports no update available', () {
      expect(
        isMandatoryUpdate(
          availability: UpdateAvailability.updateNotAvailable,
          immediateAllowed: true,
        ),
        isFalse,
      );
    });

    test('does not force on unknown availability', () {
      expect(
        isMandatoryUpdate(
          availability: UpdateAvailability.unknown,
          immediateAllowed: true,
        ),
        isFalse,
      );
    });

    test('resumes an Immediate update already in progress', () {
      expect(
        isMandatoryUpdate(
          availability: UpdateAvailability.developerTriggeredUpdateInProgress,
          immediateAllowed: true,
        ),
        isTrue,
      );
    });
  });

  group('UpdateGate', () {
    testWidgets(
      'renders the app normally when Play reports no update '
      '(covers offline / non-Play / debug / already-latest)',
      (tester) async {
        final service = _FakeUpdateService(UpdateStatus.none);
        await _pumpGate(tester, service);

        expect(find.text('APP BODY'), findsOneWidget);
        expect(find.text('Update required'), findsNothing);
        expect(service.immediateCalls, 0);
      },
    );

    testWidgets(
      'blocks with a non-dismissable screen and launches the Immediate flow '
      'when Play forces an update',
      (tester) async {
        final service = _FakeUpdateService(UpdateStatus.forced);
        await _pumpGate(tester, service);

        // The mandatory screen is shown and the official flow was launched.
        expect(find.text('Update required'), findsOneWidget);
        expect(service.immediateCalls, 1);

        // Tapping "Update" re-launches Play's flow — the user stays in the
        // update-required state rather than falling through to the app.
        await tester.tap(find.text('Update'));
        await tester.pump();
        expect(service.immediateCalls, 2);
        expect(find.text('Update required'), findsOneWidget);
      },
    );
  });
}
