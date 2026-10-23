import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_sheet.dart';
import 'package:lukitas/capture/capture_sheet.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/entry/entry_screen.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/progress/progress_screen.dart';
import 'package:lukitas/launch/launch_links.dart';
import 'package:lukitas/router.dart';

import '../capture/fakes.dart';
import '../home/fakes.dart';
import '../settings/harness.dart';

/// The links Android hands the app: one it was started with, and later ones.
class FakeLaunchLinks implements LaunchLinkSource {
  FakeLaunchLinks([this.initial]);

  String? initial;
  final _later = StreamController<String>.broadcast();

  @override
  Future<String?> takeInitial() async {
    final link = initial;
    initial = null;
    return link;
  }

  @override
  Stream<String> get links => _later.stream;

  void open(String link) => _later.add(link);
}

void main() {
  group('reading a link', () {
    test('lukitas://add and lukitas://capture, nothing else', () {
      expect(launchActionOf('lukitas://add'), LaunchAction.add);
      expect(launchActionOf('lukitas://capture'), LaunchAction.capture);
      expect(launchActionOf('lukitas://capture/'), LaunchAction.capture);
      expect(launchActionOf('lukitas://due'), LaunchAction.due);
      expect(launchActionOf('lukitas://progress'), LaunchAction.progress);
      expect(launchActionOf('lukitas://settings'), isNull);
      expect(launchActionOf('https://add'), isNull);
      expect(launchActionOf('https://app-lukas.andersonlaverde.com/auth/verify?code=1'), isNull);
      expect(launchActionOf(''), isNull);
      expect(launchActionOf(null), isNull);
    });
  });

  testWidgets('＋ at a cold start: the add sheet opens on home once the session has loaded', (
    tester,
  ) async {
    final env = await pumpSettingsApp(
      tester,
      overrides: [launchLinkSourceProvider.overrideWithValue(FakeLaunchLinks('lukitas://add'))],
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AddSheet), findsOneWidget);
    expect(env.router.state.uri.path, '/');
  });

  testWidgets('🎤 at a cold start: capture opens, listening', (tester) async {
    final engine = FakeSpeechEngine()..hold = true;
    await pumpSettingsApp(
      tester,
      settle: false,
      overrides: [
        launchLinkSourceProvider.overrideWithValue(FakeLaunchLinks('lukitas://capture')),
        speechEngineProvider.overrideWithValue(engine),
      ],
    );
    expect(find.byType(CaptureSheet), findsOneWidget);
    expect(tester.widget<CaptureSheet>(find.byType(CaptureSheet)).listen, isTrue);
    expect(engine.listens, 1, reason: 'listening, not waiting for a tap');
    await engine.held!.close();
  });

  testWidgets('a link while the app runs goes back to home from any screen and opens there', (
    tester,
  ) async {
    final links = FakeLaunchLinks();
    final env = await pumpSettingsApp(
      tester,
      location: '/settings',
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    expect(find.byType(AddSheet), findsNothing);

    links.open('lukitas://add');
    await tester.pumpAndSettle();
    expect(env.router.state.uri.path, '/');
    expect(find.byType(AddSheet), findsOneWidget);
  });

  testWidgets('the "Hoy vence…" notice opens home from any screen, with no sheet over it', (tester) async {
    final links = FakeLaunchLinks();
    final env = await pumpSettingsApp(
      tester,
      location: '/settings',
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    links.open('lukitas://due');
    await tester.pumpAndSettle();
    expect(env.router.state.uri.path, '/');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AddSheet), findsNothing);
    expect(find.byType(CaptureSheet), findsNothing);
  });

  testWidgets('the notice at a cold start opens home, and a sheet already open gives way', (tester) async {
    final links = FakeLaunchLinks();
    await pumpSettingsApp(tester, overrides: [launchLinkSourceProvider.overrideWithValue(links)]);
    links.open('lukitas://add');
    await tester.pumpAndSettle();
    expect(find.byType(AddSheet), findsOneWidget);

    links.open('lukitas://due');
    await tester.pumpAndSettle();
    expect(find.byType(AddSheet), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the notice brings a home that was already loaded up to date', (tester) async {
    final links = FakeLaunchLinks();
    final env = await pumpSettingsApp(
      tester,
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    final repo = env.container.read(homeRepositoryProvider) as FakeHomeRepository;
    final before = repo.calls.where((c) => c.startsWith('summary')).length;
    links.open('lukitas://due');
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c.startsWith('summary')).length, before + 1);
  });

  testWidgets('the guest warning opens Guarda tu progreso, over home', (tester) async {
    final links = FakeLaunchLinks();
    final env = await pumpSettingsApp(
      tester,
      guest: true,
      location: '/settings',
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    links.open('lukitas://progress');
    await tester.pumpAndSettle();
    expect(env.router.state.uri.path, '/progress');
    expect(find.byType(ProgressScreen), findsOneWidget);
    // Back is home.
    env.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('once the account has an email, the guest warning just opens home', (tester) async {
    final links = FakeLaunchLinks();
    final env = await pumpSettingsApp(
      tester,
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    links.open('lukitas://progress');
    await tester.pumpAndSettle();
    expect(env.router.state.uri.path, '/');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signed out, the notice opens nothing', (tester) async {
    final links = FakeLaunchLinks('lukitas://due');
    await pumpSettingsApp(
      tester,
      signedIn: false,
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    expect(find.byType(EntryScreen), findsOneWidget);
  });

  testWidgets('a second link replaces the sheet the first one opened', (tester) async {
    final links = FakeLaunchLinks('lukitas://add');
    final engine = FakeSpeechEngine()..hold = true;
    await pumpSettingsApp(
      tester,
      overrides: [
        launchLinkSourceProvider.overrideWithValue(links),
        speechEngineProvider.overrideWithValue(engine),
      ],
    );
    expect(find.byType(AddSheet), findsOneWidget);

    links.open('lukitas://capture');
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(AddSheet), findsNothing);
    expect(find.byType(CaptureSheet), findsOneWidget);
    expect(engine.listens, 1);
    await engine.held!.close();
  });

  group('an add sheet with the person\'s input in it is kept', () {
    Future<FakeLaunchLinks> typedInSheet(WidgetTester tester, FakeSpeechEngine engine) async {
      final links = FakeLaunchLinks('lukitas://add');
      await pumpSettingsApp(
        tester,
        overrides: [
          launchLinkSourceProvider.overrideWithValue(links),
          speechEngineProvider.overrideWithValue(engine),
        ],
      );
      expect(find.byType(AddSheet), findsOneWidget);
      await tester.tap(find.byKey(const Key('keypad.4')));
      await tester.tap(find.byKey(const Key('keypad.2')));
      await tester.pumpAndSettle();
      return links;
    }

    for (final link in ['lukitas://capture', 'lukitas://add', 'lukitas://due', 'lukitas://progress']) {
      testWidgets('$link leaves it as it is', (tester) async {
        final engine = FakeSpeechEngine()..hold = true;
        final links = await typedInSheet(tester, engine);
        final typed = find.descendant(of: find.byType(AddSheet), matching: find.textContaining('42'));
        expect(typed, findsWidgets);

        links.open(link);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(AddSheet), findsOneWidget);
        expect(typed, findsWidgets, reason: 'what was typed is still there');
        expect(find.byType(CaptureSheet), findsNothing);
        expect(find.byType(ProgressScreen), findsNothing);
        expect(engine.listens, 0, reason: 'the microphone never opened');
      });
    }

    testWidgets('once it closes, the next link opens again', (tester) async {
      final engine = FakeSpeechEngine()..hold = true;
      final links = await typedInSheet(tester, engine);
      Navigator.of(tester.element(find.byType(AddSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(AddSheet), findsNothing);

      links.open('lukitas://capture');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CaptureSheet), findsOneWidget);
      await engine.held!.close();
    });
  });

  testWidgets('signed out, a link lands on the entry screen and opens nothing', (tester) async {
    final links = FakeLaunchLinks('lukitas://capture');
    final env = await pumpSettingsApp(
      tester,
      signedIn: false,
      overrides: [launchLinkSourceProvider.overrideWithValue(links)],
    );
    expect(find.byType(EntryScreen), findsOneWidget);
    expect(find.byType(CaptureSheet), findsNothing);

    links.open('lukitas://add');
    await tester.pumpAndSettle();
    expect(find.byType(EntryScreen), findsOneWidget);
    expect(find.byType(AddSheet), findsNothing);
    expect(env.container.read(routerProvider).state.uri.path, '/entry');
  });

  testWidgets('a link that is not one of the two does nothing', (tester) async {
    final links = FakeLaunchLinks('lukitas://somewhere');
    await pumpSettingsApp(tester, overrides: [launchLinkSourceProvider.overrideWithValue(links)]);
    links.open('https://example.com/add');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AddSheet), findsNothing);
    expect(find.byType(CaptureSheet), findsNothing);
  });
}
