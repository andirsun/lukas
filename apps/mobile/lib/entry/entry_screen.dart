import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_icons.dart';
import '../ui/press_button.dart';
import 'auth_errors.dart';
import 'sign_in_frame.dart';

/// First run (spec section 6.1): Lukitas on the web's sign-in frame, and three ways in: "Probar sin correo" (a guest),
/// "Entrar con mi correo" (a code or magic link) and "Entrar con huella" (a passkey), the last only
/// when the phone supports passkeys.
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key});

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

enum _Busy { none, guest, passkey }

class _EntryScreenState extends ConsumerState<EntryScreen> {
  _Busy _busy = _Busy.none;
  AuthError? _error;

  Future<void> _run(
    _Busy busy,
    Future<void> Function() action,
    AuthError? Function(AuthFailure) onFail,
  ) async {
    setState(() {
      _busy = busy;
      _error = null;
    });
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = onFail(failure));
    } catch (error) {
      // Never an unhandled error with a busy button: a message, and the buttons work again.
      if (mounted) {
        setState(() {
          _error = busy == _Busy.passkey
              ? unexpectedPasskeyErrorFor(error)
              : unexpectedErrorFor(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  void _startGuest() => _run(
    _Busy.guest,
    () => ref.read(sessionProvider.notifier).startGuest(),
    (failure) => authErrorFor(failure, AuthAction.signIn),
  );

  // Signed out here, so no guest stands in the way.
  void _passkey() => _run(
    _Busy.passkey,
    () => ref.read(sessionProvider.notifier).signInWithPasskey(),
    passkeyErrorFor,
  );

  /// The web's `w-full`.
  Widget _full(Widget child) => SizedBox(width: double.infinity, child: child);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final passkeys = ref.watch(passkeysSupportedProvider).value ?? false;
    final busy = _busy != _Busy.none;
    final error = _error;

    return SignInFrame(
      children: [
        EntryTitle(l10n.appName),
        EntryLead(l10n.entryLead),
        // The way in with the least to give up, first: the web's secondary button.
        _full(
          PressButton.text(
            _busy == _Busy.guest ? l10n.entryGuestBusy : l10n.entryGuest,
            key: const Key('entry.guest'),
            tone: PressTone.secondary,
            onPressed: busy ? null : _startGuest,
          ),
        ),
        EntryNote(l10n.entryGuestHint),
        _full(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LukitasTokens.space3,
            children: [
              PressButton.text(
                l10n.entryEmail,
                key: const Key('entry.withEmail'),
                onPressed: busy ? null : () => context.push('/entry/email'),
              ),
              if (passkeys)
                PressButton(
                  key: const Key('entry.passkey'),
                  tone: PressTone.secondary,
                  onPressed: busy ? null : _passkey,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: LukitasTokens.space2,
                    children: [
                      const FingerprintIcon(),
                      Flexible(
                        child: Text(
                          (_busy == _Busy.passkey ? l10n.entryPasskeyBusy : l10n.entryPasskey)
                              .toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (error != null) FieldError(error.message(l10n), textAlign: TextAlign.center),
      ],
    );
  }
}
