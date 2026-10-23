@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/press_button.dart';
import 'package:lukitas/ui/press_link.dart';

import '../support/parity.dart';

/// `PressLink` against apps/web/app/ui/PressLink.stories.tsx (`ui-presslink--*`): a link dressed as
/// the primary button, and the small secondary one in day, English.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).
void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('press link parity: primary, with its focus ring ($theme)', (t) async {
      await parityGolden(
        t,
        'press-link-primary',
        ParityStoryFrame(child: PressLink.text('Empieza ahora', onPressed: () {})),
        theme: theme,
        act: (t) => t.sendKeyEvent(LogicalKeyboardKey.tab),
      );
    });
  }

  testWidgets('press link parity: secondary and small, day, English (day)', (t) async {
    await parityGolden(
      t,
      'press-link-secondary-small',
      ParityStoryFrame(
        child: PressLink.text(
          'Sign in',
          tone: PressTone.secondary,
          size: PressSize.sm,
          onPressed: () {},
        ),
      ),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
