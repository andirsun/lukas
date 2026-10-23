import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../home/home_cache.dart';
import '../home/widget_sync.dart';
import 'auth_api.dart';
import 'client.dart';
import 'device.dart';
import 'server_url.dart';
import 'passkeys.dart';

export 'auth_api.dart' show authApiProvider;
export 'passkeys.dart' show passkeysProvider, passkeysSupportedProvider;

/// The session kept on the phone: the bearer token, and whether it belongs to a guest.
class StoredSession {
  const StoredSession({required this.token, required this.guest});

  final String token;

  /// A guest's token is the only way back to their account (it has no email), so the app never
  /// replaces it without asking (spec section 4.2).
  final bool guest;
}

/// The session token in `flutter_secure_storage`, which encrypts it with a key kept in the Android
/// Keystore (spec section 6.3).
class SessionStore {
  SessionStore([FlutterSecureStorage storage = const FlutterSecureStorage()]) : _storage = storage;

  static const tokenKey = 'session.token';
  static const guestKey = 'session.guest';

  final FlutterSecureStorage _storage;

  /// The stored session, or null. A token whose guest flag is missing reads as a guest: the safe
  /// side, since the app then asks before replacing it (and /v1/me corrects the flag).
  Future<StoredSession?> read() async {
    try {
      final token = await _storage.read(key: tokenKey);
      if (token == null || token.isEmpty) return null;
      final guest = await _storage.read(key: guestKey);
      return StoredSession(token: token, guest: guest != 'false');
    } on PlatformException {
      // The Keystore key is gone (a restored backup, a reset lock screen): nothing usable.
      return null;
    }
  }

  Future<void> write(String token, {required bool guest}) async {
    // The flag first: a token is never stored next to a stale "not a guest".
    await _storage.write(key: guestKey, value: guest ? 'true' : 'false');
    await _storage.write(key: tokenKey, value: token);
  }

  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: guestKey);
  }
}

enum SessionStatus { loading, signedOut, signedIn }

/// Where the person stands: still reading the store, signed out, or signed in with [stored].
class SessionState {
  const SessionState._(this.status, this.stored);

  static const loading = SessionState._(SessionStatus.loading, null);
  static const signedOut = SessionState._(SessionStatus.signedOut, null);

  const SessionState.signedIn(StoredSession session) : this._(SessionStatus.signedIn, session);

  final SessionStatus status;
  final StoredSession? stored;

  bool get isGuest => stored?.guest ?? false;
}

/// A sign-in with another account, or a sign-out, was asked for while a guest is signed in. Going
/// ahead would leave the guest's account unreachable, so the caller must first offer to save the
/// guest's progress (claim the email) or warn, and only then pass `replaceGuest: true` (sign-in)
/// or `discardGuest: true` (sign-out).
class GuestInTheWay implements Exception {
  const GuestInTheWay();
}

/// The sign-in flows (spec sections 4 and 6.1): a guest, an email code or magic link, or a
/// passkey; and the guest's claim of an email. Every token lands in [SessionStore].
class SessionController extends Notifier<SessionState> {
  /// The most a sign-out waits for the server to be told.
  static const signOutWait = Duration(seconds: 10);

  /// Done once the stored session has been read.
  late Future<void> ready;

  /// Done once the stored session has also been checked against the server (`/v1/me`).
  late Future<void> refreshed;

  SessionStore get _store => ref.read(sessionStoreProvider);
  AuthApi get _auth => ref.read(authApiProvider);
  Passkeys get _passkeys => ref.read(passkeysProvider);

  @override
  SessionState build() {
    final restored = _restore();
    ready = restored.then((_) {});
    refreshed = restored.then((stored) async {
      if (stored != null) await _refresh(stored);
    });
    return SessionState.loading;
  }

  Future<StoredSession?> _restore() async {
    final stored = await _store.read();
    state = stored == null ? SessionState.signedOut : SessionState.signedIn(stored);
    return stored;
  }

  /// Asks the server who the stored token belongs to: a token it no longer knows signs out; a guest
  /// that has meanwhile claimed an email (or the other way round) gets the right flag. Offline,
  /// the stored session stands.
  Future<void> _refresh(StoredSession stored) async {
    try {
      final guest = await _auth.isGuest(stored.token);
      if (state.stored?.token != stored.token) return;
      if (guest != stored.guest) await _signedIn(stored.token, guest: guest);
    } on AuthFailure catch (failure) {
      if (failure.status == 401 && state.stored?.token == stored.token) {
        await _forgetWidget();
        await _store.clear();
        state = SessionState.signedOut;
      }
    }
  }

  Future<void> _signedIn(String token, {required bool guest}) async {
    // Another token is another session (a guest replaced by an email account, say): what the old
    // one left on this phone goes with it. The same token (a claim, a corrected flag) keeps it.
    final previous = state.stored?.token;
    if (previous != null && previous != token) await _forgetWidget();
    await _store.write(token, guest: guest);
    state = SessionState.signedIn(StoredSession(token: token, guest: guest));
    ref.read(widgetSyncProvider).signedIn();
  }

  void _guardGuest(bool replaceGuest) {
    if (state.isGuest && !replaceGuest) throw const GuestInTheWay();
  }

  String _requireToken() {
    final token = state.stored?.token;
    if (token == null) throw StateError('Not signed in');
    return token;
  }

  /// "Probar sin correo": a new guest.
  Future<void> startGuest() async {
    await ready;
    final token = await _auth.signInAsGuest();
    await _signedIn(token, guest: true);
  }

