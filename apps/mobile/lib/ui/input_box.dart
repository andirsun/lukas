// The box of the web's text fields: app.css `.lk-input` (and `.lk-input:focus-within`).
import 'package:flutter/material.dart';

import '../theme/surfaces.dart';
import 'lk_theme.dart';
import 'pressable.dart';

/// A sunken field box: 44px at least, a 2px `stroke` border, `radius-md`, and 12px by 9px of room
/// inside the border. While [focused] it wears the focus ring (`outline: 3px solid var(--focus);
/// outline-offset: 2px`).
class InputBox extends StatelessWidget {
  const InputBox({
    super.key,
    required this.child,
    this.focused = false,
    this.alignment = Alignment.centerLeft,
    this.borderColor,
  });

  final Widget child;
  final bool focused;

  /// The border's colour: the theme's `stroke`, or `over` on a field with a mistake
  /// (`border-over`).
  final Color? borderColor;

  /// Where [child] sits when the box is taller than it.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final radius = LkSurface.radius(LkRadius.md);
    return RingBox(
      radius: focused ? radius : null,
      color: colors.focus,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: radius,
            border: Border.all(color: borderColor ?? colors.stroke, width: 2),
          ),
          child: Padding(
            // 12px by 9px inside the 2px border.
            padding: const EdgeInsets.symmetric(horizontal: 12 + 2, vertical: 9 + 2),
            child: Align(alignment: alignment, widthFactor: null, child: child),
          ),
        ),
      ),
    );
  }
}
