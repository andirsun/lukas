// The web's PageHeader (apps/web/app/ui/PageHeader.tsx).
import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';
import 'press_button.dart';

/// The top of a screen inside the app that is not home: a back link (‹ Inicio) and, beside it,
/// what the screen browses by (the month picker, say). Under 400px the aside gets its own row,
/// like home's month.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.backLabel,
    required this.backShort,
    required this.onBack,
    this.aside,
  });

  /// How "back" reads to assistive technology: the accessible name contains the visible text.
  final String backLabel;

  /// The visible text of "back", e.g. "Inicio".
  final String backShort;

  /// Where "back" goes.
  final VoidCallback onBack;

  /// Beside the back link: the month picker, say.
  final Widget? aside;

  /// The web's link says `no-underline`, which a ghost button would otherwise have.
  static const _plain = TextStyle(decoration: TextDecoration.none);

  /// The web's `min-[400px]`, a width of the viewport.
  static const _wide = 400.0;

  @override
  Widget build(BuildContext context) {
    final aside = this.aside;
    final wide = MediaQuery.sizeOf(context).width >= _wide;
    final back = PressButton(
      onPressed: onBack,
      tone: PressTone.ghost,
      size: PressSize.sm,
      link: true,
      semanticLabel: backLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: LukitasTokens.space1,
        children: [
          const ExcludeSemantics(child: Text('‹', style: _plain)),
          Text(backShort.toUpperCase(), style: _plain),
        ],
      ),
    );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: LukitasTokens.space2,
      runSpacing: LukitasTokens.space1,
      children: [
        back,
        if (aside != null)
          wide
              ? aside
              : SizedBox(
                  width: double.infinity,
                  child: Center(child: aside),
                ),
      ],
    );
  }
}
