import 'package:flutter/widgets.dart';

import '../api/gen/lukitas_api.dart'
    show CreateTransactionRepeatFrequencyEnum, TransactionSuggestion;
import '../home/home_format.dart' show formatDay;
import '../home/home_widgets.dart' show QuietSpinner;
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/name_field.dart';
import '../ui/press_button.dart';
import 'add_form.dart';
import 'add_session.dart';
import 'category_picker.dart';
import 'more_options.dart';

/// The scrolling middle of the sheet: the name with its recent names, the categories, and "Más
/// opciones" with the date, pending, Repetir and the note (apps/web/app/features/add-transaction/
/// AddTransactionSheet.tsx, `flex flex-col gap-(--space-2)`).
class AddBody extends StatelessWidget {
  const AddBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AddSession.of(context);
    final form = session.form;
    if (form == null) return const _Unloaded();
    final l10n = session.l10n;
    final colors = context.lkColors;
    // On a short screen one row of categories, so the whole sheet fits.
    final short = MediaQuery.sizeOf(context).height < 800;
    final visible = short ? visibleChipsShort : visibleChipsRoomy;
    final dateText = form.date == form.today
        ? l10n.addToday
        : form.date.isEmpty
        ? ''
        : formatDay(form.date, l10n.localeName);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space2,
        children: [
          NameField(
            controller: session.name,
            focusNode: session.nameFocus,
            placeholder: form.selected?.name ?? l10n.nameFieldLabel,
            suggestions: session.shortcuts,
            onChanged: form.setName,
            onPick: (choice) {
              session.nameFocus.unfocus();
              form.pick(choice.source as TransactionSuggestion);
            },
          ),
          if (form.ofKind.isEmpty)
            Text(
              form.kind == Kind.income ? l10n.addNoCategoriesIncome : l10n.addNoCategoriesExpense,
              style: LkText.fieldLabel.copyWith(color: colors.inkMuted),
            )
          else
            CategoryPicker(
              chips: form.chips(visible: visible),
              selectedId: form.selected?.id,
              overflow: form.overflow(visible: visible),
              expanded: form.allChips,
              onSelect: form.select,
              onToggleAll: () => form.allChips = !form.allChips,
            ),
          MoreRow(
            key: const Key('add.more'),
            open: session.moreOpen,
            onToggle: session.toggleMore,
            title: l10n.addMoreOptions,
            summary: [
              dateText,
              form.pending ? l10n.pending : l10n.paid,
              if (form.repeat)
                form.frequency == CreateTransactionRepeatFrequencyEnum.yearly
                    ? l10n.recurringFormYearly
                    : l10n.recurringFormMonthly,
            ].join(' · '),
          ),
          if (session.moreOpen)
            MoreDetails(
              form: form,
              l10n: l10n,
              note: session.note,
              noteFocus: session.noteFocus,
              onPickDate: session.pickDate,
              onPickEndDate: session.pickEndDate,
            ),
        ],
      ),
    );
  }
}

/// The sheet before the categories are known (home has not loaded): a spinner, or why it failed.
class _Unloaded extends StatelessWidget {
  const _Unloaded();

  @override
  Widget build(BuildContext context) {
    final session = AddSession.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final failure = session.home.failure;
    final failed = failure != null;
    return Padding(
      padding: const EdgeInsets.all(LukitasTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: LukitasTokens.space3,
        children: [
          if (!failed) const QuietSpinner(size: 28),
          Semantics(
            liveRegion: true,
            child: Text(
              failed ? (failure.offline ? l10n.errorNetwork : l10n.errorGeneric) : l10n.homeLoading,
              textAlign: TextAlign.center,
              style: LkText.body.copyWith(color: colors.ink),
            ),
          ),
          if (failed) PressButton.text(l10n.retry, onPressed: session.retryLoad),
        ],
      ),
    );
  }
}
