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
}
