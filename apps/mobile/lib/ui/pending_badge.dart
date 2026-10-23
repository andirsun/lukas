// The web's PendingBadge (apps/web/app/ui/PendingBadge.tsx) and the CSS it uses: app.css
// `.lk-badge`, `.lk-badge.is-paid`, and the utilities on its button and pill.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import 'lk_theme.dart';
import 'pressable.dart';

enum _Status { idle, paying, paid }

/// "Pendiente" on a scheduled, unpaid transaction, and the button that pays it. The visible pill
/// keeps the design's size; the button around it is a 44px target. While paying it is busy and
/// once paid it is inert, so a transaction is never paid twice from here.
class PendingBadge extends StatefulWidget {
  const PendingBadge({super.key, required this.onPay, this.paid = false});

  /// Marks the transaction paid. Resolving turns the badge into "✓ Pagado"; rejecting puts it back
  /// to "Pendiente" (the caller reports the error, e.g. with a toast).
  final Future<void> Function() onPay;

  /// Already paid elsewhere (a swipe on the row): shows "✓ Pagado" and is inert.
  final bool paid;

  @override
  State<PendingBadge> createState() => _PendingBadgeState();
}

class _PendingBadgeState extends State<PendingBadge> {
  var _status = _Status.idle;

  Future<void> _pay() async {
    if (_status != _Status.idle || widget.paid) return;
    setState(() => _status = _Status.paying);
    try {
      await widget.onPay();
      if (mounted) setState(() => _status = _Status.paid);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lk = context.lk;
    final colors = lk.colors;
    final paid = _status == _Status.paid || widget.paid;
    final tone = paid ? colors.good : colors.near;
    const radius = BorderRadius.all(Radius.circular(999));
    final text = LkText.badge.copyWith(color: tone);

    return Pressable(
      onPressed: _pay,
      label: paid ? null : l10n.pendingPayLabel,
      liveRegion: true,
      builder: (context, state) {
        // `shadow-[0_2px_0_var(--surface-edge)]` at rest, none while pressed; `group-active:
        // translate-y-0.5` (2px). A paid badge is inert: no edge, no press.
        final pressed = state.pressed && !paid;
        final pill = PressSurface(
          minSize: 0,
          pressDy: pressed ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: radius,
            // `border: 1.5px solid`, which Chrome lays out as 1px (it floors a border to whole CSS
            // pixels: the badge measures 20.25px tall, not 21.25).
            border: Border.all(color: tone, width: 1),
          ),
          outsideShadow: paid || pressed
              ? const []
              : [BoxShadow(color: colors.surfaceEdge, offset: const Offset(0, 2))],
          ringRadius: state.focusVisible ? radius : null,
          ringColor: colors.focus,
          child: DefaultTextStyle.merge(
            style: text,
            // See [letterSpacingShift].
            child: Transform.translate(
              offset: Offset(letterSpacingShift(context, text.letterSpacing!), 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  if (paid)
                    BlinkLine(
                      style: LkText.badge,
                      child: Text('✓', style: text),
                    ),
                  BlinkLine(
                    style: LkText.badge,
                    child: Text(LkText.upperCase(paid ? l10n.paid : l10n.pending), style: text),
                  ),
                ],
              ),
            ),
          ),
        );
        // The pill sits in the middle of a 44px target (`min-h-11 min-w-11`).
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(widthFactor: 1, heightFactor: 1, child: pill),
        );
      },
    );
  }
}
