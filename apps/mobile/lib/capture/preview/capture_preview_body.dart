import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../home/home_repository.dart' show HomeFailure;
import '../../home/home_widgets.dart' show QuietSpinner;
import '../../theme/text_styles.dart';
import '../../theme/tokens.g.dart';
import '../../ui/lk_theme.dart';
import '../../ui/press_button.dart';
import '../capture_session.dart';
import 'capture_card.dart';
import 'capture_unread.dart';

/// What the sheet shows once the sentence is read: what was heard, with "Cambiar frase", one card
/// per movement (each open to change) and one for every piece that could not be read. While home's
/// figures are not here yet, or failed, it says so instead (the categories and the currency are in
/// them).
class CapturePreviewBody extends StatelessWidget {
  const CapturePreviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final preview = session.preview;
    final data = session.home.data;
    if (data == null || preview == null) return _Unloaded(session: session);
    final l10n = session.l10n;
    final colors = context.lkColors;
    final cards = preview.cards;
    final categories = [
      for (final c in data.categories.values)
        if (!c.archived) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space2,
      children: [
        Row(
          spacing: LukitasTokens.space2,
          children: [
            Expanded(
              child: Text(
                preview.sentence,
                style: LkText.body.copyWith(color: colors.inkMuted, fontStyle: FontStyle.italic),
              ),
            ),
            PressButton.text(
              l10n.captureChangeSentence,
              key: const Key('capture.change'),
              tone: PressTone.ghost,
              size: PressSize.sm,
              onPressed: session.saving ? null : () => session.type(null, text: preview.sentence),
            ),
          ],
        ),
        for (var i = 0; i < cards.length; i++)
          CaptureCardView(
            key: ValueKey('card-${cards[i].id}'),
            index: i,
            card: cards[i],
            open: session.openCard == cards[i].id,
            categories: categories,
            currency: data.currency,
            today: preview.today,
            enabled: !session.saving,
            onToggle: () =>
                session.openCardOnly(session.openCard == cards[i].id ? null : cards[i].id),
            onPick: () => session.openCardOnly(cards[i].id),
            onRemove: () => preview.remove(cards[i].id),
            onChange: ({amount, kind, name, categoryId, date}) => preview.update(
              cards[i].id,
              amount: amount,
              kind: kind,
              name: name,
              categoryId: categoryId,
              date: date,
            ),
            onPicked: () => session.openCardOnly(null),
          ),
        for (var i = 0; i < preview.unread.length; i++)
          CaptureUnreadCard(
            key: Key('capture.unread.$i'),
            completeKey: Key('capture.unread.$i.complete'),
            fragment: preview.unread[i],
            enabled: !session.saving,
            onComplete: () {
              preview.complete(i);
              session.openCardOnly(preview.cards.last.id);
            },
          ),
      ],
    );
  }
}

/// Home has not answered yet (or could not): a spinner and a word, and Reintentar when it failed.
class _Unloaded extends StatelessWidget {
  const _Unloaded({required this.session});

  final CaptureSheetState session;

  @override
  Widget build(BuildContext context) {
    final l10n = session.l10n;
    final colors = context.lkColors;
    final HomeFailure? failure = session.home.failure;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LukitasTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: LukitasTokens.space3,
        children: [
          if (failure == null) const QuietSpinner(size: 28),
          Text(
            failure != null
                ? (failure.offline ? l10n.errorNetwork : l10n.errorGeneric)
                : l10n.homeLoading,
            textAlign: TextAlign.center,
            style: LkText.body.copyWith(color: colors.ink),
          ),
          if (failure != null)
            PressButton.text(
              l10n.retry,
              tone: PressTone.secondary,
              onPressed: () => unawaited(session.refreshHome()),
            ),
        ],
      ),
    );
  }
}
