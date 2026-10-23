import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/api/passkey_offer.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/router.dart';

import '../entry/fakes.dart';
import '../settings/fakes.dart';

/// The web's `shouldOfferPasskey` (apps/web/app/auth/passkey.ts), on the phone.
void main() {
  late FakeAuthApi auth;
  late FakeSettingsStore store;
  setUp(() {
    auth = FakeAuthApi();
    store = FakeSettingsStore();
  });

  PasskeyOffer offer({bool supported = true}) => PasskeyOffer(
    auth: auth,
    passkeys: FakePasskeys(isSupported: supported),
    store: store,
  );

  group('due', () {
    test(
      'for an account with no passkey that has not answered, on a phone with passkeys',
      () async {
        expect(await offer().dueFor('tok'), 'user-1');
      },
    );

    test('not on a phone without passkeys, and the server is not asked', () async {
      expect(await offer(supported: false).dueFor('tok'), isNull);
      expect(auth.calls, isEmpty);
    });

    test('not for an account with a passkey, on this or any device', () async {
      auth.passkeysOnAccount = 2;
      expect(await offer().dueFor('tok'), isNull);
    });

    test('not for an account that answered here, and the list is not asked then', () async {
      final o = offer();
      await o.decide('user-1');
      auth.calls.clear();
      expect(await o.dueFor('tok'), isNull);
      expect(auth.calls.where((c) => c.startsWith('passkeyCount')), isEmpty);
    });

    test('for another account of the same phone', () async {
      final o = offer();
      await o.decide('user-1');
      auth.account = 'user-2';
      expect(await o.dueFor('tok'), 'user-2');
    });

    test('not when the list or the account cannot be read: skipped, never blocked on', () async {
      auth.failures['passkeyCount'] = const AuthFailure(status: 500);
      expect(await offer().dueFor('tok'), isNull);
      auth.failures['accountId'] = const AuthFailure(status: 0);
      expect(await offer().dueFor('tok'), isNull);
    });
  });

  group('the answer', () {
    test('is kept as a list of account ids, once each', () async {
      final o = offer();
      await o.decide('user-1');
      await o.decide('user-1');
      await o.decide('user-2');
      expect(store.values[passkeyOfferedKey], '["user-1","user-2"]');
    });

    test('a kept value that is not a list is as if nothing were kept', () async {
      store.values[passkeyOfferedKey] = '{"oops":1}';
      expect(await offer().dueFor('tok'), 'user-1');
      store.values[passkeyOfferedKey] = 'not json';
      expect(await offer().dueFor('tok'), 'user-1');
    });
  });

  group('where the session sends a person with the offer pending', () {
    const guestless = StoredSession(token: 't', guest: false);
    final pending = SessionState.signedIn(guestless, offerPasskeyFor: 'user-1');
    const none = SessionState.signedIn(guestless);
    const guest = SessionState.signedIn(StoredSession(token: 't', guest: true));

    test('to the offer from the sign-in screens and home', () {
      for (final path in ['/', '/entry/email', '/entry', '/loading']) {
        expect(sessionRedirect(pending, Uri.parse(path)), '/entry/passkey-offer', reason: path);
      }
    });

    test('the offer itself, the magic link and other screens stay', () {
      for (final path in ['/entry/passkey-offer', '/auth/verify', '/settings', '/insights']) {
        expect(sessionRedirect(pending, Uri.parse(path)), isNull, reason: path);
      }
    });

    test('the offer\'s address is for that moment only, and never a guest\'s', () {
      expect(sessionRedirect(none, Uri.parse('/entry/passkey-offer')), '/');
      expect(sessionRedirect(guest, Uri.parse('/entry/passkey-offer')), '/');
      expect(sessionRedirect(SessionState.signedOut, Uri.parse('/entry/passkey-offer')), '/entry');
    });
  });
}
