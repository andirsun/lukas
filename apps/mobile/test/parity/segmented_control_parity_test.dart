@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/segmented_control.dart';

import '../support/parity.dart';

/// `SegmentedControl` against apps/web/app/ui/SegmentedControl.stories.tsx
/// (`ui-segmentedcontrol--*`), each story as Storybook shows it after its `play` function.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

enum _View { budgets, transactions }

/// The story's `HomeViewSwitch`: `max-w-[360px]` around the control, Presupuestos selected.
class _HomeViewSwitch extends StatefulWidget {
  const _HomeViewSwitch({required this.label, required this.budgets, required this.transactions});

  final String label;
  final String budgets;
  final String transactions;

  @override
  State<_HomeViewSwitch> createState() => _HomeViewSwitchState();
}

class _HomeViewSwitchState extends State<_HomeViewSwitch> {
  var _view = _View.budgets;

  @override
  Widget build(BuildContext context) => cssBlock(
    maxWidth: 360,
    child: SegmentedControl<_View>(
      label: widget.label,
      value: _view,
      options: [
        SegmentOption(_View.budgets, widget.budgets),
        SegmentOption(_View.transactions, widget.transactions),
      ],
      onChanged: (next) => setState(() => _view = next),
    ),
  );
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('segmented control parity: the story\'s clicks and keys end on Presupuestos '
        '($theme)', (t) async {
      await parityGolden(
        t,
        'segmented-control-default',
        const ParityStoryFrame(
          block: true,
          child: _HomeViewSwitch(
            label: 'Vista',
            budgets: 'Presupuestos',
            transactions: 'Movimientos',
          ),
        ),
        theme: theme,
        act: (t) async {
          await t.tap(find.text('Movimientos'));
          await t.pumpAndSettle();
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.sendKeyEvent(LogicalKeyboardKey.home);
        },
      );
    });
  }

  testWidgets('segmented control parity: Transactions tapped, day, English (day)', (t) async {
    await parityGolden(
      t,
      'segmented-control-day-english',
      const ParityStoryFrame(
        block: true,
        child: _HomeViewSwitch(label: 'View', budgets: 'Budgets', transactions: 'Transactions'),
      ),
      theme: 'day',
      locale: const Locale('en'),
      act: (t) async {
        await t.tap(find.text('Transactions'));
        await t.pumpAndSettle();
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
      },
    );
  });
}
