import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import 'auth_errors.dart';
import 'lukitas_wave.dart';

/// First run (spec section 6.1): Lukitas waves, and three ways in: "Probar sin correo" (a guest),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final passkeys = ref.watch(passkeysSupportedProvider).value ?? false;
    final busy = _busy != _Busy.none;
    final error = _error;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(LukitasTokens.space5),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 2 * LukitasTokens.space5,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: LukitasTokens.space6),
                      const LukitasWave(),
                      const SizedBox(height: LukitasTokens.space4),
                      Text(
                        l10n.appName,
                        style: theme.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: LukitasTokens.space2),
                      Text(
                        l10n.entryLead,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: LukitasTokens.space6),
                      FilledButton(
                        key: const Key('entry.guest'),
                        onPressed: busy ? null : _startGuest,
                        child: Text(_busy == _Busy.guest ? l10n.entryGuestBusy : l10n.entryGuest),
                      ),
                      const SizedBox(height: LukitasTokens.space1),
                      Text(
                        l10n.entryGuestHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: LukitasTokens.space4),
                      OutlinedButton(
                        key: const Key('entry.withEmail'),
                        onPressed: busy ? null : () => context.push('/entry/email'),
                        child: Text(l10n.entryEmail),
                      ),
                      if (passkeys) ...[
                        const SizedBox(height: LukitasTokens.space3),
                        OutlinedButton.icon(
                          key: const Key('entry.passkey'),
                          onPressed: busy ? null : _passkey,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(
                            _busy == _Busy.passkey ? l10n.entryPasskeyBusy : l10n.entryPasskey,
                          ),
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: LukitasTokens.space4),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error.message(l10n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
