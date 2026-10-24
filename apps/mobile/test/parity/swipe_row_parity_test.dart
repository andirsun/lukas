@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/surfaces.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/theme/tokens.g.dart';
import 'package:lukitas/ui/lk_theme.dart';
import 'package:lukitas/ui/pressable.dart';
import 'package:lukitas/ui/swipe_row.dart';
import 'package:lukitas/ui/transaction_row.dart';

import '../support/parity.dart';

/// `SwipeRow` against apps/web/app/ui/SwipeRow.stories.tsx (`ui-swiperow--*`), each story as
/// Storybook shows it after its `play` function, in night and in day (`DayEnglish` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// `.lk-more-row`, the button the stories put under the row ("Fuera de la fila"): a 44px row
/// with a 2px `control-edge` border; it takes the focus ring.
class _MoreRow extends StatelessWidget {
  const _MoreRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final radius = LkSurface.radius(LkRadius.md);
    return Pressable(
      onPressed: () {},
      builder: (context, state) => RingBox(
        radius: state.focusVisible ? radius : null,
        color: colors.focus,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space3),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: colors.surfaceRow,
            borderRadius: radius,
            border: Border.all(color: colors.controlEdge, width: 2),
          ),
          child: Text('Fuera de la fila', style: LkText.input.copyWith(color: colors.ink)),
        ),
      ),
    );
  }
}

/// The stories' `Demo`: a TransactionRow inside its SwipeRow in a column 360px wide, and a button
/// outside the row.
Widget _demo({
  required bool pending,
  required String delete,
  required String edit,
  required String paid,
}) {
  return ParityStoryFrame(
    block: true,
    child: cssBlock(
      maxWidth: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          SwipeScope(
            child: SwipeRow(
              deleteLabel: delete,
              onDelete: () {},
              right: pending
                  ? SwipeRight(SwipeRightKind.paid, () {}, paid)
                  : SwipeRight(SwipeRightKind.edit, () {}, edit),
              child: TransactionRow(
                name: pending ? 'Spotify' : 'continente',
                categoryName: pending ? 'suscripciones' : 'Supermercado',
                glyph: pending ? '☂️' : '🛒',
                amount: pending ? -699 : -608,
                currency: 'EUR',
                status: pending ? TransactionRowStatus.pending : TransactionRowStatus.paid,
                onOpen: () {},
                onPay: pending ? () async {} : null,
              ),
            ),
          ),
          const _MoreRow(),
        ],
      ),
    ),
  );
}

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('swipe row parity: at rest after a swipe right that edits ($theme)', (t) async {
      await parityGolden(
        t,
        'swipe-row-at-rest',
        _demo(pending: false, delete: 'Borrar', edit: 'Editar', paid: 'Pagado'),
        theme: theme,
        act: (t) async {
          // 60 % of the row's width, slowly: past the threshold, the action runs, the row springs
          // back.
          await t.timedDrag(
            find.byType(SwipeRow),
            const Offset(216, 0),
            const Duration(milliseconds: 300),
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('swipe row parity: keyboard past a pending row, on the button outside ($theme)', (
      t,
    ) async {
      await parityGolden(
        t,
        'swipe-row-pending',
        _demo(pending: true, delete: 'Borrar', edit: 'Editar', paid: 'Pagado'),
        theme: theme,
        act: (t) => _tab(t, 3),
      );
    });
  }

  testWidgets('swipe row parity: swiped open, Edit, day, English (day)', (t) async {
    await parityGolden(
      t,
      'swipe-row-open-day-english',
      _demo(pending: false, delete: 'Delete', edit: 'Edit', paid: 'Paid'),
      theme: 'day',
      locale: const Locale('en'),
      act: (t) async {
        // The story clicked the button outside the row first (it keeps the focus, and Chrome rings
        // it), then swiped right a short way, slowly: the row opens and stays.
        await t.timedDrag(
          find.byType(SwipeRow),
          const Offset(70, 0),
          const Duration(milliseconds: 300),
        );
        await t.pumpAndSettle();
        await _tab(t, 2);
      },
    );
  });
}
