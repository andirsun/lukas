@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/feedback/celebration.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/lukitas_face.dart';
import 'package:lukitas/ui/press_button.dart';

import '../feedback/fakes.dart';
import '../settings/fakes.dart' show FakeFlagStore;
import '../support/parity.dart';

/// `CelebrationHost` against apps/web/app/feedback/Celebration.stories.tsx (`feedback-celebration--
/// mid-flight*`), each story as Storybook shows it after its `play` function: the celebration
/// stopped part of the way through (`freezeAt`), which the shots, taking animations at their end,
/// could not take of a moving one.
///
/// The app is stopped at the same moment of its 1.2 s: [_at] pumps that long after the celebration
/// has started (its controller and Lukitas' sprite start on the same frame, as the web's
/// animations do).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' `CelebrationDemo`: a button that gives [event], a landing spot as the ＋ is in the
/// app (a 58px box at the middle, 24px up) and, with [toast], where the undo toast would be.
class _Demo extends ConsumerWidget {
  const _Demo({required this.label, required this.event, this.spot = true, this.toast = false});

  final String label;
  final FeedbackEvent event;
  final bool spot;
  final bool toast;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
    children: [
      ParityStoryFrame(
        child: PressButton.text(label, onPressed: () => ref.read(feedbackProvider)(event)),
      ),
      if (spot)
        Positioned(
          bottom: 24,
          left: (412 - 58) / 2,
          width: 58,
          height: 58,
          child: const CelebrationAnchor(size: 64, child: SizedBox.expand()),
        ),
      if (spot && toast)
        const Positioned(
          bottom: 96,
          left: 16,
          right: 16,
          height: 64,
          child: CelebrationAvoid(child: SizedBox.expand()),
        ),
    ],
  );
}

List<Override> _overrides() => [
  feedbackPlatformProvider.overrideWithValue(FakeFeedbackPlatform()),
  flagStoreProvider.overrideWith((ref, key) => FakeFlagStore()),
];

/// Gives the event with the keyboard, as the story's click does (and leaves the ring on the
/// button), then lets the celebration be placed and start, and runs [fraction] of its stay.
Future<void> _at(WidgetTester t, double fraction) async {
  await t.runAsync(() async {
    final context = t.element(find.byType(PressButton));
    await precacheImage(AssetImage(LukitasMood.celebrating.sheet), context);
  });
  await t.sendKeyEvent(LogicalKeyboardKey.tab);
  await t.sendKeyEvent(LogicalKeyboardKey.enter);
  // Placed one frame on, built the next, and both tickers begin on the one after.
  await t.pump();
  await t.pump();
  await t.pump();
  await t.pump(Duration(milliseconds: (fraction * 1200).round()));
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('celebration parity: half way, above the spot ($theme)', (t) async {
      await parityGolden(
        t,
        'celebration-mid-flight',
        const _Demo(label: 'paid', event: FeedbackEvent.paid),
        theme: theme,
        overrides: _overrides(),
        act: (t) => _at(t, 0.5),
        settleAfterAct: false,
      );
    });

    testWidgets('celebration parity: half way, clear of the toast ($theme)', (t) async {
      await parityGolden(
        t,
        'celebration-clear-of-the-toast',
        const _Demo(label: 'paid', event: FeedbackEvent.paid, toast: true),
        theme: theme,
        overrides: _overrides(),
        act: (t) => _at(t, 0.5),
        settleAfterAct: false,
      );
    });

    testWidgets('celebration parity: half way, with no spot on the screen ($theme)', (t) async {
      await parityGolden(
        t,
        'celebration-no-spot',
        const _Demo(label: 'paid', event: FeedbackEvent.paid, spot: false),
        theme: theme,
        overrides: _overrides(),
        act: (t) async {
          // He waits 800 ms for a spot, then shows at the top (the story freezes the moment the
          // celebration is there).
          await t.runAsync(() async {
            final context = t.element(find.byType(PressButton));
            await precacheImage(AssetImage(LukitasMood.celebrating.sheet), context);
          });
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.sendKeyEvent(LogicalKeyboardKey.enter);
          await t.pump();
          await t.pump(const Duration(milliseconds: 900));
          await t.pump();
          await t.pump();
          await t.pump(const Duration(milliseconds: 600));
        },
        settleAfterAct: false,
      );
    });

    testWidgets('celebration parity: a tenth in ($theme)', (t) async {
      await parityGolden(
        t,
        'celebration-early',
        const _Demo(label: 'paid', event: FeedbackEvent.paid),
        theme: theme,
        overrides: _overrides(),
        act: (t) => _at(t, 0.1),
        settleAfterAct: false,
      );
    });

    testWidgets('celebration parity: under reduced motion ($theme)', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await parityGolden(
        t,
        'celebration-reduced-motion',
        const _Demo(label: 'paid', event: FeedbackEvent.paid),
        theme: theme,
        overrides: _overrides(),
        act: (t) => _at(t, 0.5),
        settleAfterAct: false,
      );
    });
  }

  testWidgets('celebration parity: three quarters in, day, English (day)', (t) async {
    await parityGolden(
      t,
      'celebration-day-english',
      const _Demo(label: 'expenseSaved', event: FeedbackEvent.saved),
      theme: 'day',
      locale: const Locale('en'),
      overrides: _overrides(),
      act: (t) => _at(t, 0.75),
      settleAfterAct: false,
    );
  });
}
