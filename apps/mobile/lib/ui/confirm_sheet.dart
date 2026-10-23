// The web's ConfirmSheet (apps/web/app/ui/ConfirmSheet.tsx).
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'lk_theme.dart';
import 'press_button.dart';
import 'sheet.dart';

/// Asks before a destructive action (archiving a category, deleting a recurrence): the question,
/// what it means, "Cancelar" and the action itself, in the danger colour. Escape, the backdrop and
/// "Cancelar" all leave things as they were.
abstract final class ConfirmSheet {
  /// Opens it and returns whether the action was confirmed and done.
  ///
  /// [onConfirm] does it; when it throws the sheet stays open for another try (the caller says why,
  /// in a toast).
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String? note,
    required String confirmLabel,
    Key? confirmKey,
    required Future<void> Function() onConfirm,
  }) async {
    final done = await LkSheet.show<bool>(
      context,
      title: title,
      children: [
        _ConfirmBody(
          body: body,
          note: note,
          confirmLabel: confirmLabel,
          confirmKey: confirmKey,
          onConfirm: onConfirm,
        ),
      ],
    );
    return done ?? false;
  }
}

/// One way out of a [ChoiceSheet].
class SheetChoice<T> {
  const SheetChoice({
    required this.label,
    required this.value,
    this.tone = PressTone.secondary,
    this.danger = false,
    this.key,
  });

  final String label;
  final T value;

  /// `primary` for the way the sheet suggests; `secondary` for the others.
  final PressTone tone;

  /// The action is the one to think twice about: its label is in the danger colour (`text-over`).
  final bool danger;
  final Key? key;
}

/// A [ConfirmSheet] with more than one way forward, for the questions only the app asks of a
/// guest (leave without an email, or save the progress first): the question, what it means, each
/// choice as a full-width button, and "Cancelar" last. Escape, the backdrop and "Cancelar" all
/// answer null.
abstract final class ChoiceSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String body,
    String? note,
    required List<SheetChoice<T>> choices,
  }) => LkSheet.show<T>(
    context,
    title: title,
    children: [_ChoiceBody<T>(body: body, note: note, choices: choices)],
  );
}

class _ChoiceBody<T> extends StatelessWidget {
  const _ChoiceBody({required this.body, required this.note, required this.choices});

  final String body;
  final String? note;
  final List<SheetChoice<T>> choices;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final note = this.note;
    return Padding(
      padding: const EdgeInsets.only(top: LukitasTokens.space3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space4,
        children: [
          Text(body, style: LkText.body.copyWith(color: colors.ink)),
          if (note != null) Text(note, style: LkText.body.copyWith(color: colors.ink)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LukitasTokens.space2,
            children: [
              for (final choice in choices)
                PressButton(
                  key: choice.key,
                  tone: choice.tone,
                  onPressed: () => Navigator.of(context).pop(choice.value),
                  child: Text(
                    LkText.upperCase(choice.label),
                    style: choice.danger ? TextStyle(color: colors.over) : null,
                  ),
                ),
              PressButton.text(
                l10n.cancel,
                tone: PressTone.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmBody extends StatefulWidget {
  const _ConfirmBody({
    required this.body,
    required this.note,
    required this.confirmLabel,
    required this.confirmKey,
    required this.onConfirm,
  });

  final String body;
  final String? note;
  final String confirmLabel;
  final Key? confirmKey;
  final Future<void> Function() onConfirm;

  @override
  State<_ConfirmBody> createState() => _ConfirmBodyState();
}

class _ConfirmBodyState extends State<_ConfirmBody> {
  var _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // The caller reported it; the sheet stays for another try.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final note = widget.note;
    final confirm = Semantics(
      container: true,
      child: PressButton(
        key: widget.confirmKey,
        tone: PressTone.secondary,
        onPressed: _busy ? null : _confirm,
        child: Text(LkText.upperCase(widget.confirmLabel), style: TextStyle(color: colors.over)),
      ),
    );
    final cancel = PressButton.text(
      l10n.cancel,
      tone: PressTone.ghost,
      onPressed: () => Navigator.of(context).pop(false),
    );
    // Side by side from a phone 400px wide (`min-[400px]:flex-row-reverse`): the action on the
    // right. Narrower, one under the other, the action first.
    final wide = MediaQuery.sizeOf(context).width >= 400;
    return Padding(
      padding: const EdgeInsets.only(top: LukitasTokens.space3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space4,
        children: [
          Text(widget.body, style: LkText.body.copyWith(color: colors.ink)),
          if (note != null) Text(note, style: LkText.body.copyWith(color: colors.ink)),
          if (wide)
            flexOneRow(
              gap: LukitasTokens.space2,
              // `flex-1` is `flex: 1 1 0%`: each button is its own padding and border, and an equal
              // share of what is left. The ghost has 8px each side; the secondary 24px and a 2px
              // border.
              items: [(16, cancel), (52, confirm)],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: LukitasTokens.space2,
              children: [confirm, cancel],
            ),
        ],
      ),
    );
  }
}

/// A row of `flex-1` items ("flex: 1 1 0%"): a box-sizing border-box item cannot be smaller than
/// its padding and border, so each is that much (its first number, in px) and an equal share of
/// the room that is left after the gaps and every item's own.
Widget flexOneRow({required double gap, required List<(double, Widget)> items}) => LayoutBuilder(
  builder: (context, constraints) {
    final own = items.fold<double>(0, (sum, item) => sum + item.$1);
    final share = (constraints.maxWidth - gap * (items.length - 1) - own) / items.length;
    return Row(
      spacing: gap,
      children: [for (final (extra, child) in items) SizedBox(width: extra + share, child: child)],
    );
  },
);
