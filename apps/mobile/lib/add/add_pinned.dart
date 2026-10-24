import 'package:flutter/widgets.dart';

import '../ui/amount_field.dart';
import '../ui/segmented_control.dart';
import 'add_form.dart';
import 'add_session.dart';

/// What stays in view under the sheet's header: the kind (Gasto or Ingreso) and the amount being
/// typed. What follows scrolls (if it must) under them.
class AddPinned extends StatelessWidget {
  const AddPinned({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AddSession.of(context);
    final form = session.form;
    if (form == null) return const SizedBox.shrink();
    final l10n = session.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SegmentedControl<Kind>(
          label: l10n.addKindLabel,
          value: form.kind,
          options: [
            SegmentOption(Kind.expense, l10n.addKindExpense, key: const Key('add.kind.expense')),
            SegmentOption(Kind.income, l10n.addKindIncome, key: const Key('add.kind.income')),
          ],
          onChanged: (kind) {
            if (!session.saving) form.setKind(kind);
          },
        ),
        AmountDisplay(
          key: const Key('add.amount'),
          raw: form.raw,
          currency: form.currency,
          sign: form.kind == Kind.expense ? '−' : '+',
          tone: form.kind == Kind.expense ? AmountTone.expense : AmountTone.income,
        ),
      ],
    );
  }
}
