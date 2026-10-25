@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/money/format.dart';
import 'package:lukitas/ui/press_button.dart';
import 'package:lukitas/ui/toast.dart';

import '../support/parity.dart';

/// `ToastHost` against apps/web/app/ui/Toast.stories.tsx (`ui-toast--*`), each story as Storybook
/// shows it after its `play` function, in night and in day (`DayEnglish` pins day).
///
/// Storybook takes the picture with CSS animations at their end, so the toast's time bar is gone
/// and the toast is still there: the host here lives for an hour (`dismissAfter`), its bar runs
/// its real eight seconds and is gone when the picture is taken.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' `SavedToastDemo`: a "Guardar" button that shows "Supermercado · −6,08 €" with
/// Deshacer. [auto] shows it when the story opens.
class _Demo extends StatefulWidget {
  const _Demo({required this.save, required this.undo, required this.locale, this.auto = false});

  final String save;
  final String undo;
  final String locale;
  final bool auto;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  void _show() => ToastHost.of(context).show(
    ToastOptions.text(
      'Supermercado · ${formatMoney(-608, 'EUR', widget.locale)}',
      actions: [ToastAction(label: widget.undo, onPressed: () {})],
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.auto) WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  @override
  Widget build(BuildContext context) => ParityStoryFrame(
    child: PressButton.text(widget.save, tone: PressTone.secondary, onPressed: _show),
  );
}

/// The story's decorator: the page inside a `ToastProvider`.
Widget _page(_Demo demo) => ToastHost(dismissAfter: const Duration(hours: 1), child: demo);

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('toast parity: reduced motion, the toast after a click ($theme)', (t) async {
      await parityGolden(
        t,
        'toast-reduced-motion',
        _page(const _Demo(save: 'Guardar', undo: 'Deshacer', locale: 'es')),
        theme: theme,
        act: (t) async {
          await t.tap(find.byType(PressButton));
          await t.pumpAndSettle();
          // The click leaves the focus on the button, and Chrome rings it.
          await _tab(t, 1);
        },
      );
    });

    testWidgets('toast parity: a second toast replaces the first ($theme)', (t) async {
      await parityGolden(
        t,
        'toast-replaces-previous',
        _page(const _Demo(save: 'Guardar', undo: 'Deshacer', locale: 'es')),
        theme: theme,
        act: (t) async {
          await t.tap(find.byType(PressButton));
          await t.pump();
          await t.tap(find.byType(PressButton));
          await t.pumpAndSettle();
          await _tab(t, 1);
        },
      );
    });
  }

  testWidgets('toast parity: shown on opening, day, English (day)', (t) async {
    await parityGolden(
      t,
      'toast-day-english',
      _page(const _Demo(save: 'Save', undo: 'Undo', locale: 'en', auto: true)),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
