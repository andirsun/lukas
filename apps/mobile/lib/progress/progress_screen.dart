import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../entry/auth_errors.dart';
import '../entry/lukitas_wave.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';

/// "Guarda tu progreso" (spec section 6.1.5, guests only): says honestly what a guest account is,
/// and offers the two ways to keep it. The email claim (section 4.2) is the real one: the guest's
/// own user receives the email, so every movement stays. A passkey (section 4.3) lets the guest
/// back in on this phone, but loses the account with the phone, and sync, AI and MCP need an email.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

enum _Passkey { idle, busy, added }

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _email = TextEditingController();
  AuthError? _emailError;

  _Passkey _passkey = _Passkey.idle;
  String? _passkeyError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// Hands the claim to the email screen, which sends the code, takes it, and says what went
  /// wrong (an email on the allowlist's other side, one that has an account already...).
  void _save() {
    final email = normalizeEmail(_email.text);
    if (!emailPattern.hasMatch(email)) {
      setState(() => _emailError = AuthError.invalidEmail);
      return;
    }
    setState(() => _emailError = null);
    context.push(
      Uri(path: '/entry/email', queryParameters: {'email': email, 'claim': '1'}).toString(),
    );
  }

  Future<void> _addPasskey() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _passkey = _Passkey.busy;
      _passkeyError = null;
    });
    String? error;
    var added = false;
    try {
      await ref.read(sessionProvider.notifier).registerPasskey();
      added = true;
    } on AuthFailure catch (failure) {
      // Closing the phone's prompt needs no explaining.
      if (failure.code != 'AUTH_CANCELLED') {
        final reason = authErrorFor(failure, AuthAction.signIn);
        error = retryableErrors.contains(reason)
            ? reason.message(l10n)
            : l10n.progressPasskeyFailed;
      }
    } catch (failure) {
      final reason = unexpectedErrorFor(failure);
      error = reason == AuthError.networkError ? reason.message(l10n) : l10n.progressPasskeyFailed;
    }
    if (!mounted) return;
    setState(() {
      _passkey = added ? _Passkey.added : _Passkey.idle;
      _passkeyError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final passkeys = ref.watch(passkeysSupportedProvider).value ?? false;
    final error = _emailError;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LukitasTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LukitasWave(size: 112)),
                  const SizedBox(height: LukitasTokens.space3),
                  Text(l10n.progressTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: LukitasTokens.space2),
                  Text(
                    l10n.progressLead,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: LukitasTokens.space2),
                  Text(l10n.progressEmailBody, style: muted),
                  const SizedBox(height: LukitasTokens.space4),
                  TextField(
                    key: const Key('progress.email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      hintText: l10n.emailPlaceholder,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: LukitasTokens.space3),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          error.message(l10n),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: LukitasTokens.space4),
                  FilledButton(
                    key: const Key('progress.save'),
                    onPressed: _save,
                    child: Text(l10n.progressSave),
                  ),
                  if (passkeys) ...[
                    const SizedBox(height: LukitasTokens.space6),
                    Text(l10n.progressPasskeyTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: LukitasTokens.space2),
                    Text(l10n.progressPasskeyBody, style: muted),
                    const SizedBox(height: LukitasTokens.space3),
                    if (_passkey == _Passkey.added)
                      Semantics(liveRegion: true, child: Text(l10n.progressPasskeyAdded))
                    else
                      OutlinedButton.icon(
                        key: const Key('progress.passkey'),
                        onPressed: _passkey == _Passkey.busy ? null : _addPasskey,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(
                          _passkey == _Passkey.busy
                              ? l10n.progressPasskeyAdding
                              : l10n.progressPasskeyAdd,
                        ),
                      ),
                    if (_passkeyError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: LukitasTokens.space3),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _passkeyError!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
