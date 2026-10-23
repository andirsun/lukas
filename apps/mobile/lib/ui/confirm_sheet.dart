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
    required Future<void> Function() onConfirm,
  }) async {
    final done = await LkSheet.show<bool>(
      context,
      title: title,
      children: [
        _ConfirmBody(body: body, note: note, confirmLabel: confirmLabel, onConfirm: onConfirm),
      ],
    );
    return done ?? false;
  }
}

class _ConfirmBody extends StatefulWidget {
  const _ConfirmBody({
    required this.body,
    required this.note,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String body;
  final String? note;
  final String confirmLabel;
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
          Text(
            widget.body,
            style: LkText.body.copyWith(color: colors.ink, fontWeight: FontWeight.w700),
          ),
          if (note != null)
            Text(
              note,
              style: LkText.body.copyWith(color: colors.ink, fontWeight: FontWeight.w700),
            ),
          if (wide)
            Row(
              spacing: LukitasTokens.space2,
              children: [
                Expanded(child: cancel),
                Expanded(child: confirm),
              ],
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
