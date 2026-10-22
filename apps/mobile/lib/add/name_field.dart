import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';

/// A recent name with the category it usually goes in.
class NameChoice {
  const NameChoice({required this.name, required this.categoryName, required this.source});

  final String name;
  final String categoryName;

  /// What the sheet gets back when this shortcut is tapped.
  final Object source;
}

/// At most this many rows of shortcuts, so the categories under the field stay in view.
const maxShortcutRows = 2;

/// How many shortcuts of [widths] fit in [maxRows] wrapped rows of [maxWidth], [spacing] apart.
/// Whatever does not fit is left out, never squeezed: the first ones are the most used.
int shortcutsThatFit(List<double> widths, double maxWidth, {double spacing = 6, int maxRows = 2}) {
  var row = 0;
  var x = 0.0;
  for (var i = 0; i < widths.length; i++) {
    final width = widths[i] > maxWidth ? maxWidth : widths[i];
    final next = x == 0 ? width : x + spacing + width;
    if (x > 0 && next > maxWidth) {
      row++;
      x = 0;
      if (row >= maxRows) return i;
      x = width;
    } else {
      x = next;
    }
  }
  return widths.length;
}

/// The transaction's optional name, with recent names as shortcuts under it. While typing, each
/// shortcut is labelled with its category; the one matching the current name is marked. The web's
/// `NameField`.
class NameField extends StatelessWidget {
  const NameField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.suggestions,
    required this.onChanged,
    required this.onPick,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// What the name will be when the field stays empty: the selected category's.
  final String placeholder;

  /// Recent names, already filtered for what is typed, most used first.
  final List<NameChoice> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<NameChoice> onPick;

  static const _chipStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);
  static const _padding = 10.0;
  static const _border = 2.0;
  static const _check = ' ✓';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final query = controller.text.trim().toLowerCase();
    bool isHit(NameChoice s) => query.isNotEmpty && s.name.toLowerCase() == query;
    final typing = query.isNotEmpty && !suggestions.any(isHit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.nameFieldLabel,
          textField: true,
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
              border: Border.all(color: colors.stroke, width: 2),
            ),
            child: Row(
              children: [
                const SizedBox(width: LukitasTokens.space3),
                const ExcludeSemantics(child: Text('✏️')),
                const SizedBox(width: LukitasTokens.space2),
                Expanded(
                  child: TextField(
                    key: const Key('add.name'),
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    maxLength: 120,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textInputAction: TextInputAction.done,
                    cursorColor: colors.brand,
                    style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      border: InputBorder.none,
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: colors.inkMuted,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: LukitasTokens.space3),
              ],
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Semantics(
            container: true,
            label: l10n.nameFieldSuggestions,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaler = MediaQuery.textScalerOf(context);
                final direction = Directionality.of(context);
                String textOf(NameChoice s) =>
                    '${s.name}${typing ? ' · ${s.categoryName}' : ''}${isHit(s) ? _check : ''}';
                double widthOf(NameChoice s) {
                  final painter = TextPainter(
                    text: TextSpan(text: textOf(s), style: _chipStyle),
                    textDirection: direction,
                    textScaler: scaler,
                    maxLines: 1,
                  )..layout();
                  // A hair of slack so a rounding difference never wraps a chip.
                  return painter.width.ceilToDouble() + 2 * (_padding + _border) + 1;
                }

                final widths = [for (final s in suggestions) widthOf(s)];
                final count = shortcutsThatFit(
                  widths,
                  constraints.maxWidth,
                  maxRows: maxShortcutRows,
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < count; i++)
                        _Shortcut(
                          key: Key('shortcut.${suggestions[i].name}'),
                          text: textOf(suggestions[i]),
                          width: widths[i].clamp(0, constraints.maxWidth),
                          hit: isHit(suggestions[i]),
                          onTap: () => onPick(suggestions[i]),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    super.key,
    required this.text,
    required this.width,
    required this.hit,
    required this.onTap,
  });

  final String text;
  final double width;
  final bool hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Semantics(
      button: true,
      selected: hit,
      label: text,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // A 40 px button around the 28 px pill.
        child: SizedBox(
          width: width,
          height: 40,
          child: Center(
            child: Container(
              width: width,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceRow,
                borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
                border: Border.all(color: hit ? colors.brand : colors.stroke, width: 2),
              ),
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: NameField._chipStyle.copyWith(color: colors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
