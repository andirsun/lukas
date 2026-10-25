import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/confirm_sheet.dart';
import '../ui/press_button.dart';

/// What a guest was about to do that would leave their account behind.
enum GuestLeaving { signOut, changeServer }

/// What a warned guest chose.
enum GuestWarning { saveInstead, leave }

/// The warning before a guest signs out or changes server (spec section 4.2; the carried review of
/// Task 9): the account has no email, so once its token is gone nobody can reach it again. It says
/// so honestly and offers "Guarda tu progreso" instead. It is the web's sheet (`ConfirmSheet`) with
/// a second way forward. Null: the person backed out.
Future<GuestWarning?> warnGuestLeaving(BuildContext context, GuestLeaving leaving) {
  final l10n = AppLocalizations.of(context);
  final (title, body, confirm, confirmKey) = switch (leaving) {
    GuestLeaving.signOut => (
      l10n.guestSignOutTitle,
      l10n.guestSignOutBody,
      l10n.guestSignOutConfirm,
      'guest.signOutConfirm',
    ),
    GuestLeaving.changeServer => (
      l10n.guestServerTitle,
      l10n.guestServerBody,
      l10n.guestServerConfirm,
      'guest.serverConfirm',
    ),
  };
  return ChoiceSheet.show<GuestWarning>(
    context,
    title: title,
    body: body,
    choices: [
      SheetChoice(
        key: const Key('guest.saveInstead'),
        label: l10n.progressTitle,
        value: GuestWarning.saveInstead,
        tone: PressTone.primary,
      ),
      SheetChoice(key: Key(confirmKey), label: confirm, value: GuestWarning.leave, danger: true),
    ],
  );
}
