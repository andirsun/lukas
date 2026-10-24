import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/text_styles.dart';
import '../../ui/lk_theme.dart';
import '../../ui/press_button.dart';
import 'capture_card.dart';

/// A piece of the sentence the parser could not read, as a card in the amber of what is waiting
/// for the person: what was heard of it ("No entendí: «…»") and "Completar", which turns it into a
/// movement to fill in by hand.
class CaptureUnreadCard extends StatelessWidget {
  const CaptureUnreadCard({
    super.key,
    required this.fragment,
    required this.enabled,
    required this.onComplete,
    required this.completeKey,
  });

  final String fragment;
  final bool enabled;
  final VoidCallback onComplete;
  final Key completeKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lk = context.lk;
    final style = LkText.label.copyWith(leadingDistribution: TextLeadingDistribution.even);
    return DecoratedBox(
      decoration: captureCardBox(lk, outline: lk.colors.near),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
        child: Row(
          spacing: 10,
          children: [
            const CaptureTile(glyph: '🤔'),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    l10n.captureUnread(fragment),
                    style: style.copyWith(color: lk.colors.near),
                  ),
                ),
              ),
            ),
            PressButton.text(
              l10n.captureComplete,
              key: completeKey,
              tone: PressTone.secondary,
              size: PressSize.sm,
              onPressed: enabled ? onComplete : null,
            ),
          ],
        ),
      ),
    );
  }
}
