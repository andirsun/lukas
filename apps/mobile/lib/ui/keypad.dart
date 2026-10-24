// The web's Keypad (apps/web/app/ui/Keypad.tsx) and the CSS it uses: app.css `.lk-keys` and
// `.lk-key` (and its press), and the tighter keys of a short phone's sheet.
import 'package:flutter/material.dart';

import '../add/keypad_input.dart';
import '../feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import 'lk_theme.dart';
import 'pressable.dart';

/// The add sheet's numeric keypad: digits, the language's decimal key (`,` es, `.` en; none for
/// whole-unit currencies, which have no fractional pesos) and backspace. It edits the raw text
/// [value] and reports every change through [onChange]; a key that would not change it (a third
/// decimal, a second separator, past the cap) is ignored. The rules for what a key does are in
/// `lib/add/keypad_input.dart`.
///
/// Each key sits on a solid edge and sinks into it while pressed (`.lk-key`). A key counts on the
/// release of a tap: a finger that starts on a key and drags (to pull the sheet down) types
/// nothing.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.value,
    required this.onChange,
    required this.locale,
    this.currency,
    this.compact = false,
    this.currentValue,
  });

  /// The raw text typed so far (`6,08` in es, `6.08` in en).
  final String value;
  final ValueChanged<String> onChange;

  /// `es` or `en`.
  final String locale;

  /// ISO 4217 code. Whole-unit currencies (COP, CLP) get no decimal key. Without one, decimals are
  /// allowed.
  final String? currency;

  /// The keys of a phone up to 844 px tall (`.lk-sheet.has-footer .lk-key { padding: 4px 0 }`, a
  /// 4px gap): still 44px targets, so the whole sheet fits.
  final bool compact;

  /// What the text is right now, for a key pressed before the screen has caught up with the last
  /// one (two taps within a frame): without it [value], as of the last build.
  final ValueGetter<String>? currentValue;

  void _press(BuildContext context, KeypadKey key) {
    context.feedback(FeedbackEvent.keyPressed);
    final now = currentValue?.call() ?? value;
    final next = pressKey(now, key, AmountFormat(locale, currency));
    if (next != now) onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gap = compact ? 4.0 : 6.0;
    _Spec digit(String d) => _Spec('keypad.$d', d, null, DigitKey(d));
    final rows = <List<_Spec?>>[
      [digit('1'), digit('2'), digit('3')],
      [digit('4'), digit('5'), digit('6')],
      [digit('7'), digit('8'), digit('9')],
      [
        takesDecimals(currency)
            ? _Spec(
                'keypad.decimal',
                decimalSeparator(locale),
                l10n.keypadDecimal,
                const DecimalKey(),
              )
            : null,
        digit('0'),
        _Spec('keypad.backspace', '⌫', l10n.keypadBackspace, const BackspaceKey()),
      ],
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.keypadLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Three equal columns, their edges on whole device pixels as Chrome draws them.
          final track = snappedColumns(
            constraints.maxWidth,
            3,
            gap,
            MediaQuery.devicePixelRatioOf(context),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: [
              for (final row in rows)
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) SizedBox(width: track[3 + i - 1]),
                      SizedBox(
                        width: track[i],
                        child: row[i] == null
                            ? const ExcludeSemantics(child: SizedBox.shrink())
                            : _KeyButton(
                                spec: row[i]!,
                                compact: compact,
                                textShift: track[5 + i],
                                onPressed: () => _press(context, row[i]!.key),
                              ),
                      ),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Spec {
  const _Spec(this.id, this.text, this.label, this.key);

  final String id;
  final String text;
  final String? label;
  final KeypadKey key;
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.spec,
    required this.onPressed,
    required this.compact,
    required this.textShift,
  });

  final _Spec spec;
  final bool compact;

  /// How far Chrome's rounding of the key's edges moved its centre: the text stays where the
  /// unrounded box puts it.
  final double textShift;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final radius = LkSurface.radius(LkRadius.sm);
    return Pressable(
      key: Key(spec.id),
      onPressed: onPressed,
      label: spec.label,
      builder: (context, state) {
        final pressed = state.pressed;
        return PressSurface(
          pressDy: pressed ? 3 : 0,
          padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
          decoration: BoxDecoration(
            color: pressed ? colors.keyPressed : colors.key,
            borderRadius: radius,
            border: Border.all(color: colors.keyBorder, width: 2),
            // `0 3px 0 var(--key-edge)`, `0 1px 0` while pressed.
            boxShadow: [BoxShadow(color: colors.keyEdge, offset: Offset(0, pressed ? 1 : 3))],
          ),
          ringRadius: state.focusVisible ? radius : null,
          ringColor: colors.focus,
          child: Transform.translate(
            offset: Offset(textShift, cssBaselineShift(LkText.key)),
            child: Text(spec.text, style: LkText.key.copyWith(color: colors.ink)),
          ),
        );
      },
    );
  }
}
