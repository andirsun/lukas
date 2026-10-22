import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import 'auth_errors.dart';
import 'guest_dialogs.dart';

/// "Entrar con mi correo": the email, then the 6-digit code (the email also carries a magic link,
/// handled by VerifyLinkScreen).
///
/// For a signed-in guest, nothing is sent before the person decides: save their progress to the
/// email (the claim, spec section 4.2), or, after a warning, sign in as another account.
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key, this.initialEmail, this.claim = false});

  final String? initialEmail;

  /// Start the claim of [initialEmail] at once (a guest chose "Guardar mi progreso" elsewhere).
  final bool claim;

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

enum _Stage { email, code }

enum _Mode { signIn, claim }

class _EmailScreenState extends ConsumerState<EmailScreen> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _code = TextEditingController();

  _Stage _stage = _Stage.email;
  _Mode _mode = _Mode.signIn;

  /// The person was warned and chose to leave the guest account behind.
  bool _replaceGuest = false;
  bool _busy = false;

  /// Checking the code (rather than sending one).
  bool _verifying = false;
  AuthError? _error;
  bool _resent = false;

  /// The email the code went to.
  String _sentTo = '';

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail;
    if (widget.claim && email != null && emailPattern.hasMatch(normalizeEmail(email))) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _claim(normalizeEmail(email)));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  SessionController get _session => ref.read(sessionProvider.notifier);

  /// Runs [action] with the busy state on, showing a failure as [onFail] reads it.
  Future<bool> _run(Future<void> Function() action, AuthError Function(AuthFailure) onFail) async {
    setState(() {
      _busy = true;
      _error = null;
      _resent = false;
    });
    try {
      await action();
      return true;
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = onFail(failure));
      return false;
    } catch (error) {
      // Never an unhandled error with a busy button: a message, and the screen works again.
      if (mounted) setState(() => _error = unexpectedErrorFor(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final email = normalizeEmail(_email.text);
    if (!emailPattern.hasMatch(email)) {
      setState(() => _error = AuthError.invalidEmail);
      return;
    }
    if (ref.read(sessionProvider).isGuest && !_replaceGuest) {
      final choice = await askGuestChoice(context, email);
      if (!mounted || choice == null) return;
      if (choice == GuestChoice.save) return _claim(email);
      if (!await confirmLeavingGuest(context, email) || !mounted) return;
      _replaceGuest = true;
    }
    await _sendSignIn(email);
  }

  Future<void> _sendSignIn(String email, {bool again = false}) async {
    final sent = await _run(
      () => _session.sendCode(email, replaceGuest: _replaceGuest),
      (failure) => authErrorFor(failure, AuthAction.send),
    );
    if (sent && mounted) _toCode(email, _Mode.signIn, again: again);
  }

  Future<void> _claim(String email, {bool again = false}) async {
    final sent = await _run(
      () => _session.claimEmail(email),
      (failure) => authErrorFor(failure, AuthAction.send),
    );
    if (sent && mounted) _toCode(email, _Mode.claim, again: again);
  }

  /// After email_taken: that email has its own account; signing in to it leaves the guest behind.
  Future<void> _signInInstead() async {
    final email = normalizeEmail(_email.text);
    if (!await confirmLeavingGuest(context, email) || !mounted) return;
    _replaceGuest = true;
    await _sendSignIn(email);
  }

  void _toCode(String email, _Mode mode, {required bool again}) {
    setState(() {
      _sentTo = email;
      _mode = mode;
      _stage = _Stage.code;
      _resent = again;
      _code.clear();
    });
  }

  Future<void> _submitCode() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _verifying = true);
    final ok = await _run(
      () => _mode == _Mode.claim
          ? _session.confirmClaim(_sentTo, code)
          : _session.verifyCode(_sentTo, code, replaceGuest: _replaceGuest),
      (failure) {
        final error = authErrorFor(failure, AuthAction.signIn);
        if (isCodeError(error)) _code.clear();
        return error;
      },
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) context.go('/');
  }

  void _resend() =>
      _mode == _Mode.claim ? _claim(_sentTo, again: true) : _sendSignIn(_sentTo, again: true);

  void _changeEmail() => setState(() {
    // A new email gets its own question (and warning) for a guest.
    _replaceGuest = false;
    _stage = _Stage.email;
    _error = null;
    _resent = false;
  });

  void _close() => context.canPop() ? context.pop() : context.go('/');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: _stage == _Stage.code ? _changeEmail : _close)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LukitasTokens.space5),
          child: _stage == _Stage.email ? _emailStage(l10n) : _codeStage(l10n),
        ),
      ),
    );
  }

  Widget _errorText(AuthError error) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: LukitasTokens.space3),
      child: Semantics(
        liveRegion: true,
        child: Text(
          error.message(AppLocalizations.of(context)),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  Widget _emailStage(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.signInTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: LukitasTokens.space2),
        Text(
          l10n.signInLead,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: LukitasTokens.space5),
        TextField(
          key: const Key('entry.email'),
          controller: _email,
          enabled: !_busy,
          autofocus: widget.initialEmail == null,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            hintText: l10n.emailPlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        if (error != null) _errorText(error),
        if (error == AuthError.emailTaken) ...[
          const SizedBox(height: LukitasTokens.space3),
          OutlinedButton(
            onPressed: _busy ? null : _signInInstead,
            child: Text(l10n.emailTakenSignIn),
          ),
        ],
        const SizedBox(height: LukitasTokens.space5),
        FilledButton(
          key: const Key('entry.send'),
          onPressed: _busy ? null : _send,
          child: Text(_busy ? l10n.sending : l10n.sendCode),
        ),
      ],
    );
  }

  Widget _codeStage(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final error = _error;
    final claim = _mode == _Mode.claim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.codeTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: LukitasTokens.space2),
        Text(
          claim ? l10n.claimCodeLead(_sentTo) : l10n.codeLead(_sentTo),
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: LukitasTokens.space5),
        TextField(
          key: const Key('entry.code'),
          controller: _code,
          enabled: !_busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitCode(),
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8),
          decoration: InputDecoration(
            labelText: l10n.codeLabel,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
        ),
        if (error != null) _errorText(error),
        if (_resent && error == null)
          Padding(
            padding: const EdgeInsets.only(top: LukitasTokens.space3),
            child: Semantics(liveRegion: true, child: Text(l10n.resent)),
          ),
        const SizedBox(height: LukitasTokens.space5),
        FilledButton(
          key: const Key('entry.submitCode'),
          onPressed: _busy ? null : _submitCode,
          child: Text(_verifying ? l10n.verifying : (claim ? l10n.submitClaim : l10n.submitCode)),
        ),
        const SizedBox(height: LukitasTokens.space3),
        TextButton(onPressed: _busy ? null : _resend, child: Text(l10n.resend)),
        TextButton(onPressed: _busy ? null : _changeEmail, child: Text(l10n.changeEmail)),
      ],
    );
  }
}
