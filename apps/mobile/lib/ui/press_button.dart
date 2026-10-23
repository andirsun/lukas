// The web's PressButton (apps/web/app/ui/PressButton.tsx) and the CSS it uses: app.css `.lk-btn`,
// `.lk-btn-primary`, `.lk-btn-secondary`, `.lk-btn-ghost`, `.lk-btn-sm`, and the disabled and
// ghost-press additions further down the same file.
import 'package:flutter/material.dart';

import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import 'lk_theme.dart';
import 'pressable.dart';

/// Which button: one `primary` per view; `secondary` for the alternative, `ghost` to skip or
/// dismiss (the web's `variant`).
enum PressTone { primary, secondary, ghost }

/// The button's size (the web's `size`): `md`, or the smaller `sm`.
enum PressSize { md, sm }

/// The pressable button (`lk-btn`): it sits on a solid bottom edge and sinks into it while pressed
/// (primary 5px, secondary 3px, ghost 2px, over 80 ms). At least 44px in both directions. Without
/// [onPressed] it is disabled: half as opaque, and it does not move.
///
/// [child] is the label. The web writes it in upper case through CSS (`text-transform`), which
/// Flutter has not: [PressButton.text] does it for a string.
class PressButton extends StatelessWidget {
  const PressButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tone = PressTone.primary,
    this.size = PressSize.md,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.link = false,
  });

  /// A button whose label is [label], in upper case as the web shows it.
  PressButton.text(
    String label, {
    super.key,
    this.onPressed,
    this.tone = PressTone.primary,
    this.size = PressSize.md,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.link = false,
  }) : child = Text(LkText.upperCase(label));

  final Widget child;

  /// Called on a tap or Enter/Space; null makes the button disabled.
  final VoidCallback? onPressed;

  final PressTone tone;
  final PressSize size;
  final FocusNode? focusNode;
  final bool autofocus;

  /// The accessible name, when the label's text is not it.
  final String? semanticLabel;

  /// A link, not a button, to assistive technology: for [PressLink].
  final bool link;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final sm = size == PressSize.sm;
    final radius = LkSurface.radius(sm ? LkRadius.lg : LkRadius.xl);
    final textStyle = (sm ? LkText.buttonSm : LkText.button).copyWith(
      color: tone == PressTone.primary ? colors.onBrand : colors.ink,
      decoration: tone == PressTone.ghost ? TextDecoration.underline : null,
      decorationColor: colors.ink,
    );
    final padding = switch ((tone, sm)) {
      (PressTone.ghost, false) => const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      (_, false) => const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      (_, true) => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    };

    return Pressable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      label: semanticLabel,
      link: link,
      builder: (context, state) {
        final pressed = state.pressed;
        final BoxDecoration decoration;
        final double dy;
        switch (tone) {
          case PressTone.primary:
            decoration = BoxDecoration(
              color: colors.brand,
              borderRadius: radius,
              boxShadow: LkSurface.brandEdge(lk, pressed: pressed),
            );
            dy = pressed ? 5 : 0;
          case PressTone.secondary:
            decoration = BoxDecoration(
              color: colors.surfaceRow,
              borderRadius: radius,
              border: Border.all(color: colors.controlEdge, width: 2),
              boxShadow: pressed ? LkSurface.pressedEdge(lk) : LkSurface.edgeShadow(lk, LkEdge.sm),
            );
            dy = pressed ? 3 : 0;
          case PressTone.ghost:
            decoration = BoxDecoration(borderRadius: radius);
            dy = pressed ? 2 : 0;
        }
        final surface = PressSurface(
          decoration: decoration,
          pressDy: dy,
          padding: padding,
          ringRadius: state.focusVisible ? radius : null,
          ringColor: colors.focus,
          child: DefaultTextStyle.merge(
            style: textStyle,
            textAlign: TextAlign.center,
            child: child,
          ),
        );
        // `.lk-btn:disabled { opacity: 0.5 }`.
        return state.enabled ? surface : Opacity(opacity: 0.5, child: surface);
      },
    );
  }
}
