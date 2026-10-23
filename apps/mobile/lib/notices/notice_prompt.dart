import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';

/// Why the app asks to post notices: the notice that just became relevant.
enum NoticeReason {
  /// "Hoy vence…": a recurring payment exists and the notice is on.
  due,

  /// The guest warning: a guest account exists and the notice is on.
  guest,
}

/// Asks the person, in the app, whether notices may be posted, with one sentence on why. True:
/// "Permitir avisos"; false: "Ahora no"; null: there was no screen to ask on (nothing was asked).
typedef NoticePrompt = Future<bool?> Function(NoticeReason reason);

/// The question, on whatever screen the app is on (replaced in tests).
final noticePromptProvider = Provider<NoticePrompt>((ref) {
  return (reason) async {
    final context = await _navigatorContext(ref);
    if (context == null || !context.mounted) return null;
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('notices.ask'),
        title: Text(l10n.noticeAskTitle),
        content: Text(
          key: const Key('notices.askWhy'),
          switch (reason) {
            NoticeReason.due => l10n.noticeAskDue,
            NoticeReason.guest => l10n.noticeAskGuest,
          },
        ),
        actions: [
          TextButton(
            key: const Key('notices.askLater'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.noticeAskLater),
          ),
          FilledButton(
            key: const Key('notices.askAllow'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.noticeAskAllow),
          ),
        ],
      ),
    );
    // Dismissed by tapping outside or going back: an answer, "not now".
    return answer ?? false;
  };
});

/// The screen to ask on: the router's navigator once the person is on a screen of their own, not
/// the loading screen or the entry (a question put over a page that goes away goes with it). It
/// takes a few frames at a cold start. Null if it never comes.
Future<BuildContext?> _navigatorContext(Ref ref) async {
  final router = ref.read(routerProvider);
  final navigator = router.routerDelegate.navigatorKey;
  for (var frame = 0; frame < 60; frame++) {
    final context = navigator.currentContext;
    final path = router.state.uri.path;
    final settled = path != '/loading' && path != '/entry' && path != '/entry/email';
    if (settled && context != null && context.mounted) {
      // One more frame: the navigator is still showing the old page, which the screen replaces.
      await WidgetsBinding.instance.endOfFrame;
      return navigator.currentContext;
    }
    await WidgetsBinding.instance.endOfFrame;
  }
  return null;
}
