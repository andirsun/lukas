// The web's AmountField (apps/web/app/ui/AmountField.tsx) and the CSS it uses: app.css
// `.lk-amount-display` (`is-expense`, `is-income`) and `.lk-sheet-amount`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../add/keypad_input.dart';
import '../money/format.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'keypad.dart';
import 'lk_theme.dart';
import 'sheet.dart';

/// How long typing must pause before the amount is announced.
const _announceAfter = Duration(milliseconds: 500);

/// How the figure is coloured: spending, income, or neither (a budget).
enum AmountTone { expense, income, neutral }

/// The big figure of an amount being typed, with the muted lukas hint after it in pesos, as the add
/// sheet shows it: [sign] (`−` for spending, `+` for income) once there is an amount, formatted
/// from the raw keypad text [raw]. Screen readers hear it once typing pauses, not at every key.
class AmountDisplay extends StatefulWidget {
  const AmountDisplay({
    super.key,
    required this.raw,
    required this.currency,
    this.sign = '',
    this.tone = AmountTone.neutral,
    this.invalid = false,
  });

  /// The raw text typed so far (`6,08` in es, `6.08` in en).
  final String raw;
  final String currency;
  final String sign;
  final AmountTone tone;

  /// Colours the figure as an error (it is tied to an error message).
  final bool invalid;

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<AmountDisplay> {
  Timer? _timer;
  String? _announced;
  String _latest = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// [announcement] once it has stopped changing for [_announceAfter] (the first one at once).
  String _settled(String announcement) {
    if (announcement != _latest) {
      _latest = announcement;
      _timer?.cancel();
      if (_announced == null) {
        _announced = announcement;
      } else {
        _timer = Timer(_announceAfter, () {
          if (mounted) setState(() => _announced = _latest);
        });
      }
    }
    return _announced ?? announcement;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final locale = Localizations.localeOf(context).languageCode;
    final format = AmountFormat(locale, widget.currency);
    final cents = amountCents(widget.raw, format);
    final hint = lukasHint(cents, locale, currency: widget.currency);
    final text =
        '${cents > 0 ? widget.sign : ''}${formatAmountInput(wholeAmount(widget.raw, format), widget.currency, locale)}';
    final color = widget.invalid
        ? colors.over
        : switch (widget.tone) {
            AmountTone.expense => colors.over,
            AmountTone.income => colors.good,
            AmountTone.neutral => colors.ink,
          };
    // `.lk-sheet.has-footer .lk-sheet-amount { line-height: 1.15 }`.
    final tight = LkSheetScope.maybeOf(context)?.hasFooter ?? false;
    final style = LkText.display.copyWith(color: color, height: tight ? 1.15 : null);
    final announced = _settled(hint == null ? text : '$text $hint');

    return Stack(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: double.infinity,
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: text),
                  if (hint != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: hint,
                      style: LkText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: null,
                        color: colors.inkMuted,
                        fontFeatures: const [],
                      ),
                    ),
                  ],
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Semantics(liveRegion: true, label: announced, child: const SizedBox.shrink()),
        ),
      ],
    );
  }
}

/// A physical keyboard types on the keypad (the web's `useAmountKeys`) while focus is inside
/// [child]: the digits, the language's decimal key and Backspace. The thousands separator is
/// ignored (`15.000` in Spanish is 15000) and pesos take no decimals (`keypad_input.dart`).
class AmountKeys extends StatelessWidget {
  const AmountKeys({
    super.key,
    required this.raw,
    required this.onChanged,
    required this.currency,
    required this.child,
  });

  final String raw;
  final ValueChanged<String> onChanged;
  final String currency;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final keys = HardwareKeyboard.instance;
        if (keys.isMetaPressed || keys.isControlPressed || keys.isAltPressed) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey == LogicalKeyboardKey.backspace
            ? 'Backspace'
            : event.character;
        if (key == null) return KeyEventResult.ignored;
        final next = typeOnKeypad(raw, key, AmountFormat(locale, currency));
        if (next == null) return KeyEventResult.ignored;
        onChanged(next);
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}

/// The amount as the add sheet takes it, for any sheet: the big figure (with the muted lukas hint
/// in pesos), the numeric keypad under it, and a physical keyboard typing too.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.raw,
    required this.onChanged,
    required this.currency,
    this.sign = '',
    this.tone = AmountTone.neutral,
    this.invalid = false,
    this.compact = false,
  });

  final String raw;
  final ValueChanged<String> onChanged;
  final String currency;
  final String sign;
  final AmountTone tone;
  final bool invalid;

  /// The keypad's tighter keys (see [Keypad.compact]).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return AmountKeys(
      raw: raw,
      onChanged: onChanged,
      currency: currency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space2,
        children: [
          AmountDisplay(raw: raw, currency: currency, sign: sign, tone: tone, invalid: invalid),
          Keypad(
            value: raw,
            onChange: onChanged,
            locale: locale,
            currency: currency,
            compact: compact,
          ),
        ],
      ),
    );
  }
}
