import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/app.dart' show withAppHosts;
import 'package:lukitas/feedback/celebration.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/lukitas_face.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/ui/toast.dart';

import '../settings/fakes.dart' show FakeFlagStore;
import '../settings/harness.dart' show pumpSettingsApp;
import '../support/fonts.dart';
import 'fakes.dart';

/// The celebration (the web's `Celebration`, apps/web/app/feedback/Celebration.tsx): confetti and a
/// celebrating Lukitas for a save and a payment, landing above the ＋ and clear of the toasts. Its
/// look is the parity pairs' (`celebration-*`); these are what it does.

const _spotSize = 64.0;

/// A phone with a ＋ at the bottom (the landing spot), a button for each event, and the hosts the
/// app has.
class _Page extends ConsumerWidget {
  const _Page({this.spot = true});

  final bool spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Stack(
      children: [
        Positioned(
          left: 8,
          top: 8,
          child: Column(
            children: [
              for (final event in FeedbackEvent.values)
                ElevatedButton(
                  key: Key('give.${event.name}'),
                  onPressed: () => ref.read(feedbackProvider)(event),
                  child: Text(event.name),
                ),
            ],
          ),
        ),
        if (spot)
          const Positioned(
            bottom: 24,
            left: 177,
            width: 58,
            height: 58,
            child: CelebrationAnchor(
              size: _spotSize,
              child: SizedBox.expand(key: Key('spot')),
            ),
          ),
      ],
    ),
  );
}

Future<ProviderContainer> _pump(
  WidgetTester t, {
  bool spot = true,
  bool reduce = false,
  Size size = const Size(412, 915),
}) async {
  await loadAppFonts();
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final container = ProviderContainer(
    overrides: [
      feedbackPlatformProvider.overrideWithValue(FakeFeedbackPlatform()),
      flagStoreProvider.overrideWith((ref, key) => FakeFlagStore()),
    ],
  );
  addTearDown(container.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: nightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: withAppHosts(child!, animateToastBar: false),
        ),
        home: _Page(spot: spot),
      ),
    ),
  );
  await t.pumpAndSettle();
  return container;
}

