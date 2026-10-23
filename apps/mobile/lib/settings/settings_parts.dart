// The parts of the web's Settings (apps/web/app/features/settings/parts.tsx) and the CSS they use:
// app.css `.lk-hero` (the card), `.lk-switch-row`, `.lk-switch` and `.lk-switch-thumb`.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';

import '../home/home_widgets.dart' show HeroCard;
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/css_text.dart';
import '../ui/lk_theme.dart';
import '../ui/pixel_snap.dart';
import '../ui/pressable.dart';

/// A card of settings named by its heading (`SettingsSection`): `lk-hero`, 16px between what is in
/// it, the title in Fredoka 20 and, under it, a muted line on what the card is for.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, this.lead, required this.children});

  final String title;
  final String? lead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final titleStyle = LkText.sectionTitle.copyWith(color: colors.ink);
    final leadStyle = LkText.bodySm.copyWith(color: colors.inkMuted);
    final lead = this.lead;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: title,
      child: HeroCard(
        padding: const EdgeInsets.fromLTRB(
          LukitasTokens.space4,
          LukitasTokens.space3,
          LukitasTokens.space4,
          LukitasTokens.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LukitasTokens.space4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: LukitasTokens.space1,
              children: [
                Semantics(header: true, child: CssParagraph(title, style: titleStyle)),
                if (lead != null) CssParagraph(lead, style: leadStyle),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// The name of one setting and, under it, a muted line on what it does (`SettingLabel`).
class SettingLabel extends StatelessWidget {
  const SettingLabel({super.key, required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final labelStyle = LkText.body.copyWith(color: colors.ink);
    final hintStyle = LkText.fieldLabel.copyWith(color: colors.inkMuted);
    final hint = this.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: LukitasTokens.space1,
      children: [
        CssParagraph(label, style: labelStyle),
        if (hint != null) CssParagraph(hint, style: hintStyle),
      ],
    );
  }
}

/// One choice of a [Choices].
class Choice<T> {
  const Choice(this.value, this.label, {this.key});

  final T value;
  final String label;

  /// Finds this choice's label (tests).
  final Key? key;
}

/// One choice among a few (language, theme), as the web's native radios in a fieldset named by its
/// legend: the arrow keys move between them, only the chosen one is in the tab order, and the
/// chosen one is outlined in gold (`Choices`).
class Choices<T> extends StatefulWidget {
  const Choices({
    super.key,
    required this.legend,
    this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String legend;
  final String? hint;
  final T value;
  final List<Choice<T>> options;
  final ValueChanged<T> onChanged;

  @override
  State<Choices<T>> createState() => _ChoicesState<T>();
}

class _ChoicesState<T> extends State<Choices<T>> {
  final _nodes = <T, FocusNode>{};

  FocusNode _node(T value) =>
      _nodes.putIfAbsent(value, () => FocusNode(debugLabel: 'choice $value'));

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _select(T value) {
    _node(value).requestFocus();
    widget.onChanged(value);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final options = widget.options;
    final current = options.indexWhere((o) => o.value == widget.value);
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.arrowDown => 1,
      _ => null,
    };
    if (step == null) return KeyEventResult.ignored;
    _select(options[(current + step + options.length) % options.length].value);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final hint = widget.hint;
    final hintStyle = LkText.fieldLabel.copyWith(color: colors.inkMuted);
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: widget.legend,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LukitasTokens.space2,
          children: [
            ExcludeSemantics(child: SettingLabel(label: widget.legend)),
            Row(
              spacing: LukitasTokens.space2,
              children: [
                for (final option in widget.options)
                  Expanded(
                    child: _Option(
                      label: option.label,
                      labelKey: option.key,
                      selected: option.value == widget.value,
                      focusNode: _node(option.value)..skipTraversal = option.value != widget.value,
                      onPressed: () => _select(option.value),
                    ),
                  ),
              ],
            ),
            if (hint != null) CssParagraph(hint, style: hintStyle),
          ],
        ),
      ),
    );
  }
}

/// One radio, drawn as its label (`OPTION` in parts.tsx): 44px at least, `surface-row` with a 2px
/// `stroke` border and `edge-sm`; chosen, the border is `brand-glow`, the text `ink` and a 3px
/// `gold` outline stands 1px off it; with the keyboard on it, a 3px `focus` outline 2px off.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.labelKey,
    required this.selected,
    required this.focusNode,
    required this.onPressed,
  });

  final String label;
  final Key? labelKey;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final radius = LkSurface.radius(LkRadius.md);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onPressed,
        selected: selected,
        checked: selected,
        focusNode: focusNode,
        builder: (context, state) {
          final ring = state.focusVisible
              ? (colors.focus, 2.0)
              : selected
              ? (colors.gold, 1.0)
              : null;
          return RingBox(
            radius: ring == null ? null : radius,
            color: ring?.$1 ?? const Color(0x00000000),
            offset: ring?.$2 ?? 2,
            child: SnappedDecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRow,
                borderRadius: radius,
                border: Border.all(color: selected ? colors.brandGlow : colors.stroke, width: 2),
                boxShadow: LkSurface.edgeShadow(lk, LkEdge.sm),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space2),
                  child: Center(
                    child: Text(
                      label,
                      key: labelKey,
                      textAlign: TextAlign.center,
                      style: LkText.bodySm.copyWith(color: selected ? colors.ink : colors.inkMuted),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// An on/off setting: the whole row is one switch, named by its label (`SettingSwitch`).
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final labelStyle = LkText.body.copyWith(color: colors.ink);
    // The hint says `font-normal` (400), but the web loads Nunito from 600 up (fonts.ts), so the
    // browser draws its nearest face, 600.
    final hintStyle = LkText.fieldLabel.copyWith(
      color: colors.inkMuted,
      fontWeight: FontWeight.w600,
    );
    final hint = this.hint;
    return Pressable(
      onPressed: () => onChanged(!value),
      toggled: value,
      label: label,
      hint: hint,
      builder: (context, state) => RingBox(
        // `.lk-switch-row:focus-visible { outline: 3px solid var(--focus); outline-offset: 4px }`
        radius: state.focusVisible ? LkSurface.radius(LkRadius.md) : null,
        color: colors.focus,
        offset: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            spacing: LukitasTokens.space3,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: LukitasTokens.space1,
                  children: [
                    CssParagraph(label, style: labelStyle),
                    if (hint != null) CssParagraph(hint, style: hintStyle),
                  ],
                ),
              ),
              LkSwitch(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// The switch itself (`.lk-switch`): a 52 × 30 pill with a 2px border and a 20px thumb that slides
/// 22px, `brand` and white when on, `ink-muted` on the sunken surface when off.
class LkSwitch extends StatelessWidget {
  const LkSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : LukitasTokens.durationPress;
    final border = value ? colors.brand : colors.inkMuted;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.ease,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          color: value ? colors.brand : colors.surfaceSunken,
          borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
          border: Border.all(color: border, width: 2),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: duration,
              curve: Curves.ease,
              left: value ? 3 + 22 : 3,
              top: 3,
              width: 20,
              height: 20,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.ease,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? colors.onBrand : colors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
