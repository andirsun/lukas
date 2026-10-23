import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/gen/lukitas_api.dart';
import '../../home/category_look.dart';
import '../../l10n/app_localizations.dart';
import '../../money/format.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.g.dart';
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

/// One movement of the preview: its amount, name and category at a glance, a remove button, and,
/// open, the fields to change it.
class CaptureCardView extends StatelessWidget {
  const CaptureCardView({
    super.key,
    required this.index,
    required this.card,
    required this.open,
    required this.categories,
    required this.currency,
    required this.today,
    required this.enabled,
    required this.onToggle,
    required this.onPick,
    required this.onRemove,
    required this.onChange,
    required this.onPicked,
  });

  final int index;
  final CaptureCard card;
  final bool open;
  final List<Category> categories;
  final String currency;
  final String today;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final CardChange onChange;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final locale = l10n.localeName;
    final category = categories.where((c) => c.id == card.categoryId).firstOrNull;
    final hasAmount = (card.amount ?? 0) > 0;
    final expense = card.kind == p.Kind.expense;

    return Container(
      key: Key('capture.card.$index'),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
        border: Border.all(color: card.complete ? colors.stroke : colors.near, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
            onTap: enabled ? onToggle : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(LukitasTokens.space3, LukitasTokens.space2, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAmount
                              ? formatMoney(card.amount!, currency, locale)
                              : l10n.captureNeedsAmount,
                          style: TextStyle(
                            color: hasAmount ? (expense ? colors.over : colors.good) : colors.near,
                            fontSize: hasAmount ? 20 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (card.name.isNotEmpty)
                          Text(
                            card.name,
                            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
                          ),
                        const SizedBox(height: 4),
                        if (category != null)
                          Text(
                            '${categoryLook(icon: category.icon, color: category.color).glyph} '
                            '${category.name}',
                            style: TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w700),
                          )
                        else
                          OutlinedButton(
                            key: Key('capture.card.$index.pick'),
                            onPressed: enabled ? onPick : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.near,
                              side: BorderSide(color: colors.near, width: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(l10n.capturePickCategory),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('capture.card.$index.remove'),
                    tooltip: l10n.captureRemove,
                    onPressed: enabled ? onRemove : null,
                    icon: Icon(Icons.close, color: colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            CaptureCardEditor(
              key: ValueKey('editor-${card.id}'),
              index: index,
              card: card,
              categories: categories,
              currency: currency,
              today: today,
              onChange: onChange,
              onPicked: onPicked,
            ),
        ],
      ),
    );
  }
}

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

  bool get _whole => widget.currency == 'COP';

  String get _locale => AppLocalizations.of(context).localeName == 'en' ? 'en' : 'es';

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final card = widget.card;
    final i = widget.index;
    final kind = card.kind == p.Kind.income ? CategoryKindEnum.income : CategoryKindEnum.expense;
    final ofKind = widget.categories.where((c) => c.kind == kind).toList();
    final yesterday = addDays(widget.today, -1);
    InputDecoration field(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
        borderSide: BorderSide(color: colors.stroke, width: 2),
      ),
    );
    Widget chip(Key key, String label, bool selected, VoidCallback onTap) => ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colors.brand,
      labelStyle: TextStyle(
        color: selected ? colors.onBrand : colors.ink,
        fontWeight: FontWeight.w700,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LukitasTokens.space3,
        0,
        LukitasTokens.space3,
        LukitasTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('capture.card.$i.amount'),
                  controller: _amount,
                  keyboardType: TextInputType.numberWithOptions(decimal: !_whole),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(_whole ? r'[0-9]' : r'[0-9.,]')),
                  ],
                  maxLength: 12,
                  onChanged: (text) => widget.onChange(
                    amount: parseCardAmount(text, currency: widget.currency, locale: _locale),
                  ),
                  style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
                  decoration: field(l10n.captureAmountLabel),
                ),
              ),
              const SizedBox(width: LukitasTokens.space2),
              Expanded(
                flex: 2,
                child: TextField(
                  key: Key('capture.card.$i.name'),
                  controller: _name,
                  maxLength: 120,
                  onChanged: (text) => widget.onChange(name: text),
                  style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
                  decoration: field(l10n.captureNameLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: LukitasTokens.space2),
          Wrap(
            spacing: LukitasTokens.space2,
            runSpacing: LukitasTokens.space1,
            children: [
              chip(
                Key('capture.card.$i.kind.expense'),
                l10n.addKindExpense,
                card.kind == p.Kind.expense,
                () => widget.onChange(kind: p.Kind.expense),
              ),
              chip(
                Key('capture.card.$i.kind.income'),
                l10n.addKindIncome,
                card.kind == p.Kind.income,
                () => widget.onChange(kind: p.Kind.income),
              ),
              chip(
                Key('capture.card.$i.date.today'),
                l10n.addToday,
                card.date == widget.today,
                () => widget.onChange(date: widget.today),
              ),
              chip(
                Key('capture.card.$i.date.yesterday'),
                l10n.captureYesterday,
                card.date == yesterday,
                () => widget.onChange(date: yesterday),
              ),
              if (card.date != widget.today && card.date != yesterday)
                chip(Key('capture.card.$i.date.other'), card.date, true, () {}),
            ],
          ),
          const SizedBox(height: LukitasTokens.space2),
          if (ofKind.isEmpty)
            Text(
              card.kind == p.Kind.income ? l10n.addNoCategoriesIncome : l10n.addNoCategoriesExpense,
              style: TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w700),
            )
          else
            Wrap(
              spacing: LukitasTokens.space2,
              runSpacing: LukitasTokens.space1,
              children: [
                for (final c in ofKind)
                  chip(
                    Key('capture.card.$i.category.${c.id}'),
                    '${categoryLook(icon: c.icon, color: c.color).glyph} ${c.name}',
                    c.id == card.categoryId,
                    () {
                      widget.onChange(categoryId: c.id);
                      widget.onPicked();
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
