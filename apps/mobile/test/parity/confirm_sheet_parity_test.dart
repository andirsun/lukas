@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/confirm_sheet.dart';
import 'package:lukitas/ui/press_button.dart';

import '../support/parity.dart';

/// `ConfirmSheet` against apps/web/app/ui/ConfirmSheet.stories.tsx (`ui-confirmsheet--*`), each
/// story as Storybook shows it after its `play` function, in night and in day
/// (`OpenDayEnglish` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' `ConfirmHarness`: a "Eliminar" button, and the sheet open over it.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.button,
    required this.title,
    required this.body,
    required this.confirm,
  });

  final String button;
  final String title;
  final String body;
  final String confirm;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    // `initiallyOpen`.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ConfirmSheet.show(
        context,
        title: widget.title,
        body: widget.body,
        confirmLabel: widget.confirm,
        onConfirm: () async {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ParityStoryFrame(
    child: PressButton.text(widget.button, tone: PressTone.secondary, onPressed: () {}),
  );
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('confirm sheet parity: open ($theme)', (t) async {
      await parityGolden(
        t,
        'confirm-sheet-open',
        const _Harness(
          button: 'Eliminar',
          title: '¿Eliminar esta huella?',
          body: 'Ya no podrás entrar con ella. Tu correo sigue funcionando.',
          confirm: 'Sí, eliminar',
        ),
        theme: theme,
      );
    });
  }

  testWidgets('confirm sheet parity: open, day, English (day)', (t) async {
    await parityGolden(
      t,
      'confirm-sheet-open-day-english',
      const _Harness(
        button: 'Delete',
        title: 'Delete this fingerprint?',
        body: "You won't be able to sign in with it anymore. Your email still works.",
        confirm: 'Yes, delete',
      ),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
