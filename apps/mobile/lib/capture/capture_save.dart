import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add/add_sheet.dart' show canRetrySave;
import '../api/gen/lukitas_api.dart';
import '../feedback/feedback.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../home/home_widgets.dart' show QuietSpinner;
import '../home/saved_feedback.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/failure_row.dart';
import '../ui/press_button.dart';
import '../ui/toast.dart';
import 'capture_repository.dart';
import 'capture_session.dart';

/// Told about every batch saved, with its rows, once the month's figures include the whole batch.
/// By default the batch feels like any save: by kind and by the limit state after the batch (see
/// [savedFeedbackFor]), and Lukitas celebrates on home unless a category is near or over its limit,
/// like for a single save. The celebration line and Deshacer are the toast's. Tests replace it to
/// see what was saved.
final batchSavedFeedbackProvider = Provider<void Function(List<Transaction> saved)>(
  (ref) => (saved) {
    final data = ref.exists(homeProvider) ? ref.read(homeProvider).data : null;
    final event = savedFeedbackFor(data, saved);
    ref.read(feedbackProvider)(event);
    if (celebrates(event)) ref.read(celebrationProvider.notifier).celebrate();
  },
);

/// What is pinned under the preview: a refused or failed save, said above "Guardar N" (with
/// Reintentar when sending it again can work), and Guardar itself, which waits until every card
/// has an amount and a category.
class CaptureSaveFooter extends StatelessWidget {
  const CaptureSaveFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaptureSession.of(context);
    final l10n = session.l10n;
    final preview = session.preview;
    final failure = session.failure;
    final loaded = session.home.data != null && preview != null;
    final count = preview?.cards.length ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space2,
      children: [
        if (failure != null)
          SaveFailureRow(
            message: captureFailureMessage(l10n, failure),
            retryLabel: canRetrySave(failure) ? l10n.retry : null,
            onRetry: () => unawaited(session.save()),
            retryKey: const Key('capture.retry'),
          ),
        PressButton(
          key: const Key('capture.save'),
          horizontalPadding: LukitasTokens.space4,
          onPressed: loaded && preview.ready && !session.saving
              ? () => unawaited(session.save())
              : null,
          child: session.saving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: LukitasTokens.space2,
                  children: [const QuietSpinner(), Text(LkText.upperCase(l10n.addSaving))],
                )
              : Text(LkText.upperCase(loaded ? l10n.captureSave(count) : l10n.addSave)),
        ),
      ],
    );
  }
}

/// What a refused or failed batch save says.
String captureFailureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  if (failure.code == 'idempotency_in_progress') return l10n.addErrorBusy;
  if (failure.code == 'category_not_found') return l10n.addErrorCategory;
  if (failure.status == 422) return l10n.addErrorInvalid;
  return failure.status >= 500 ? l10n.errorInternal : l10n.errorGeneric;
}

/// The one celebration after a batch: how many and the total, with one Deshacer that takes them
/// all away. Everything it needs is passed in: the sheet is gone by the time anyone taps.
void celebrateBatch({
  required ProviderContainer container,
  required ToastController toasts,
  required AppLocalizations l10n,
  required List<Transaction> saved,
  required String total,
}) {
  final ids = [for (final t in saved) t.id];
  toasts.say(
    l10n.captureSaved(saved.length, total),
    actionLabel: l10n.undo,
    onAction: () => unawaited(() async {
      try {
        await container.read(captureRepositoryProvider).undoBatch(ids);
      } on HomeFailure catch (failure) {
        toasts.say(failure.offline ? l10n.errorNetwork : l10n.errorGeneric, error: true);
        return;
      }
      unawaited(container.read(homeProvider.notifier).forget(ids));
      container.read(feedbackProvider)(FeedbackEvent.undo);
      toasts.say(l10n.captureUndone(ids.length));
    }()),
  );
}
