import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/settings/url_opener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('lukitas/device');
  final calls = <MethodCall>[];

  tearDown(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'the address goes to lukitas/device as an openUrl call, and the answer comes back',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      final opened = await const ChannelUrlOpener().open(Uri.parse('https://app.example.com'));
      expect(opened, isTrue);
      expect(calls.single.method, 'openUrl');
      expect(calls.single.arguments, 'https://app.example.com');
    },
  );

  test('no browser answers false', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => false);
    expect(await const ChannelUrlOpener().open(Uri.parse('https://app.example.com')), isFalse);
  });

  test('a phone with no such channel, or a platform error, is false, not a crash', () async {
    expect(await const ChannelUrlOpener().open(Uri.parse('https://app.example.com')), isFalse);
    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'x'));
    expect(await const ChannelUrlOpener().open(Uri.parse('https://app.example.com')), isFalse);
  });

  group('what it will open', () {
    Future<bool> open(String address) async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      return const ChannelUrlOpener().open(Uri.parse(address));
    }

    test('mailto: goes to the channel exactly as it is, encoded subject and body included', () async {
      const mailto =
          'mailto:lukitas@andersonlaverde.com?subject=Lukitas%3A%20comentarios&body=%0A%0AVersi%C3%B3n%3A%201.2.3';
      expect(await open(mailto), isTrue);
      expect(calls.single.method, 'openUrl');
      expect(calls.single.arguments, mailto);
    });

    test('http and https still go', () async {
      expect(await open('http://10.0.2.2:3000'), isTrue);
      expect(await open('https://app.example.com/en'), isTrue);
      expect(calls, hasLength(2));
    });

    test('any other scheme is refused, and the channel is never asked', () async {
      for (final address in [
        'javascript:alert(1)',
        'JavaScript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end',
        'intent:#Intent;action=android.intent.action.CALL;end',
        'file:///data/data/com.andersonlaverde.lukitas/databases/x',
        'content://com.android.contacts/contacts',
        'tel:+34600000000',
        'sms:+34600000000?body=hi',
        'data:text/html,<script>alert(1)</script>',
        'market://details?id=x',
        'android-app://com.example',
        'ftp://example.com/file',
        '//example.com',
      ]) {
        expect(await open(address), isFalse, reason: address);
      }
      expect(calls, isEmpty);
    });
  });
}
