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

/// Phones under 800px tall (`max-height: 799.98px`) get the add sheet's smaller amount, 28px.
const shortPhoneBelow = 800.0;
const shortAmountSize = 28.0;

/// How far the lukas hint's baseline sits above the figure's baseline: CSS `vertical-align: middle`
/// puts the middle of the hint's box on the parent's baseline plus half its x-height. The figure is
/// Fredoka, whose OS/2 `sxHeight` is 0.500 em, at [figureSize]; the hint is Nunito 14px, whose box
/// is `hhea` ascent 1.011 em and descent 0.353 em tall, so its middle is (1.011 - 0.353) / 2 em
/// above its own baseline. At 36px that is 9.0 - 4.606 = 4.39px.
double hintRaise(double figureSize) => figureSize * 0.500 / 2 - 14 * (1.011 - 0.353) / 2;

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
    final scope = LkSheetScope.maybeOf(context);
    final tight = scope?.hasFooter ?? false;
    // `@media (max-height: 799.98px) { .lk-sheet.has-footer .lk-sheet-amount { font-size: 28px } }`.
    final size = tight && MediaQuery.sizeOf(context).height < shortPhoneBelow
        ? shortAmountSize
        : LkText.display.fontSize!;
    final style = LkText.display.copyWith(
      color: color,
      fontSize: size,
      height: tight ? 1.15 : null,
    );
    final announced = _settled(hint == null ? text : '$text $hint');

    final display = Stack(
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
                    // `align-middle` (see [hintRaise]).
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Transform.translate(
                        offset: Offset(0, -hintRaise(size)),
                        child: Text(
                          hint,
                          style: LkText.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: null,
                            color: colors.inkMuted,
                            fontFeatures: const [],
                          ),
                        ),
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
    // `.lk-sheet:not(.has-footer) .lk-sheet-amount { padding: var(--space-1) var(--space-3) }`: in a
    // sheet that scrolls as a whole the figure has 4px above and below it (and is stuck at the top).
    return scope != null && !tight
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: LukitasTokens.space1),
            child: display,
          )
        : display;
  }
}

/// A physical keyboard and the clipboard type on the keypad (the web's `useAmountKeys`, a
/// listener on the document while the form is on screen): the digits, the language's decimal key and
/// Backspace, and Ctrl or Cmd with V to paste. The thousands separator is ignored (`15.000` in
/// Spanish is 15000) and pesos take no decimals (`keypad_input.dart`). It listens while the screen it
/// is on is the top one, and leaves the keys to a text field that has the focus.
///
/// [onNegative] is a minus typed or a negative amount pasted: a form that takes only positive
/// amounts says so and keeps the amount. Without it a typed `-` is ignored and a paste drops its
/// sign, as in the add sheet, whose sign comes from expense / income.
class AmountKeys extends StatefulWidget {
  const AmountKeys({
    super.key,
    required this.raw,
    required this.onChanged,
    required this.currency,
    required this.child,
    this.onNegative,
  });

  final String raw;
  final ValueChanged<String> onChanged;
  final String currency;
  final VoidCallback? onNegative;
  final Widget child;

  @override
  State<AmountKeys> createState() => _AmountKeysState();
}

class _AmountKeysState extends State<AmountKeys> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  AmountFormat get _format =>
      AmountFormat(Localizations.localeOf(context).languageCode, widget.currency);

  /// A text field has the keys (a name being typed, say).
  bool get _inField {
    final focus = FocusManager.instance.primaryFocus?.context;
    return focus != null &&
        (focus.widget is EditableText ||
            focus.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  bool _onKey(KeyEvent event) {
    if (!mounted || (ModalRoute.of(context)?.isCurrent ?? true) == false) return false;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final keys = HardwareKeyboard.instance;
    if (_inField) return false;
    if ((keys.isMetaPressed || keys.isControlPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyV) {
      unawaited(_paste());
      return true;
    }
    if (keys.isMetaPressed || keys.isControlPressed || keys.isAltPressed) return false;
    final negative = widget.onNegative;
    if (negative != null &&
        (event.logicalKey == LogicalKeyboardKey.minus ||
            event.logicalKey == LogicalKeyboardKey.numpadSubtract)) {
      negative();
      return true;
    }
    final key = event.logicalKey == LogicalKeyboardKey.backspace ? 'Backspace' : event.character;
    if (key == null) return false;
    final next = typeOnKeypad(widget.raw, key, _format);
    if (next == null) return false;
    widget.onChanged(next);
    return true;
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    final negative = widget.onNegative;
    if (negative != null && pastedNegative(text)) {
      negative();
      return;
    }
    final next = pasteAmount(text, _format);
    if (next != null) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
    this.onNegative,
  });

  final String raw;
  final ValueChanged<String> onChanged;
  final String currency;
  final String sign;
  final AmountTone tone;
  final bool invalid;

  /// The keypad's tighter keys (see [Keypad.compact]).
  final bool compact;

  /// A minus typed or a negative amount pasted (see [AmountKeys.onNegative]).
  final VoidCallback? onNegative;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return AmountKeys(
      raw: raw,
      onChanged: onChanged,
      currency: currency,
      onNegative: onNegative,
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
