import 'package:flutter/material.dart';

import '../feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'keypad_input.dart';

/// The add sheet's numeric keypad: digits, the language's decimal key (`,` es, `.` en; none for
/// whole-unit currencies: there are no fractional pesos) and backspace. It only reports the key
/// pressed ([onKey]); the rules for what a key does are in `keypad_input.dart`.
///
/// A key counts on the release of a tap: a finger that starts on a key and drags (to pull the
/// sheet down) types nothing.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.locale,
    required this.currency,
    required this.onKey,
    this.keyHeight = 48,
  });

  /// `es` or `en`.
  final String locale;
  final String currency;
  final void Function(KeypadKey key) onKey;

  /// The height of a key, at least 40 for a touch target.
  final double keyHeight;

  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final decimals = takesDecimals(currency);
    Widget digit(String d) =>
        _Key(keyId: 'keypad.$d', label: d, height: keyHeight, onTap: () => onKey(DigitKey(d)));
    final rows = <List<Widget?>>[
      [digit('1'), digit('2'), digit('3')],
      [digit('4'), digit('5'), digit('6')],
      [digit('7'), digit('8'), digit('9')],
      [
        decimals
            ? _Key(
                keyId: 'keypad.decimal',
                label: decimalSeparator(locale),
                semanticLabel: l10n.keypadDecimal,
                height: keyHeight,
                onTap: () => onKey(const DecimalKey()),
              )
            : null,
        digit('0'),
        _Key(
          keyId: 'keypad.backspace',
          label: '⌫',
          semanticLabel: l10n.keypadBackspace,
          height: keyHeight,
          onTap: () => onKey(const BackspaceKey()),
        ),
      ],
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.keypadLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: _gap),
            Row(
              children: [
                for (var c = 0; c < rows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: _gap),
                  Expanded(child: rows[r][c] ?? SizedBox(height: keyHeight)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.keyId,
    required this.label,
    required this.height,
    required this.onTap,
    this.semanticLabel,
  });

  final String keyId;
  final String label;
  final String? semanticLabel;
  final double height;
  final VoidCallback onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    // The key sinks into its edge while pressed (the web's `.lk-key:active`).
    final sink = _pressed ? 3.0 : 0.0;
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        key: Key(widget.keyId),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapCancel: () => _press(false),
        onTapUp: (_) => _press(false),
        onTap: () {
          context.feedback(FeedbackEvent.keyPressed);
          widget.onTap();
        },
        child: SizedBox(
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Transform.translate(
              offset: Offset(0, sink),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _pressed ? colors.keyPressed : colors.key,
                  borderRadius: BorderRadius.circular(LukitasTokens.radiusSm),
                  border: Border.all(color: colors.keyBorder, width: 2),
                  boxShadow: [BoxShadow(color: colors.keyEdge, offset: Offset(0, 3 - sink))],
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
