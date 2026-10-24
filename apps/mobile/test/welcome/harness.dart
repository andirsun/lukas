import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/files/files_channel.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_repository.dart';
import 'package:lukitas/welcome/onboarding_repository.dart';
import 'package:lukitas/welcome/welcome_controller.dart';

import '../entry/fakes.dart';
import '../import/fakes.dart' show FakeFilesChannel;
import '../settings/fakes.dart';
import '../settings/harness.dart';
import 'fakes.dart';

export '../import/fakes.dart' show FakeFilesChannel;

/// The browser the web's `WelcomeStage` pretends to be: in Bogotá, in Colombian Spanish.
const bogota = WelcomeDevice(languages: ['es-CO'], timeZone: 'America/Bogota');

/// "Now": 22 October 2026, 15:00 UTC.
final now = DateTime.utc(2026, 10, 22, 15);

/// The sample Budge file, as the picker hands it over.
final budgeFile = PickedFile('budge.csv', Uint8List.fromList('Date,Payment\n'.codeUnits));

class WelcomeEnv {
  WelcomeEnv(this.app, this.world, this.files, this.settings, this.auth);

  final SettingsEnv app;
  final WelcomeWorld world;
  final FakeFilesChannel files;
  final FakeSettingsStore settings;
  final FakeAuthApi auth;

  String get location => app.router.routerDelegate.currentConfiguration.last.matchedLocation;
  bool get pending => app.container.read(sessionProvider).onboardingPending;
}

/// The whole app, signed in as a new email account (no `onboardingCompletedAt`: it is sent to the
/// welcome), against [world], in Spanish unless told otherwise, on [location] when given.
/// [settings] and [auth] outlive the app: a second call with the same ones is the app started again.
Future<WelcomeEnv> pumpWelcome(
  WidgetTester tester,
  WelcomeWorld world, {
  String? location,
  Locale locale = const Locale('es'),
  WelcomeDevice device = bogota,
  FakeSettingsStore? settings,
  FakeAuthApi? auth,
  bool pending = true,
  bool guest = false,
  List<Override> extra = const [],
}) async {
  final fakeAuth = auth ?? FakeAuthApi();
  fakeAuth.pendingOnboarding['email-token-0'] = pending;
  final store = settings ?? FakeSettingsStore();
  final files = FakeFilesChannel();
  final overrides = <Override>[
    homeRepositoryProvider.overrideWithValue(world),
    onboardingRepositoryProvider.overrideWithValue(world),
    importRepositoryProvider.overrideWithValue(world),
    filesChannelProvider.overrideWithValue(files),
    welcomeDeviceProvider.overrideWithValue(device),
    clockProvider.overrideWithValue(() => now),
    ...extra,
  ];
  final app = await pumpSettingsApp(
    tester,
    auth: fakeAuth,
    settings: store,
    guest: guest,
    locale: locale,
    overrides: overrides,
    location: location,
  );
  return WelcomeEnv(app, world, files, store, fakeAuth);
}

Finder key(String key) => find.byKey(Key(key));

Future<void> tap(WidgetTester tester, String k) async {
  await tester.ensureVisible(key(k));
  await tester.pumpAndSettle();
  await tester.tap(key(k));
  await tester.pumpAndSettle();
}

/// The text of a widget found by key (a `Text`, or an editable field).
String shown(WidgetTester tester, String k) {
  final widget = tester.widget(key(k));
  return widget is Text ? widget.data! : (widget as EditableText).controller.text;
}

/// Taps "Siguiente" or "Saltar" ... and waits for the step it leads to.
Future<void> go(WidgetTester tester, String k) => tap(tester, k);

/// Whether a step is on screen.
bool onStep(String id) => key('welcome.step.$id').evaluate().isNotEmpty;
