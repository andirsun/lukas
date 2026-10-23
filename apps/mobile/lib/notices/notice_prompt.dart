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
/// "Permitir avisos"; false: "Ahora no"; null: nothing was answered (no screen to ask on, or the
/// question was closed by something other than the person, such as a link opening a sheet), so it
/// is asked again at the next chance.
typedef NoticePrompt = Future<bool?> Function(NoticeReason reason);

/// The question, on home and only there (replaced in tests). Only its two buttons (and the back
/// button, as "Ahora no") answer it: tapping outside does nothing.
final noticePromptProvider = Provider<NoticePrompt>((ref) {
  return (reason) async {
    final context = await _homeContext(ref);
    if (context == null || !context.mounted) return null;
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        // The back button is "Ahora no"; a pop from the app itself (a link closing every sheet)
        // does not come here and leaves the dialog's result null.
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop(false);
        },
        child: AlertDialog(
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
      ),
    );
  };
});

/// How long the question waits for home to be free, and how often it looks.
const _waitForHome = Duration(minutes: 5);
const _lookEvery = Duration(milliseconds: 250);

/// The screen to ask on: the router's navigator while the person is on home with nothing over it
/// (no sheet, no dialog, no other screen). It waits for that for a few minutes (a sheet the person
/// is using is theirs), and takes one more frame once there, since the navigator is still showing
/// the page that home replaces. Null when home never frees up: nothing is asked.
Future<BuildContext?> _homeContext(Ref ref) async {
  final router = ref.read(routerProvider);
  final navigator = router.routerDelegate.navigatorKey;

  bool free() {
    final context = navigator.currentContext;
    return router.state.uri.path == '/' &&
        context != null &&
        context.mounted &&
        !Navigator.of(context).canPop();
  }

  final end = DateTime.now().add(_waitForHome);
  while (DateTime.now().isBefore(end)) {
    if (free()) {
      await WidgetsBinding.instance.endOfFrame;
      if (free()) return navigator.currentContext;
    }
    await Future<void>.delayed(_lookEvery);
  }
  return null;
}
