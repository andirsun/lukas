import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../feedback/feedback.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../home/toast.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/tokens.g.dart';
import 'add_form.dart';

/// What follows a save, apart from the sheet itself: when sending the same request again can work,
/// the words for a failure, and the toast with Deshacer (the web's `useTransactionActions`).

/// Whether sending the same request again can work: no answer at all (offline, a lost
/// connection), a server error or timeout, too many requests, or the first try still running. Not
/// a refusal (a 4xx such as an invalid amount), which says the same every time.
bool canRetrySave(HomeFailure failure) =>
    failure.status == 0 ||
    failure.status >= 500 ||
    failure.status == 408 ||
    failure.status == 429 ||
    failure.code == 'idempotency_in_progress';

/// What the sheet says when a save fails.
String saveFailureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  if (failure.code == 'idempotency_in_progress') return l10n.addErrorBusy;
  if (failure.code == 'category_not_found') return l10n.addErrorCategory;
  if (failure.status == 404) return l10n.addErrorNotFound;
  if (failure.status == 422) return l10n.addErrorInvalid;
  return failure.status >= 500 ? l10n.errorInternal : l10n.errorGeneric;
}

/// The toast after a new movement: what was saved, Deshacer (which takes it away again) and, for
/// a movement saved without a name, "Ponerle nombre" (which opens it on its name). Everything it
/// needs is passed in: the sheet is gone by the time anyone taps.
void toastCreated({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required NavigatorState navigator,
  required LukitasColors colors,
  required AppLocalizations l10n,
  required Transaction created,
  required Kind kind,
  required String categoryName,
  required String currency,
  required bool unnamed,
  required Future<void> Function(BuildContext context, Transaction tx) nameIt,
}) {
  final locale = l10n.localeName;
  final amount = formatMoney(created.amount.abs(), currency, locale);
  final hint = lukasHint(created.amount, locale, currency: currency);
  final line = kind == Kind.income
      ? l10n.addSavedIncome(categoryName, amount)
      : l10n.addSavedExpense(categoryName, amount);
  showToast(
    messenger,
    colors,
    hint == null ? line : '$line $hint',
    actionLabel: l10n.undo,
    onAction: () => unawaited(_undoCreated(container, messenger, colors, l10n, created)),
    extraLabel: unnamed ? l10n.addNameIt : null,
    onExtra: unnamed
        ? () {
            if (navigator.mounted) unawaited(nameIt(navigator.context, created));
          }
        : null,
  );
}

Future<void> _undoCreated(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  LukitasColors colors,
  AppLocalizations l10n,
  Transaction created,
) async {
  try {
    await container.read(homeProvider.notifier).remove(created);
  } on HomeFailure catch (failure) {
    showToast(
      messenger,
      colors,
      failure.offline ? l10n.errorNetwork : l10n.errorGeneric,
      error: true,
    );
    return;
  }
  container.read(feedbackProvider)(FeedbackEvent.undo);
  showToast(messenger, colors, l10n.addUndone(created.name));
}

/// Eliminar on an edited movement: it goes at once (home does the same for a swipe) and the toast
/// offers Deshacer, which brings it back (the web's `actions.remove` and `bringBack`). The sheet is
/// gone by then, so everything it needs is passed in.
Future<void> deleteMovement({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required LukitasColors colors,
  required AppLocalizations l10n,
  required Transaction transaction,
}) async {
  final home = container.read(homeProvider.notifier);
  container.read(feedbackProvider)(FeedbackEvent.deleted);
  try {
    await home.remove(transaction);
  } on HomeFailure catch (failure) {
    showToast(
      messenger,
      colors,
      failure.offline ? l10n.errorNetwork : l10n.errorGeneric,
      error: true,
    );
    return;
  }
  showToast(
    messenger,
    colors,
    l10n.transactionDeleted(transaction.name),
    actionLabel: l10n.undo,
    onAction: () => unawaited(_bringBack(container, messenger, colors, l10n, transaction)),
  );
}

Future<void> _bringBack(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  LukitasColors colors,
  AppLocalizations l10n,
  Transaction transaction,
) async {
  try {
    await container.read(homeProvider.notifier).restore(transaction);
  } on HomeFailure catch (failure) {
    showToast(
      messenger,
      colors,
      failure.offline ? l10n.errorNetwork : l10n.errorGeneric,
      error: true,
    );
    return;
  }
  container.read(feedbackProvider)(FeedbackEvent.undo);
  showToast(messenger, colors, l10n.transactionRestored(transaction.name));
}
