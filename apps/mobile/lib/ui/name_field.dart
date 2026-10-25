// The web's NameField (apps/web/app/ui/NameField.tsx) and the CSS it uses: app.css `.lk-input`,
// `.lk-shortcuts`, `.lk-shortcut`, `.lk-shortcut.is-hit`, and the shortcut button's press and focus.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'css_text.dart';
import 'lk_theme.dart';
import 'pressable.dart';

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
/// shortcut is labelled with its category; the one matching the current name is marked.
///
/// Only the two rows of shortcuts that fit show (the most used first), so the categories under the
/// field stay in view; the rest are out of sight and out of the tab order.
class NameField extends StatefulWidget {
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

  /// What the name will be when the field stays empty: the selected category's name.
  final String placeholder;

  /// Recent names, already filtered for what is typed (most used first).
  final List<NameChoice> suggestions;
  final ValueChanged<String> onChanged;

  /// A shortcut was tapped: the caller fills the name and selects its category.
  final ValueChanged<NameChoice> onPick;

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(NameField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final controller = widget.controller;
    final query = controller.text.trim().toLowerCase();
    bool isHit(NameChoice s) => query.isNotEmpty && s.name.toLowerCase() == query;
    final typing = query.isNotEmpty && !widget.suggestions.any(isHit);
    final radius = LkSurface.radius(LkRadius.md);

    final field = RingBox(
      radius: widget.focusNode.hasFocus ? radius : null,
      color: colors.focus,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: radius,
            border: LkSurface.border(colors),
          ),
          child: Padding(
            // 12px by 9px inside the 2px border.
            padding: const EdgeInsets.symmetric(horizontal: 12 + 2, vertical: 9 + 2),
            child: Row(
              spacing: LukitasTokens.space2,
              children: [
                ExcludeSemantics(
                  child: CssText(
                    TextSpan(
                      text: '✏️',
                      style: LkText.input.copyWith(color: colors.ink),
                    ),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    label: l10n.nameFieldLabel,
                    textField: true,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        if (controller.text.isEmpty)
                          IgnorePointer(
                            child: BlinkLine(
                              style: LkText.input,
                              child: Text(
                                widget.placeholder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LkText.input.copyWith(
                                  color: colors.inkMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        Transform.translate(
                          offset: Offset(0, cssBaselineShift(LkText.input)),
                          child: EditableText(
                            key: const Key('add.name'),
                            controller: controller,
                            focusNode: widget.focusNode,
                            onChanged: widget.onChanged,
                            style: LkText.input.copyWith(color: colors.ink),
                            cursorColor: colors.ink,
                            backgroundCursorColor: colors.inkMuted,
                            selectionColor: colors.brand.withValues(alpha: 0.4),
                            maxLines: 1,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [LengthLimitingTextInputFormatter(120)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space1,
      children: [
        field,
        if (widget.suggestions.isNotEmpty)
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: l10n.nameFieldSuggestions,
            child: LayoutBuilder(
              builder: (context, constraints) {
                TextSpan spanOf(NameChoice s) => TextSpan(
                  style: LkText.shortcut.copyWith(color: colors.ink),
                  children: [
                    TextSpan(text: s.name),
                    if (typing)
                      TextSpan(
                        text: ' · ${s.categoryName}',
                        style: TextStyle(color: colors.inkMuted),
                      ),
                    if (isHit(s)) const TextSpan(text: ' ✓'),
                  ],
                );
                // The pill: 10px padding and a 2px border each side, a button at least 44 wide.
                final texts = [
                  for (final s in widget.suggestions) CssText.widthOf(context, spanOf(s)),
                ];
                final widths = [for (final w in texts) w + 2 * (10 + 2) < 44 ? 44.0 : w + 24];
                final count = shortcutsThatFit(
                  widths,
                  constraints.maxWidth,
                  maxRows: maxShortcutRows,
                );
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < count; i++)
                      _Shortcut(
                        key: Key('shortcut.${widget.suggestions[i].name}'),
                        text: spanOf(widget.suggestions[i]),
                        label:
                            '${widget.suggestions[i].name}${typing ? ' · ${widget.suggestions[i].categoryName}' : ''}',
                        hit: isHit(widget.suggestions[i]),
                        onPressed: () => widget.onPick(widget.suggestions[i]),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// `.lk-shortcut-button` around `.lk-shortcut`: a 44px button, and inside it the pill, which sits
/// on a solid edge, sinks while pressed and takes the focus ring.
class _Shortcut extends StatelessWidget {
  const _Shortcut({
    super.key,
    required this.text,
    required this.label,
    required this.hit,
    required this.onPressed,
  });

  final TextSpan text;

  final String label;
  final bool hit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    const radius = BorderRadius.all(Radius.circular(LukitasTokens.radiusPill));
    return Pressable(
      onPressed: onPressed,
      selected: hit,
      label: label,
      builder: (context, state) {
        final pressed = state.pressed;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: PressSurface(
              minSize: 0,
              pressDy: pressed ? 3 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surfaceRow,
                borderRadius: radius,
                border: Border.all(color: hit ? colors.brand : colors.stroke, width: 2),
                boxShadow: pressed
                    ? LkSurface.pressedEdge(lk)
                    : LkSurface.edgeShadow(lk, LkEdge.sm),
              ),
              ringRadius: state.focusVisible ? radius : null,
              ringColor: colors.focus,
              child: BlinkLine(style: LkText.shortcut, child: CssText(text)),
            ),
          ),
        );
      },
    );
  }
}
