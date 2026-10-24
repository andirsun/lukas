import 'package:flutter/widgets.dart';

import '../home/home_widgets.dart' show QuietSpinner;
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import '../ui/sheet.dart';
import 'capture_download.dart';
import 'capture_listening.dart';
import 'capture_save.dart';
import 'capture_session.dart';
import 'capture_typing.dart';
import 'preview/capture_preview_body.dart';

export 'capture_save.dart' show batchSavedFeedbackProvider;
export 'capture_session.dart'
    show CaptureLinkTarget, CaptureSheet, OpenCaptureSheets, openCaptureSheetsProvider;

/// Opens quick capture (spec section 6.1.4): 🎤 listens with "¿En qué gastaste?" (or, with
/// [listen] false, the typing field is ready), the preview shows one editable, removable card per
/// movement plus what could not be read, and "GUARDAR N" saves them all at once.
///
/// It needs only the app's providers (the home figures it reads the categories, currency and time
/// zone from, the API, the speech engine), no home screen state: the ＋'s neighbour on home calls
/// it, and so will the widget's deep link (Task 15). A save closes the sheet, updates home through
/// its controller and shows one celebration with the total and one Deshacer.
///
/// The sheet is [LkSheet], the web's, with capture's parts in it: what the stage shows scrolls
/// under the title, and what the person does next (stop, type, read, save, download) is pinned at
/// the bottom, in reach of the thumb. What the parts share is in [CaptureSheet], which wraps it.
Future<void> openCapture(BuildContext context, {bool listen = true}) => LkSheet.show<void>(
  context,
  title: AppLocalizations.of(context).captureTitle,
  wrap: (sheet) => CaptureSheet(listen: listen, child: sheet),
  children: const [CaptureBody()],
  footer: const [CaptureFooter()],
);

/// What the current stage shows, under the sheet's title.
class CaptureBody extends StatelessWidget {
  const CaptureBody({super.key});

  @override
  Widget build(BuildContext context) => switch (CaptureSession.of(context).stage) {
    CaptureStage.starting => const Padding(
      padding: EdgeInsets.all(LukitasTokens.space5),
      child: Center(child: QuietSpinner(size: 28)),
    ),
    CaptureStage.offer => const CaptureOfferBody(),
    CaptureStage.downloading => const CaptureDownloadingBody(),
    CaptureStage.listening => const CaptureListeningBody(),
    CaptureStage.typing => const CaptureTypingBody(),
    CaptureStage.preview => const CapturePreviewBody(),
  };
}

/// What the person does next, pinned at the bottom of the sheet.
class CaptureFooter extends StatelessWidget {
  const CaptureFooter({super.key});

  @override
  Widget build(BuildContext context) => switch (CaptureSession.of(context).stage) {
    CaptureStage.starting => const CaptureListeningActions(enabled: false),
    CaptureStage.offer => const CaptureOfferActions(),
    CaptureStage.downloading => const CaptureDownloadingActions(),
    CaptureStage.listening => const CaptureListeningActions(),
    CaptureStage.typing => const CaptureTypingActions(),
    CaptureStage.preview => const CaptureSaveFooter(),
  };
}
