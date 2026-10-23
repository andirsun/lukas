import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import 'auth_errors.dart';
import 'code_formatter.dart';
import 'guest_dialogs.dart';

/// "Entrar con mi correo": the email, then the 6-digit code (the email also carries a magic link,
/// handled by VerifyLinkScreen).
///
/// On opening it also asks the phone for a passkey it can offer at once (one made on the web and
/// held by a provider such as Proton Pass): its sheet appears if there is one, and signing in with
/// it completes; with none, nothing shows and the email field is ready. "Usar passkey" does the
/// same on demand, with the provider's own picker.
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
  final _emailFocus = FocusNode();

  /// A passkey prompt is open (or being asked for): no second one.
  bool _passkeyActive = false;

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
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerPasskey());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  SessionController get _session => ref.read(sessionProvider.notifier);

  /// On opening: signs in with a passkey the phone can offer at once, silently when it has none.
  /// Not for a guest, whose session a passkey would replace unasked (the button warns first), nor
  /// when the screen only finishes a claim.
  Future<void> _offerPasskey() async {
    if (!mounted || _passkeyActive) return;
    setState(() => _passkeyActive = true);
    var signedIn = false;
    try {
      await _session.ready;
      if (!mounted || ref.read(sessionProvider).isGuest) return;
      if (!await ref.read(passkeysSupportedProvider.future) || !mounted) return;
      signedIn = await _session.signInWithAvailablePasskey();
    } on GuestInTheWay {
      // A guest signed in meanwhile: nothing to offer.
    } on AuthFailure catch (failure) {
      // Only a passkey the person chose and the server refused gets here.
      if (mounted) setState(() => _error = passkeyErrorFor(failure));
    } catch (error) {
      if (mounted) setState(() => _error = unexpectedPasskeyErrorFor(error));
    } finally {
      if (mounted) setState(() => _passkeyActive = false);
    }
    if (!mounted) return;
    if (signedIn) {
      context.go('/');
    } else if (_stage == _Stage.email) {
      // The sheet took the focus away, or never came: the email is where the person goes next.
      _emailFocus.requestFocus();
    }
  }

  /// "Usar passkey": the phone's passkey prompt, with the provider's own picker. A guest is warned
  /// first (the passkey's account replaces theirs) and may save their progress instead.
  Future<void> _passkey() async {
    if (_passkeyActive) return;
    var replaceGuest = false;
    if (ref.read(sessionProvider).isGuest) {
      final choice = await askGuestPasskeyChoice(context);
      if (!mounted || choice == null) return;
      if (choice == GuestPasskeyChoice.save) {
        _emailFocus.requestFocus();
        return;
      }
      replaceGuest = true;
    }
    setState(() {
      _passkeyActive = true;
      _error = null;
      _resent = false;
    });
    var signedIn = false;
    try {
      await _session.signInWithPasskey(replaceGuest: replaceGuest);
      signedIn = true;
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = passkeyErrorFor(failure));
    } on GuestInTheWay {
      // A guest signed in meanwhile: the person can tap again and will be asked.
    } catch (error) {
      if (mounted) setState(() => _error = unexpectedPasskeyErrorFor(error));
    } finally {
      if (mounted) setState(() => _passkeyActive = false);
    }
    if (!mounted) return;
    if (signedIn) {
      context.go('/');
    } else if (_stage == _Stage.email) {
      _emailFocus.requestFocus();
    }
  }

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
    final passkeys = ref.watch(passkeysSupportedProvider).value ?? false;
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
          focusNode: _emailFocus,
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
        if (passkeys) ...[
          const SizedBox(height: LukitasTokens.space3),
          OutlinedButton(
            key: const Key('entry.passkey'),
            onPressed: _busy || _passkeyActive ? null : _passkey,
            child: Text(_passkeyActive ? l10n.emailPasskeyBusy : l10n.emailPasskey),
          ),
        ],
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
          inputFormatters: const [CodeFormatter()],
          maxLength: codeLength,
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
