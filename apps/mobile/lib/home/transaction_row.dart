import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'category_look.dart';

/// "Pendiente" on a scheduled, unpaid transaction, and the button that pays it. Paying shows the
/// badge busy; once paid it says "✓ Pagado" and is inert, so a transaction is never paid twice from
/// here. A payment that fails puts it back to "Pendiente" (the caller reports the error).
class PendingBadge extends StatefulWidget {
  const PendingBadge({super.key, required this.onPay, this.paid = false});

  /// Marks the transaction paid. Rejecting puts the badge back.
  final Future<void> Function() onPay;

  /// Already paid elsewhere (a swipe on the row): "✓ Pagado", inert.
  final bool paid;

  @override
  State<PendingBadge> createState() => _PendingBadgeState();
}

enum _Pay { idle, paying, paid }

class _PendingBadgeState extends State<PendingBadge> {
  _Pay _status = _Pay.idle;

  Future<void> _pay() async {
    if (_status != _Pay.idle || widget.paid) return;
    setState(() => _status = _Pay.paying);
    try {
      await widget.onPay();
      if (mounted) setState(() => _status = _Pay.paid);
    } catch (_) {
      if (mounted) setState(() => _status = _Pay.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final paid = _status == _Pay.paid || widget.paid;
    final color = paid ? colors.good : colors.near;
    return Semantics(
      button: !paid,
      liveRegion: true,
      label: paid ? l10n.paid : l10n.pendingPayLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pay,
        // The pill keeps the design's size; the area around it is the touch target.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
            ),
            child: Text(
              paid ? '✓ ${l10n.paid}'.toUpperCase() : l10n.pending.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One transaction: its category's glyph, name (or its category's name), category and amount (a
/// real minus sign for expenses; `+` in the good color for income). The card opens the editor; a
/// pending row carries its own [PendingBadge]. The web's `TransactionRow`.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    required this.locale,
    this.paidHere = false,
    this.onOpen,
    this.onPay,
  });

  final Transaction transaction;

  /// Null when the category is unknown: the row then shows no name for it.
  final Category? category;
  final String currency;
  final String locale;

  /// Paid from this row just now: the badge stays ("✓ Pagado") although the status is already paid.
  final bool paidHere;

  /// Opens the edit sheet.
  final VoidCallback? onOpen;

  /// Marks a pending transaction paid. Without it a pending row shows a plain label.
  final Future<void> Function()? onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final text = Theme.of(context).textTheme;
    final tx = transaction;
    final look = category == null
        ? null
        : categoryLook(icon: category!.icon, color: category!.color);
    final categoryName = category?.name ?? '';
    final title = tx.name.trim().isEmpty ? categoryName : tx.name.trim();
    final income = tx.amount > 0;
    final pending = tx.status == TransactionStatusEnum.pending;
    final amount = formatMoney(
      tx.amount,
      currency,
      locale,
      sign: income ? MoneySign.always : MoneySign.auto,
    );

    final badge = (pending || (paidHere && onPay != null))
        ? (onPay != null
              ? PendingBadge(onPay: onPay!, paid: !pending)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    l10n.pending.toUpperCase(),
                    style: TextStyle(
                      color: colors.near,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ))
        : null;

    return Semantics(
      container: true,
      button: onOpen != null,
      onTap: onOpen,
      child: Material(
        color: colors.surfaceRow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
          side: BorderSide(color: colors.stroke, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusSm),
                  ),
                  child: ExcludeSemantics(
                    child: Text(look?.glyph ?? '🏷️', style: const TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            amount,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: income ? colors.good : colors.ink,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: LukitasTokens.space2,
                        children: [
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors.inkMuted,
                            ),
                          ),
                          ?badge,
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
