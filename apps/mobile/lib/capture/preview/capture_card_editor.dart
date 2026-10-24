// The fields that change one movement of the capture preview, in the web's controls: the kind in a
// segmented control, the amount and name in `.lk-input` boxes, the day in a segmented control and the
// category among `CategoryChip`s, as the add sheet lays them out (apps/web/app/features/
// add-transaction/AddTransactionSheet.tsx).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/gen/lukitas_api.dart';
import '../../home/category_look.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/text_styles.dart';
import '../../theme/tokens.g.dart';
import '../../ui/category_chip.dart';
import '../../ui/lk_theme.dart';
import '../../ui/segmented_control.dart';
import '../../ui/web_text_field.dart';
import '../parser/dates.dart' show addDays;
import '../parser/parse.dart' as p;
import 'capture_preview.dart';

/// A change to one card's fields; null fields stay as they are.
typedef CardChange = void Function({
  int? amount,
  p.Kind? kind,
  String? name,
  String? categoryId,
  String? date,
});

/// Which day a card's date is, for its segmented control: today, yesterday, or another one.
enum CardDay { today, yesterday, other }

class CaptureCardEditor extends StatefulWidget {
  const CaptureCardEditor({
    super.key,
    required this.index,
    required this.card,
    required this.categories,
    required this.currency,
    required this.today,
    required this.onChange,
    required this.onPicked,
  });

  final int index;
  final CaptureCard card;
  final List<Category> categories;
  final String currency;
  final String today;
  final CardChange onChange;
  final VoidCallback onPicked;

  @override
  State<CaptureCardEditor> createState() => _CaptureCardEditorState();
}

class _CaptureCardEditorState extends State<CaptureCardEditor> {
  late final _amount = TextEditingController(
    text: cardAmountText(widget.card.amount, currency: widget.currency, locale: _locale),
  );
  late final _name = TextEditingController(text: widget.card.name);
  final _amountFocus = FocusNode();
  final _nameFocus = FocusNode();

  bool get _whole => widget.currency == 'COP';

  String get _locale => AppLocalizations.of(context).localeName == 'en' ? 'en' : 'es';

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _amountFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// A field's caption: `text-[13px] font-bold text-ink-muted`, over its box.
  Widget _field(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LukitasTokens.space1,
    children: [
      Text(label, style: LkText.fieldLabel.copyWith(color: context.lkColors.inkMuted)),
      field,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final card = widget.card;
    final i = widget.index;
    final kind = card.kind == p.Kind.income ? CategoryKindEnum.income : CategoryKindEnum.expense;
    final ofKind = widget.categories.where((c) => c.kind == kind).toList();
    final yesterday = addDays(widget.today, -1);
    final day = card.date == widget.today
        ? CardDay.today
        : card.date == yesterday
        ? CardDay.yesterday
        : CardDay.other;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LukitasTokens.space1,
        LukitasTokens.space1,
        LukitasTokens.space1,
        LukitasTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space3,
        children: [
          SegmentedControl<p.Kind>(
            label: l10n.addKindLabel,
            value: card.kind,
            options: [
              SegmentOption(
                p.Kind.expense,
                l10n.addKindExpense,
                key: Key('capture.card.$i.kind.expense'),
              ),
              SegmentOption(
                p.Kind.income,
                l10n.addKindIncome,
                key: Key('capture.card.$i.kind.income'),
              ),
            ],
            onChanged: (kind) => widget.onChange(kind: kind),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: LukitasTokens.space2,
            children: [
              Expanded(
                child: _field(
                  l10n.captureAmountLabel,
                  WebTextField(
                    controller: _amount,
                    focusNode: _amountFocus,
                    fieldKey: Key('capture.card.$i.amount'),
                    label: l10n.captureAmountLabel,
                    keyboardType: TextInputType.numberWithOptions(decimal: !_whole),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(_whole ? r'[0-9]' : r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (text) => widget.onChange(
                      amount: parseCardAmount(text, currency: widget.currency, locale: _locale),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _field(
                  l10n.captureNameLabel,
                  WebTextField(
                    controller: _name,
                    focusNode: _nameFocus,
                    fieldKey: Key('capture.card.$i.name'),
                    label: l10n.captureNameLabel,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    onChanged: (text) => widget.onChange(name: text),
                  ),
                ),
              ),
            ],
          ),
          _field(
            l10n.addDateLabel,
            SegmentedControl<CardDay>(
              label: l10n.addDateLabel,
              value: day,
              options: [
                SegmentOption(CardDay.today, l10n.addToday, key: Key('capture.card.$i.date.today')),
                SegmentOption(
                  CardDay.yesterday,
                  l10n.captureYesterday,
                  key: Key('capture.card.$i.date.yesterday'),
                ),
                if (day == CardDay.other)
                  SegmentOption(CardDay.other, card.date, key: Key('capture.card.$i.date.other')),
              ],
              onChanged: (next) => switch (next) {
                CardDay.today => widget.onChange(date: widget.today),
                CardDay.yesterday => widget.onChange(date: yesterday),
                CardDay.other => null,
              },
            ),
          ),
          if (ofKind.isEmpty)
            Text(
              card.kind == p.Kind.income ? l10n.addNoCategoriesIncome : l10n.addNoCategoriesExpense,
              style: LkText.label.copyWith(color: colors.inkMuted),
            )
          else
            _field(
              l10n.addCategoryLabel,
              CategoryChipGrid(
                children: [
                  for (final c in ofKind)
                    CategoryChip(
                      key: Key('capture.card.$i.category.${c.id}'),
                      glyph: categoryLook(icon: c.icon, color: c.color).glyph,
                      label: c.name,
                      selected: c.id == card.categoryId,
                      onSelect: () {
                        widget.onChange(categoryId: c.id);
                        widget.onPicked();
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
