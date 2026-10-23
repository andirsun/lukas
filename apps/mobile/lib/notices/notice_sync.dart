import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/session.dart';
import '../feedback/stored_flag.dart';
import '../home/widget_sync.dart';
import '../settings/preferences.dart';
import 'notice_backend.dart';
import 'notice_platform.dart';
import 'notice_prompt.dart';

/// Keeps the app's two local notices (spec section 7.2) in step with the person, on the phone:
///
///  * **"Hoy vence…"** is scheduled for 9:00 in the profile's zone while someone is signed in and
///    its switch is on, and cancelled when either stops being true.
///  * **The guest warning** is set 45 days ahead, again at every opening of the app on a guest
///    account (so it only fires after 45 days without opening it), and cancelled when the account
///    stops being a guest (a claimed email, a sign-out) or its switch goes off.
///  * **The notification permission** (Android 13+) is asked in the app, with one sentence on why,
///    the first time a notice is relevant while the app is open: a recurring payment and the due
///    switch on, or a guest account and the guest switch on. It is asked once, whatever the
///    answer: a refusal only means the notices are not posted.
///
/// Runs one pass at a time; a pass is asked for at the start, whenever the session, a switch or the
/// language changes, and whenever the app comes back to the foreground (that is an opening too).
/// Where there is no Android side ([NoticePermission.unavailable]) it does nothing at all.
class NoticeSync with WidgetsBindingObserver {
  NoticeSync(this._ref);

  final Ref _ref;
  var _queue = Future<void>.value();
  var _asking = Future<void>.value();
  var _askingNow = false;
  NoticeFacts? _facts;

  /// Completes when every pass asked so far is done, and the question to the person, if one was
  /// put (tests wait on it).
  Future<void> get idle async {
    await _queue;
    await _asking;
  }

  /// Asks for a pass.
  void request() {
    _queue = _queue.then((_) async {
      try {
        await _pass();
      } on Object {
        // The notices keep what they had; this never breaks the app.
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) request();
  }

  NoticePlatform get _platform => _ref.read(noticePlatformProvider);

  Future<void> _pass() async {
    final platform = _platform;
    final session = _ref.read(sessionProvider.notifier);
    await session.ready;
    if (_ref.read(sessionProvider).status == SessionStatus.loading) return;
    // Android's answer first: where there is none, there is nothing to schedule or ask.
    if (await platform.permission() == NoticePermission.unavailable) return;

    if (_ref.read(sessionProvider).status != SessionStatus.signedIn) {
      _facts = null;
      await platform.cancelDue();
      await platform.cancelGuest();
      return;
    }
    final due = _ref.read(dueNoticeEnabledProvider.notifier);
    final guestNotice = _ref.read(guestNoticeEnabledProvider.notifier);
    await Future.wait([due.ready, guestNotice.ready]);
    // Read after the waits: the session may have changed meanwhile, and a later pass is queued.
    if (_ref.read(sessionProvider).status != SessionStatus.signedIn) return;
    final dueOn = _ref.read(dueNoticeEnabledProvider);
    final guestOn = _ref.read(guestNoticeEnabledProvider);
    final guest = _ref.read(sessionProvider).isGuest;
    final language = widgetLanguage(_ref);

    final guestRelevant = guest && guestOn;
    if (guestRelevant) {
      await platform.scheduleGuest(language: language);
    } else {
      await platform.cancelGuest();
    }

    var recurringRelevant = false;
    if (dueOn) {
      // The zone and the recurring payments are the server's word. Offline, the job keeps the
      // zone it knows, and nothing is asked of the person without knowing there is something.
      var facts = _facts;
      if (facts == null || !facts.hasRecurring) {
        try {
          facts = _facts = await _ref.read(noticeBackendProvider).facts();
        } on Object {
          // Keep the earlier facts, if any.
        }
      }
      await platform.scheduleDue(zone: facts?.timezone, language: language);
      recurringRelevant = facts?.hasRecurring ?? false;
    } else {
      await platform.cancelDue();
    }

    // The question waits for the person, so it never holds up the passes behind it.
    if (recurringRelevant) {
      _ask(NoticeReason.due);
    } else if (guestRelevant) {
      _ask(NoticeReason.guest);
    }
  }

  void _ask(NoticeReason reason) {
    if (_askingNow) return;
    _askingNow = true;
    _asking = _askOnce(reason)
        .catchError((Object _) {
          // Nothing asked: the notices just do not post.
        })
        .whenComplete(() => _askingNow = false);
  }

  /// The permission, once: with a sentence on why in the app, then Android's own prompt.
  Future<void> _askOnce(NoticeReason reason) async {
    final asked = _ref.read(flagStoreProvider('notice.permission.asked'));
    if (await asked.read() == true) return;
    // Allowed already, or switched off where the app cannot change it: nothing to ask.
    if (await _platform.permission() != NoticePermission.askable) return;
    final answer = await _ref.read(noticePromptProvider)(reason);
    if (answer == null) return;
    // Counted as soon as the person has seen the question, whatever they answer.
    try {
      await asked.write(true);
    } on Object {
      // Not kept: it may be asked once more after a restart.
    }
    if (answer) await _platform.requestPermission();
  }
}

/// The notices' keeper. The app watches it from the start (app.dart).
final noticeSyncProvider = Provider<NoticeSync>((ref) {
  final sync = NoticeSync(ref);
  WidgetsBinding.instance.addObserver(sync);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(sync));
  // A new session, a guest who claimed an email, a switch, the language: a new pass.
  ref.listen(sessionProvider.select((s) => (s.status, s.isGuest)), (previous, next) {
    if (previous != next) sync.request();
  });
  ref.listen(dueNoticeEnabledProvider, (previous, next) {
    if (previous != next) sync.request();
  });
  ref.listen(guestNoticeEnabledProvider, (previous, next) {
    if (previous != next) sync.request();
  });
  ref.listen(localeOverrideProvider, (previous, next) {
    if (previous != next) sync.request();
  });
  // While the stored session is being read the listener above asks as soon as it is known.
  if (ref.read(sessionProvider).status != SessionStatus.loading) sync.request();
  return sync;
});