Future<void> _give(WidgetTester t, FeedbackEvent event) async {
  await t.tap(find.byKey(Key('give.${event.name}')));
  // Placed one frame on, built the next.
  await t.pump();
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  group('the burst', () {
    test('is the web\'s, piece for piece', () {
      // apps/web/app/feedback/Celebration.tsx BURST: 28 pieces on the golden angle, worked out by
      // the web's own code for these.
      expect(confettiBurst, hasLength(28));
      void piece(int i, int tone, bool round, double dx, double rise, double fall, double spin) {
        final p = confettiBurst[i];
        expect(
          (p.tone, p.round, p.dx, p.rise, p.fall, p.spin),
          (tone, round, dx, rise, fall, spin),
        );
      }

      piece(0, 0, false, 105, -60, 90, 240);
      piece(1, 1, false, -118, -113, 66, -301);
      piece(3, 0, true, 83, -109, 128, -423);
      piece(7, 1, true, -103, -101, 72, -367);
      piece(27, 0, true, -46, -61, 152, -387);
    });

    test('a piece goes out and up to 45%, then falls while it turns and fades', () {
      final piece = confettiBurst[1];
      final start = confettiAt(piece, 0);
      expect((start.offset, start.angle, start.opacity), (Offset.zero, 0.0, 1.0));
      final apex = confettiAt(piece, 0.45);
      expect(apex.offset.dx, closeTo(piece.dx * 0.8, 1e-9));
      expect(apex.offset.dy, closeTo(piece.rise, 1e-9));
      expect(apex.angle, closeTo(piece.spin * 0.5, 1e-9));
      expect(apex.opacity, 1);
      final end = confettiAt(piece, 1);
      expect(end.offset.dx, closeTo(piece.dx, 1e-5));
      expect(end.offset.dy, closeTo(piece.fall, 1e-5));
      expect(end.angle, closeTo(piece.spin, 1e-5));
      expect(end.opacity, closeTo(0, 1e-5));
    });

    test('Lukitas grows up from his feet, bounces once and shrinks back; reduced, he fades', () {
      expect(lukitasAt(0, reduced: false), (scale: 0.4, opacity: 0.0));
      expect(lukitasAt(0.2, reduced: false).scale, closeTo(1.06, 1e-9));
      expect(lukitasAt(0.5, reduced: false), (scale: 1.0, opacity: 1.0));
      final end = lukitasAt(1, reduced: false);
      expect(end.scale, closeTo(0.85, 1e-5));
      expect(end.opacity, closeTo(0, 1e-5));
      expect(lukitasAt(0.5, reduced: true), (scale: 1.0, opacity: 1.0));
      expect(lukitasAt(0, reduced: true).opacity, 0);
      expect(lukitasAt(1, reduced: true).opacity, closeTo(0, 1e-5));
    });
  });

  group('when it shows', () {
    for (final event in [FeedbackEvent.saved, FeedbackEvent.incomeSaved, FeedbackEvent.paid]) {
      testWidgets('${event.name} celebrates, then it is gone', (t) async {
        await _pump(t);
        expect(find.byKey(const Key('celebration')), findsNothing);
        await _give(t, event);
        expect(find.byKey(const Key('celebration')), findsOneWidget);
        expect(find.byType(LukitasFace), findsOneWidget);
        expect(find.byKey(const Key('celebration.confetti')), findsOneWidget);
        // One `--celebrate` and a little over.
        await t.pump(const Duration(milliseconds: 1300));
        await t.pump();
        expect(find.byKey(const Key('celebration')), findsNothing);
      });
    }

    for (final event in [
      FeedbackEvent.nearLimit,
      FeedbackEvent.overBudget,
      FeedbackEvent.undo,
      FeedbackEvent.deleted,
      FeedbackEvent.thresholdCrossed,
      FeedbackEvent.keyPressed,
    ]) {
      testWidgets('${event.name} is no party', (t) async {
        await _pump(t);
        await _give(t, event);
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const Key('celebration')), findsNothing);
      });
    }

    testWidgets('it is the person\'s to see whatever the sound and the vibration are set to', (
      t,
    ) async {
      final container = await _pump(t);
      await container.read(soundEnabledProvider.notifier).set(false);
      await container.read(vibrationEnabledProvider.notifier).set(false);
      await _give(t, FeedbackEvent.paid);
      expect(find.byKey(const Key('celebration')), findsOneWidget);
    });

    testWidgets('another event mid-celebration starts it again', (t) async {
      await _pump(t);
      await _give(t, FeedbackEvent.saved);
      await t.pump(const Duration(milliseconds: 1000));
      await _give(t, FeedbackEvent.paid);
      // Past the first's end, the second still shows.
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('celebration')), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1000));
      await t.pump();
      expect(find.byKey(const Key('celebration')), findsNothing);
    });
  });

  group('where he lands', () {
    testWidgets('just above the ＋, centred on it, never over it', (t) async {
      await _pump(t);
      final spot = t.getRect(find.byKey(const Key('spot')));
      await _give(t, FeedbackEvent.paid);
      await t.pump(const Duration(milliseconds: 500));
      final box = t.getRect(find.byType(LukitasFace));
      expect(box.size, const Size(_spotSize, _spotSize));
      expect(box.bottom, closeTo(spot.top - 4, 1e-6));
      expect(box.center.dx, closeTo(spot.center.dx, 1e-6));
    });

    testWidgets('above the toast while one is up, which stays where it is', (t) async {
      await _pump(t);
      final host = t.element(find.byType(_Page));
      ToastHost.of(host).say('Supermercado · −6,08 €', actionLabel: 'Deshacer', onAction: () {});
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      final toast = t.getRect(find.text('Deshacer'));
      await _give(t, FeedbackEvent.paid);
      await t.pump(const Duration(milliseconds: 500));
      final box = t.getRect(find.byType(LukitasFace));
      expect(box.bottom, lessThanOrEqualTo(toast.top + 1));
      expect(t.getRect(find.text('Deshacer')), toast);
    });

    testWidgets('with no spot on the screen he shows at the top, after waiting for one', (t) async {
      await _pump(t, spot: false);
      await t.tap(find.byKey(const Key('give.paid')));
      await t.pump();
      // Looking: not yet.
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('celebration')), findsNothing);
      await t.pump(const Duration(milliseconds: 600));
      await t.pump();
      expect(find.byKey(const Key('celebration')), findsOneWidget);
      // Grown to his size by a third of the way through.
      await t.pump(const Duration(milliseconds: 500));
      final box = t.getRect(find.byType(LukitasFace));
      expect(box.top, 8);
      expect(box.size, const Size(72, 72));
      expect(box.center.dx, 412 / 2);
    });
  });

  group('what he never does', () {
    testWidgets('take a tap: the page under him still gets it', (t) async {
      await _pump(t);
      await _give(t, FeedbackEvent.paid);
      var pressed = 0;
      // The page's own button, under the overlay, answers.
      final container = ProviderScope.containerOf(t.element(find.byType(_Page)));
      expect(container.read(celebrationBurstsProvider), 1);
      await t.tap(find.byKey(const Key('give.paid')));
      await t.pump();
      pressed = container.read(celebrationBurstsProvider);
      expect(pressed, 2);
    });

    testWidgets('speak to assistive technology: the toast or screen already says it', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      await _give(t, FeedbackEvent.paid);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Lukitas'), findsNothing);
      handle.dispose();
    });

    testWidgets('throw confetti under reduced motion: he only fades, on his still frame', (
      t,
    ) async {
      await _pump(t, reduce: true);
      await _give(t, FeedbackEvent.paid);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('celebration')), findsOneWidget);
      expect(find.byKey(const Key('celebration.confetti')), findsNothing);
      expect(find.byType(LukitasFace), findsOneWidget);
    });
  });

  group('in the app', () {
    testWidgets('a payment on home puts him above the bottom bar\'s ＋, over every screen', (
      t,
    ) async {
      final env = await pumpSettingsApp(t);
      env.container.read(feedbackProvider)(FeedbackEvent.paid);
      await t.pump();
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      final plus = t.getRect(find.byKey(const Key('home.add')));
      final box = t.getRect(
        find.descendant(
          of: find.byKey(const Key('celebration')),
          matching: find.byType(LukitasFace),
        ),
      );
      expect(box.bottom, closeTo(plus.top - 4, 1.5));
      expect(box.center.dx, closeTo(plus.center.dx, 1.5));
      await t.pump(const Duration(milliseconds: 1300));
      await t.pump();
      expect(find.byKey(const Key('celebration')), findsNothing);
    });
  });
}