  /// Emails a sign-in code and magic link. Throws [GuestInTheWay] for a guest unless
  /// [replaceGuest] (the person was warned).
  Future<void> sendCode(String email, {bool replaceGuest = false}) async {
    await ready;
    _guardGuest(replaceGuest);
    await _auth.sendCode(email);
  }

  /// Signs in with the emailed code (typed, or from the magic link). Guarded like [sendCode].
  Future<void> verifyCode(String email, String code, {bool replaceGuest = false}) async {
    await ready;
    _guardGuest(replaceGuest);
    final token = await _auth.verifyCode(email, code);
    await _signedIn(token, guest: false);
  }

  /// "Guardar mi progreso": mails the signed-in guest a code to claim [email].
  Future<void> claimEmail(String email) async {
    await ready;
    if (!state.isGuest) throw StateError('Only a guest claims an email');
    await _auth.claimSend(_requireToken(), email);
  }

  /// Gives the guest [email] with the claim code: the same user and token, no longer a guest.
  Future<void> confirmClaim(String email, String code) async {
    await ready;
    if (!state.isGuest) throw StateError('Only a guest claims an email');
    final token = _requireToken();
    await _auth.claimVerify(token, email, code);
    await _signedIn(token, guest: false);
  }

  /// "Entrar con huella". Guarded like [sendCode].
  Future<void> signInWithPasskey({bool replaceGuest = false}) async {
    await ready;
    _guardGuest(replaceGuest);
    final challenge = await _auth.passkeySignInOptions();
    final assertion = await _passkeys.get(challenge.optionsJson);
    await _finishPasskeySignIn(challenge, assertion);
  }

  /// The email screen, on opening: signs in with a passkey the phone can offer at once (one made on
  /// the web and held by Proton Pass, say), showing nothing when there is none. True when it signed
  /// in. False, silently, when there was no passkey, the person closed the sheet, or the phone or
  /// the connection could not even ask: the email works as ever. Only a passkey the person chose
  /// and the server then refused throws [AuthFailure]. Guarded like [sendCode]: it never replaces
  /// a guest's session ([GuestInTheWay], before anything is asked).
  Future<bool> signInWithAvailablePasskey() async {
    await ready;
    _guardGuest(false);
    final PasskeyChallenge challenge;
    final String assertion;
    try {
      challenge = await _auth.passkeySignInOptions();
      assertion = await _passkeys.getAvailable(challenge.optionsJson);
    } on AuthFailure {
      return false;
    }
    await _finishPasskeySignIn(challenge, assertion);
    return true;
  }

  Future<void> _finishPasskeySignIn(PasskeyChallenge challenge, String assertion) async {
    final token = await _auth.passkeySignIn(challenge, assertion);
    // A guest can add a passkey (spec section 4.3), so the passkey may belong to one: ask, so a
    // guest stays a guest (warned on sign-out, offered "Guarda tu progreso"). If the server can't
    // say, the safe side is a guest, which /v1/me corrects at the next start.
    bool guest;
    try {
      guest = await _auth.isGuest(token);
    } on AuthFailure {
      guest = true;
    }
    await _signedIn(token, guest: guest);
  }

  /// Adds a passkey on this phone to the signed-in user, a guest included (spec section 4.3).
  Future<void> registerPasskey() async {
    await ready;
    final token = _requireToken();
    final challenge = await _auth.passkeyRegisterOptions(token);
    final attestation = await _passkeys.create(challenge.optionsJson);
    await _auth.passkeyRegister(token, challenge, attestation);
  }

  /// Signs out. A guest's account has no email, so once the token is gone nobody can reach it:
  /// this throws [GuestInTheWay], changing nothing, unless [discardGuest] says the person was
  /// warned (Settings does) or the server itself has dropped the session (a 401).
  Future<void> signOut({bool discardGuest = false}) async {
    await ready;
    if (state.isGuest && !discardGuest) throw const GuestInTheWay();
    final token = state.stored?.token;
    if (token != null) {
      try {
        // Best effort, and never for long: a server that is down (the reason someone changes
        // server) must not hold the sign-out up. Forgetting the session here is what matters.
        await _auth.signOut(token).timeout(signOutWait);
      } on Object {
        // Offline, not answering, already gone, a 5xx, a failed TLS handshake, a bug in the call:
        // whatever went wrong there, the session is forgotten here all the same.
      }
    }
    await _forgetWidget();
    await _store.clear();
    state = SessionState.signedOut;
  }

  /// The most a sign-out waits for the widget's storage.
  static const widgetWait = Duration(seconds: 2);

  /// The widget on the home screen and the home cache hold the signed-in person's figures: signed
  /// out, neither may show them to the next person. The widget gets its signed-out snapshot
  /// ("Abre Lukitas para empezar", no figure) and is redrawn (Review Focus 4) **before** the
  /// session is forgotten: if the process dies in between, the session is still there and the
  /// next start puts things right, while the other order would leave the figure on the home
  /// screen with nobody signed in. Waited for at most [widgetWait]: signing out never hangs on
  /// the widget's storage. The home cache is not waited for.
  Future<void> _forgetWidget() async {
    unawaited(clearHomeCache(ref.read(homeCacheStoreProvider)));
    await ref.read(widgetSyncProvider).signedOut().timeout(widgetWait, onTimeout: () {});
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// The API client for the signed-in session (rebuilt when the token changes).
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient.forServer(
    ref.watch(serverUrlProvider),
    token: ref.watch(sessionProvider.select((s) => s.stored?.token)),
    hints: ref.watch(deviceHintsProvider),
  ),
);
