import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// What a guest who typed an email chose to do with it.
enum GuestChoice { save, otherAccount }

/// Asked when a guest enters with an email (spec section 4.2): save their progress to that email
/// (the claim: same account, every movement kept), or sign in as another account. Null: neither.
Future<GuestChoice?> askGuestChoice(BuildContext context, String email) {
  final l10n = AppLocalizations.of(context);
  return showDialog<GuestChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.guestSaveTitle),
      content: Text(l10n.guestSaveBody(email)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          key: const Key('guest.otherAccount'),
          onPressed: () => Navigator.pop(context, GuestChoice.otherAccount),
          child: Text(l10n.guestOtherAccount),
        ),
        FilledButton(
          key: const Key('guest.save'),
          onPressed: () => Navigator.pop(context, GuestChoice.save),
          child: Text(l10n.guestSaveAction),
        ),
      ],
    ),
  );
}

/// The warning before a guest's session is replaced by [email]'s: the guest's account has no email,
/// so once its token is gone nobody can reach it again. True only when the person confirms.
Future<bool> confirmLeavingGuest(BuildContext context, String email) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.guestLeaveTitle),
      content: Text(l10n.guestLeaveBody(email)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('guest.leaveConfirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.guestLeaveConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// What a guest who chose "Usar passkey" decided.
enum GuestPasskeyChoice { save, signIn }

/// The warning before a guest signs in with a passkey (spec section 4.2), which replaces the
/// guest's session: its email is not known, so the warning cannot name one. The person may instead
/// save their progress to an email first (the claim). Null: neither.
Future<GuestPasskeyChoice?> askGuestPasskeyChoice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<GuestPasskeyChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.guestLeaveTitle),
      content: Text(l10n.guestPasskeyBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          key: const Key('guest.leaveConfirm'),
          onPressed: () => Navigator.pop(context, GuestPasskeyChoice.signIn),
          child: Text(l10n.guestLeaveConfirm),
        ),
        FilledButton(
          key: const Key('guest.save'),
          onPressed: () => Navigator.pop(context, GuestPasskeyChoice.save),
          child: Text(l10n.guestSaveAction),
        ),
      ],
    ),
  );
}
