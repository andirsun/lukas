import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../home/lukitas_face.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/lukas_bubble.dart';
import '../ui/press_button.dart';
import '../ui/web_text_field.dart';
import 'capture_session.dart';

/// The typing field, for when nothing listens (the person chose to type, or could not be heard):
/// Lukas asks his question in the bubble, or says why the field shows, and under him is the
/// sentence's box, in the web's input.
class CaptureTypingBody extends StatelessWidget {
  const CaptureTypingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    final colors = context.lkColors;
    final why = session.why;
    final message = switch (why) {
      CaptureWhy.micDenied => l10n.captureMicDenied,
      CaptureWhy.noEngine => l10n.captureNoEngine,
      CaptureWhy.noVoiceYet => l10n.captureNoVoiceYet,
      CaptureWhy.listenFailed => l10n.captureListenFailed,
      CaptureWhy.nothingHeard => l10n.captureNothingHeard,
      CaptureWhy.nothingRead => l10n.captureNothingRead,
      null => l10n.captureListeningPrompt,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space3,
      children: [
        KeyedSubtree(
          key: why == null ? null : const Key('capture.note'),
          child: LukasBubble(
            message: message,
            // Something that did not work worries him; asking is not.
            mood: why == null ? LukitasMood.happy : LukitasMood.worried,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space1,
          children: [
            Text(l10n.captureFieldLabel, style: LkText.fieldLabel.copyWith(color: colors.inkMuted)),
            WebTextField(
              controller: session.field,
              focusNode: session.fieldFocus,
              fieldKey: const Key('capture.field'),
              label: l10n.captureFieldLabel,
              placeholder: l10n.captureFieldHint,
              maxLines: 3,
              enableSuggestions: true,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => session.readTyped(),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Hablar" (listen, when the phone can) and "Leer" (read the sentence into cards).
class CaptureTypingActions extends StatelessWidget {
  const CaptureTypingActions({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    return Row(
      spacing: LukitasTokens.space2,
      children: [
        if (session.canListen)
          PressButton.text(
            l10n.captureListen,
            key: const Key('capture.listen'),
            tone: PressTone.secondary,
            horizontalPadding: LukitasTokens.space4,
            onPressed: session.listen,
          ),
        Expanded(
          child: PressButton.text(
            l10n.captureRead,
            key: const Key('capture.read'),
            horizontalPadding: LukitasTokens.space4,
            onPressed: session.readTyped,
          ),
        ),
      ],
    );
  }
}
