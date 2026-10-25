import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/press_button.dart';
import 'capture_session.dart';
import 'preview/capture_card.dart';

/// The voice, as a card: a tile with a microphone, [title] over [children].
class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.title, required this.children, this.outline});

  final Widget title;
  final List<Widget> children;
  final Color? outline;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: captureCardBox(context.lk, outline: outline),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          const CaptureTile(glyph: '🎙️'),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: LukitasTokens.space2,
              children: [title, ...children],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The opt-in to download the voice: what it is for, the size it takes (shown before anything is
/// downloaded, so it is the person's choice), and, after a download that did not work, why.
class CaptureOfferBody extends StatelessWidget {
  const CaptureOfferBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    final colors = context.lkColors;
    final model = session.model;
    final megabytes = (model.bytes / 1e6).round();
    final failure = session.downloadFailure;
    return _VoiceCard(
      outline: failure == null ? null : colors.over,
      title: Text(
        l10n.captureOfferTitle,
        style: LkText.body.copyWith(color: colors.ink, fontWeight: FontWeight.w900),
      ),
      children: [
        Text(l10n.captureOfferBody(megabytes), style: LkText.body.copyWith(color: colors.inkMuted)),
        if (failure != null)
          Semantics(
            liveRegion: true,
            child: Text(
              failure.noSpace
                  ? l10n.captureDownloadNoSpace(((model.bytes + model.unzippedBytes) / 1e6).round())
                  : failure.corrupt
                  ? l10n.captureDownloadCorrupt
                  : l10n.captureDownloadFailed,
              style: LkText.label.copyWith(color: colors.over),
            ),
          ),
      ],
    );
  }
}

/// "Descargar N MB" (or "Reintentar" after a failure) and "Ahora no, escribo".
class CaptureOfferActions extends StatelessWidget {
  const CaptureOfferActions({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    final megabytes = (session.model.bytes / 1e6).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space1,
      children: [
        PressButton(
          key: const Key('capture.offer.download'),
          horizontalPadding: LukitasTokens.space4,
          onPressed: () => unawaited(session.downloadModel()),
          child: Text(
            LkText.upperCase(
              session.downloadFailure == null ? l10n.captureOfferDownload(megabytes) : l10n.retry,
            ),
          ),
        ),
        PressButton.text(
          l10n.captureOfferDecline,
          key: const Key('capture.offer.decline'),
          tone: PressTone.ghost,
          onPressed: () => session.type(null),
        ),
      ],
    );
  }
}

/// The download under way: how far it is, in words (read out as it changes) and on a bar.
class CaptureDownloadingBody extends StatelessWidget {
  const CaptureDownloadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    final colors = context.lkColors;
    final total = session.model.bytes;
    final fraction = total == 0 ? 0.0 : (session.downloaded / total).clamp(0.0, 1.0);
    return _VoiceCard(
      title: Semantics(
        liveRegion: true,
        child: Text(
          l10n.captureDownloading((fraction * 100).floor()),
          style: LkText.body.copyWith(color: colors.ink, fontWeight: FontWeight.w900),
        ),
      ),
      children: [_ProgressTrack(fraction: fraction)],
    );
  }
}

/// "Cancelar": the download stops, and the offer comes back.
class CaptureDownloadingActions extends StatelessWidget {
  const CaptureDownloadingActions({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    return PressButton.text(
      session.l10n.captureDownloadCancel,
      key: const Key('capture.download.cancel'),
      tone: PressTone.secondary,
      horizontalPadding: LukitasTokens.space4,
      onPressed: session.cancelDownload,
    );
  }
}

/// The web's bar (`.lk-bar`: a sunken pill 12px tall) filled with the brand colour as the download
/// goes on; it follows over `--count-up`, or at once with "remove animations".
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : LukitasTokens.durationCountUp;
    const radius = BorderRadius.all(Radius.circular(LukitasTokens.radiusPill));
    return ExcludeSemantics(
      child: SizedBox(
        height: 12,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: radius),
          child: ClipRRect(
            borderRadius: radius,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: duration,
              curve: Curves.easeOut,
              builder: (context, value, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: colors.brand, borderRadius: radius),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
