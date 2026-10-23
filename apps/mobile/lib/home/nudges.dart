import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback/stored_flag.dart';

/// The cards home shows an account that skipped the setup (the web's `Nudges`). The app has the
/// budgets one; the history import stays on the web (spec 3.4).
enum Nudge {
  budgets('budgets');

  const Nudge(this.id);
  final String id;
}

/// Whether a person put a nudge away ("Ahora no"), for good, on this phone (the web's
/// `useDismissed`, kept per person and per device). Null until it has been read, so a card that
/// was put away never shows for a moment at the start; unreadable counts as not put away.
class NudgeDismissed extends Notifier<bool?> {
  NudgeDismissed(this.key);

  /// `home.dismissed.<user id>.<nudge id>`.
  final String key;

  var _chosen = false;

  FlagStore get _store => ref.read(flagStoreProvider(key));

  @override
  bool? build() {
    unawaited(_read());
    return null;
  }

  Future<void> _read() async {
    bool? kept;
    try {
      kept = await _store.read();
    } on Object {
      // Unreadable: not put away.
    }
    if (!_chosen && ref.mounted) state = kept ?? false;
  }

  /// Puts the card away, and keeps that.
  Future<void> dismiss() async {
    _chosen = true;
    state = true;
    try {
      await _store.write(true);
    } on Object {
      // Not kept: the card is back at the next start.
    }
  }
}

final nudgeDismissedProvider = NotifierProvider.family<NudgeDismissed, bool?, String>(
  NudgeDismissed.new,
);

/// The key of [nudge] for the person [userId].
String nudgeKey(String userId, Nudge nudge) => 'home.dismissed.$userId.${nudge.id}';
