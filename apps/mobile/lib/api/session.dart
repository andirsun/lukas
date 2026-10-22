import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_api.dart';
import 'client.dart';
import 'device.dart';
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

/// An email or passkey sign-in was asked for while a guest is signed in. Going ahead would start a
/// second user and leave the guest's account unreachable, so the caller must first offer to save
/// the guest's progress (claim the email) or warn, and only then pass `replaceGuest: true`.
class GuestInTheWay implements Exception {
  const GuestInTheWay();
}

/// The sign-in flows (spec sections 4 and 6.1): a guest, an email code or magic link, or a
/// passkey; and the guest's claim of an email. Every token lands in [SessionStore].
class SessionController extends Notifier<SessionState> {
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
        await _store.clear();
        state = SessionState.signedOut;
      }
    }
  }

  Future<void> _signedIn(String token, {required bool guest}) async {
    await _store.write(token, guest: guest);
    state = SessionState.signedIn(StoredSession(token: token, guest: guest));
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
    final token = await _auth.passkeySignIn(challenge, assertion);
    await _signedIn(token, guest: false);
  }

  /// Adds a passkey on this phone to the signed-in user, a guest included (spec section 4.3).
  Future<void> registerPasskey() async {
    await ready;
    final token = _requireToken();
    final challenge = await _auth.passkeyRegisterOptions(token);
    final attestation = await _passkeys.create(challenge.optionsJson);
    await _auth.passkeyRegister(token, challenge, attestation);
  }

  Future<void> signOut() async {
    await ready;
    final token = state.stored?.token;
    if (token != null) {
      try {
        await _auth.signOut(token);
      } on AuthFailure {
        // Offline or already gone: forgetting it here is what matters.
      }
    }
    await _store.clear();
    state = SessionState.signedOut;
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
