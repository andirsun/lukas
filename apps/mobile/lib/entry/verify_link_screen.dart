import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_api.dart';
import '../api/session.dart';
import '../home/lukitas_face.dart';
import '../l10n/app_localizations.dart';
import '../ui/lk_theme.dart';
import '../ui/press_button.dart';
import 'auth_errors.dart';
import 'sign_in_frame.dart';

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

  /// The web's `w-full`.
  Widget _full(Widget child) => SizedBox(width: double.infinity, child: child);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (_phase) {
      // The web's page while the code is being checked: whose account, and a button that says so.
      _Phase.waiting || _Phase.verifying => SignInFrame(
        children: [
          EntryTitle(l10n.verifyConfirmTitle(_email)),
          EntryLead(l10n.verifyConfirmLead),
          _full(PressButton.text(l10n.verifying)),
          PressButton.text(l10n.verifyNotMe, tone: PressTone.ghost),
        ],
      ),
      // Only the app has this one: the web's page signs a new browser in, not a signed-in guest.
      _Phase.guestAsks => SignInFrame(
        children: [
          EntryTitle(l10n.guestLeaveTitle),
          EntryLead(l10n.guestLeaveBody(_email), strong: _email),
          _full(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PressButton.text(
                  l10n.guestSaveAction,
                  onPressed: () => context.go(_emailRoute(claim: true)),
                ),
                PressButton(
                  tone: PressTone.secondary,
                  onPressed: () => _verify(replaceGuest: true),
                  child: Text(
                    l10n.guestLeaveConfirm.toUpperCase(),
                    style: TextStyle(color: context.lkColors.over),
                  ),
                ),
                PressButton.text(
                  l10n.cancel,
                  tone: PressTone.ghost,
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
        ],
      ),
      _Phase.failed => _failed(l10n),
    };
  }

  Widget _failed(AppLocalizations l10n) {
    final retry = retryableErrors.contains(_error) && emailPattern.hasMatch(_email);
    return SignInFrame(
      mood: LukitasMood.worried,
      children: [
        EntryTitle(l10n.verifyFailedTitle),
        FieldError(_error.message(l10n), textAlign: TextAlign.center),
        if (retry) _full(PressButton.text(l10n.retry, onPressed: () => _start())),
        _full(
          PressButton.text(
            l10n.sendNewCode,
            tone: retry ? PressTone.secondary : PressTone.primary,
            onPressed: () => context.go(_emailRoute()),
          ),
        ),
      ],
    );
  }
}
