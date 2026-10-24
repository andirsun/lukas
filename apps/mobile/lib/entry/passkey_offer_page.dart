// The passkey offer's page: the screen wired to the session (`/entry/passkey-offer`).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../ui/toast.dart';
import 'passkey_offer_screen.dart';

/// What adding the passkey came to, from the failure Better Auth or the phone gave: closing the
/// phone's prompt is no failure (`cancelled`), and a passkey this phone already has counts as made.
PasskeyOfferOutcome passkeyOfferOutcome(AuthFailure failure) => switch (failure.code) {
  'AUTH_CANCELLED' ||
  'ERROR_CEREMONY_ABORTED' ||
  'ERROR_PASSTHROUGH_SEE_CAUSE_PROPERTY' => PasskeyOfferOutcome.cancelled,
  'ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED' => PasskeyOfferOutcome.added,
  _ => PasskeyOfferOutcome.failed,
};

/// `/entry/passkey-offer`: the offer, wired to the session. Making the passkey is the existing
/// `registerPasskey()`; either answer is kept for the account and leads on to home, with the
/// confirmation when a passkey was made.
class PasskeyOfferPage extends ConsumerWidget {
  const PasskeyOfferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(sessionProvider.notifier);
    return PasskeyOfferScreen(
      add: () async {
        try {
          await session.registerPasskey();
          return PasskeyOfferOutcome.added;
        } on AuthFailure catch (failure) {
          return passkeyOfferOutcome(failure);
        }
      },
      onAnswered: (added) async {
        final router = GoRouter.of(context);
        final toasts = ToastHost.of(context);
        final message = AppLocalizations.of(context).passkeyOfferAdded;
        await session.answerPasskeyOffer();
        if (added) toasts.say(message);
        router.go('/');
      },
    );
  }
}
