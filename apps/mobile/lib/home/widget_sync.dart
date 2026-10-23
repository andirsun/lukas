import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/device.dart';
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../settings/preferences.dart';
import 'home_controller.dart';
import 'widget_snapshot.dart';

/// The language of the widget's words and amounts: the one picked in Settings, else the phone's
/// (Spanish unless it asks for English), as the app's own screens.
String widgetLanguage(Ref ref) =>
    ref.read(localeOverrideProvider)?.languageCode ??
    languageOfTag(ref.read(deviceHintsProvider).locale);

/// The app's theme choice as the widget reads it (`theme` in the snapshot).
String widgetTheme(ThemeMode mode) => switch (mode) {
  ThemeMode.dark => 'dark',
  ThemeMode.light => 'light',
  ThemeMode.system => 'system',
};

/// Keeps the home-screen widget's snapshot (lib/home/widget_snapshot.dart) in step with the app
/// (spec section 7.1):
///
/// * every summary home loads is written, once the hide-amount choice has been read back (so a
///   hidden amount is never written in the clear, even for a moment at a cold start);
/// * the hide-amount switch and the theme choice are copied in whenever they change: the widget is
///   Kotlin and cannot read `flutter_secure_storage`, where Settings keeps them;
/// * a sign-out writes the signed-out snapshot at once, and nothing of a signed-in person is
///   written after it (Review Focus 4): every write checks the session right before it is sent,
///   with nothing awaited in between, so it lands either before the sign-out's or not at all.
///
/// Summary and choice writes run one after another, so an older one never lands after a newer
/// one. The Kotlin refresh job (RefreshWorker.kt) writes the same document on its own; it never
/// writes once the session token is gone.
class WidgetSync {
  WidgetSync(this._ref);

  final Ref _ref;
  var _queue = Future<void>.value();

  /// Grows at each sign-out: a write queued before it is dropped, even when the next session is
  /// already signed in by the time it runs (a guest replaced by an email account).
  var _session = 0;

  WidgetStore get _store => _ref.read(widgetStoreProvider);
  bool get _signedIn => _ref.read(sessionProvider).status == SessionStatus.signedIn;
  bool get _hideAmount => _ref.read(hideWidgetAmountProvider);
  String get _theme => widgetTheme(_ref.read(themeModeProvider));

  /// Completes when every write asked so far is done (tests wait on it).
  Future<void> get idle => _queue;

  Future<void> _enqueue(Future<void> Function() write) {
    final next = _queue.then((_) async {
      try {
        await write();
      } on Object {
        // The widget keeps what it had; this never breaks the app.
      }
    });
    _queue = next;
    return next;
  }

  /// Writes [summary], the month home just loaded, in [currency]. [locale] is the language its
  /// amount is written in ([widgetLanguage] when null).
  Future<void> summaryLoaded(Summary summary, {required String currency, String? locale}) {
    final language = locale ?? widgetLanguage(_ref);
    final updatedAt = _ref.read(clockProvider)();
    final session = _session;
    return _enqueue(() async {
      await _ref.read(hideWidgetAmountProvider.notifier).ready;
      if (!_signedIn || session != _session) return;
      await saveWidgetSnapshot(
        _store,
        signedInSnapshot(
          summary,
          currency: currency,
          locale: language,
          hideAmount: _hideAmount,
          theme: _theme,
          updatedAt: updatedAt,
        ),
      );
    });
  }

  /// The session ended: the widget says "Abre Lukitas para empezar" and holds no figure. Written
  /// straight away, ahead of anything queued (which then finds the session gone and writes
  /// nothing), and never held up by a slow store read.
  Future<void> signedOut() async {
    _session++;
    try {
      await saveWidgetSnapshot(
        _store,
        signedOutSnapshot(hideAmount: _hideAmount, theme: _theme, locale: widgetLanguage(_ref)),
      );
    } on Object {
      // Nothing more to do.
    }
  }

  /// The hide-amount switch or the theme changed: the stored snapshot gets them, its figures and
  /// their time unchanged.
  Future<void> choicesChanged() {
    final session = _session;
    return _enqueue(() async {
      await _ref.read(hideWidgetAmountProvider.notifier).ready;
      final stored = await _store.read(widgetSnapshotKey);
      final patched = withChoices(stored, hideAmount: _hideAmount, theme: _theme);
      if (patched == null) {
        // Nothing of this version yet: signed out, the signed-out snapshot carries the choices;
        // signed in, home's next load writes everything.
        if (!_signedIn) {
          await saveWidgetSnapshot(
            _store,
            signedOutSnapshot(hideAmount: _hideAmount, theme: _theme, locale: widgetLanguage(_ref)),
          );
        }
        return;
      }
      // Read before a sign-out, written after it: dropped, the sign-out's snapshot stands.
      if (patched['signedIn'] == true && (!_signedIn || session != _session)) return;
      await saveWidgetSnapshot(_store, patched);
    });
  }
}

/// The widget's snapshot keeper. The app watches it from the start (app.dart), so the choices are
/// followed for as long as the app runs.
final widgetSyncProvider = Provider<WidgetSync>((ref) {
  final sync = WidgetSync(ref);
  ref.listen(hideWidgetAmountProvider, (previous, next) {
    if (previous != next) unawaited(sync.choicesChanged());
  });
  ref.listen(themeModeProvider, (previous, next) {
    if (previous != next) unawaited(sync.choicesChanged());
  });
  return sync;
});
