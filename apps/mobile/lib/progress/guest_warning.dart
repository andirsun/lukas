import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// What a guest was about to do that would leave their account behind.
enum GuestLeaving { signOut, changeServer }

/// What a warned guest chose.
enum GuestWarning { saveInstead, leave }

/// The warning before a guest signs out or changes server (spec section 4.2; the carried review of
/// Task 9): the account has no email, so once its token is gone nobody can reach it again. It says
/// so honestly and offers "Guarda tu progreso" instead. Null: the person backed out.
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
  return showDialog<GuestWarning>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          key: Key(confirmKey),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, GuestWarning.leave),
          child: Text(confirm),
        ),
        FilledButton(
          key: const Key('guest.saveInstead'),
          onPressed: () => Navigator.pop(context, GuestWarning.saveInstead),
          child: Text(l10n.progressTitle),
        ),
      ],
    ),
  );
}
