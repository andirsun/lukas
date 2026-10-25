import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../home/home_widgets.dart' show QuietSpinner;
import '../home/lukitas_face.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/lukas_bubble.dart';
import '../ui/press_button.dart';
import 'capture_session.dart';
import 'mic_level.dart';

/// While the microphone is open: Lukas asks "¿En qué gastaste?" in his bubble (once the engine is
/// ready, so no start of a sentence is lost; before, he says he is getting the microphone ready),
/// the input level moves in a sunken box under him, and what has been understood so far shows
/// underneath, growing as the person speaks.
class CaptureListeningBody extends StatelessWidget {
  const CaptureListeningBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    final colors = context.lkColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space3,
      children: [
        LukasBubble(
          message: session.ready ? l10n.captureListeningPrompt : l10n.capturePreparing,
          mood: LukitasMood.happy,
        ),
        CaptureWaves(ready: session.ready, levels: session.levels),
        // The explanation of where the voice goes, for the first use only.
        if (session.noteActive)
          Text(
            l10n.captureListeningNote,
            textAlign: TextAlign.center,
            style: LkText.label.copyWith(color: colors.inkMuted),
          ),
        // Room for two lines, so the sheet does not jump when the first words come.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(
              session.heard,
              key: const Key('capture.heard'),
              textAlign: TextAlign.center,
              style: LkText.body.copyWith(color: colors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

/// The microphone's level in a sunken box, `.lk-input`'s surface at the size of a card: the waves
/// of [MicLevel] while the engine listens, a spinner until it does.
class CaptureWaves extends StatelessWidget {
  const CaptureWaves({super.key, required this.ready, required this.levels});

  final bool ready;
  final Stream<double> levels;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: LkSurface.radius(LkRadius.lg),
        border: LkSurface.border(colors),
      ),
      child: SizedBox(
        height: 96,
        child: Center(
          child: ready
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: LukitasTokens.space3,
                  children: [
                    ExcludeSemantics(child: Icon(Icons.mic, size: 28, color: colors.brand)),
                    MicLevel(levels: levels),
                  ],
                )
              : const QuietSpinner(size: 32),
        ),
      ),
    );
  }
}

/// "Escribir" (the typing field instead) and "Listo" (stop and read what was said). While the
/// sheet is still starting they wait, so nothing can interrupt what has not begun.
class CaptureListeningActions extends StatelessWidget {
  const CaptureListeningActions({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    return Row(
      spacing: LukitasTokens.space2,
      children: [
        PressButton.text(
          l10n.captureTypeInstead,
          key: const Key('capture.type'),
          tone: PressTone.secondary,
          horizontalPadding: LukitasTokens.space4,
          onPressed: enabled ? () => session.type(null, text: session.heard) : null,
        ),
        Expanded(
          child: PressButton.text(
            l10n.captureStop,
            key: const Key('capture.stop'),
            horizontalPadding: LukitasTokens.space4,
            onPressed: enabled ? session.stopListening : null,
          ),
        ),
      ],
    );
  }
}
