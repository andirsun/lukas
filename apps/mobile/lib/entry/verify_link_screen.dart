import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import 'auth_errors.dart';

/// The magic link, `https://<server>/auth/verify?email=…&code=…`, opened in the app (Android App
/// Links). Signs in at once; a signed-in guest is asked first, since signing in would leave the
/// guest's account behind (it can save its progress to that email instead).
class VerifyLinkScreen extends ConsumerStatefulWidget {
  const VerifyLinkScreen({super.key, required this.email, required this.code});

  final String? email;
  final String? code;

  @override
  ConsumerState<VerifyLinkScreen> createState() => _VerifyLinkScreenState();
}

enum _Phase { waiting, guestAsks, verifying, failed }

class _VerifyLinkScreenState extends ConsumerState<VerifyLinkScreen> {
  _Phase _phase = _Phase.waiting;
  AuthError _error = AuthError.invalidOrExpiredCode;

  String get _email => normalizeEmail(widget.email ?? '');
  String get _code => (widget.code ?? '').trim();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await ref.read(sessionProvider.notifier).ready;
    if (!mounted) return;
    if (!emailPattern.hasMatch(_email) || _code.isEmpty) {
      setState(() => _phase = _Phase.failed);
    } else if (ref.read(sessionProvider).isGuest) {
      setState(() => _phase = _Phase.guestAsks);
    } else {
      await _verify(replaceGuest: false);
    }
  }

  Future<void> _verify({required bool replaceGuest}) async {
    setState(() => _phase = _Phase.verifying);
    try {
      await ref
          .read(sessionProvider.notifier)
          .verifyCode(_email, _code, replaceGuest: replaceGuest);
      if (mounted) context.go('/');
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = linkErrorFor(failure);
        });
      }
    } on GuestInTheWay {
      if (mounted) setState(() => _phase = _Phase.guestAsks);
    } catch (error) {
      // Never a spinner that turns forever: the failure, with a retry when it can help.
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = unexpectedErrorFor(error);
        });
      }
    }
  }

  String _emailRoute({bool claim = false}) => Uri(
    path: '/entry/email',
    queryParameters: {if (_email.isNotEmpty) 'email': _email, if (claim) 'claim': '1'},
  ).toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final body = switch (_phase) {
      _Phase.waiting || _Phase.verifying => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: LukitasTokens.space4),
            Text(l10n.verifying),
          ],
        ),
      ),
      _Phase.guestAsks => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.guestLeaveTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: LukitasTokens.space3),
          Text(l10n.guestLeaveBody(_email), style: theme.textTheme.bodyLarge),
          const SizedBox(height: LukitasTokens.space5),
          FilledButton(
            onPressed: () => context.go(_emailRoute(claim: true)),
            child: Text(l10n.guestSaveAction),
          ),
          const SizedBox(height: LukitasTokens.space3),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => _verify(replaceGuest: true),
            child: Text(l10n.guestLeaveConfirm),
          ),
          TextButton(onPressed: () => context.go('/'), child: Text(l10n.cancel)),
        ],
      ),
      _Phase.failed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.verifyFailedTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: LukitasTokens.space3),
          Semantics(
            liveRegion: true,
            child: Text(_error.message(l10n), style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: LukitasTokens.space5),
          if (retryableErrors.contains(_error) && emailPattern.hasMatch(_email))
            OutlinedButton(onPressed: () => _start(), child: Text(l10n.retry)),
          FilledButton(onPressed: () => context.go(_emailRoute()), child: Text(l10n.sendNewCode)),
        ],
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(LukitasTokens.space5), child: body),
      ),
    );
  }
}
