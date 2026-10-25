import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/app.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/widget_snapshot.dart';
import 'package:lukitas/recurring/recurring_repository.dart';
import 'package:lukitas/router.dart';
import 'package:lukitas/settings/settings_store.dart';
import 'package:lukitas/settings/url_opener.dart';

import '../capture/fakes.dart';
import '../entry/fakes.dart';
import '../feedback/fakes.dart';
import '../home/fakes.dart';
import '../recurring/fakes.dart';
import 'fakes.dart';

/// Opens URLs into a list instead of a browser.
class FakeUrlOpener implements UrlOpener {
  final opened = <Uri>[];

  /// Whether a browser is found.
  bool works = true;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return works;
  }
}

/// A model store holding downloaded models until they are deleted.
class DeletableModelStore extends FakeModelStore {
  bool installed = true;
  int deletes = 0;
  Object? deleteFailure;

  @override
  Future<String?> installedPath(String locale) async => installed ? '/models/$locale' : null;

  @override
  Future<void> deleteModels() async {
    deletes++;
    final failure = deleteFailure;
    if (failure != null) throw failure;
    installed = false;
  }
}

class SettingsEnv {
  SettingsEnv({
    required this.container,
    required this.auth,
    required this.settings,
    required this.flags,
    required this.opener,
    required this.models,
    required this.passkeys,
  });

  final ProviderContainer container;
  final FakeAuthApi auth;
  final FakeSettingsStore settings;

  /// The on/off settings, by key (`setting.sound`...).
  final Map<String, FakeFlagStore> flags;
  final FakeUrlOpener opener;
  final DeletableModelStore models;
  final FakePasskeys passkeys;

  GoRouter get router => container.read(routerProvider);
  StoredSession? get stored => container.read(sessionProvider).stored;
}

/// The whole app with everything outside the phone faked, signed in as a guest or not, in Spanish
/// unless told otherwise, and on [location] (Home when null).
Future<SettingsEnv> pumpSettingsApp(
  WidgetTester tester, {
  bool guest = false,
  bool passkeysSupported = false,
  bool modelsInstalled = true,
  Locale locale = const Locale('es'),
  String? location,
  FakeAuthApi? auth,
  FakeSettingsStore? settings,
  bool signedIn = true,
  List<Override> overrides = const [],
  bool settle = true,
  FakeHomeRepository? homeRepo,
}) async {
  final token = guest ? 'guest-token-0' : 'email-token-0';
  mockStorage(token: signedIn ? token : null, guest: guest);
  final fakeAuth = auth ?? FakeAuthApi();
  fakeAuth.guests[token] = guest;
  final fakeSettings = settings ?? FakeSettingsStore();
  final flags = <String, FakeFlagStore>{};
  final opener = FakeUrlOpener();
  final models = DeletableModelStore()..installed = modelsInstalled;
  final passkeys = FakePasskeys(isSupported: passkeysSupported);
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // What the whole app is faked with; a test's own override of the same provider replaces it.
  final defaults = <Override>[
    // The tests settle the frames: a running time bar would wait the toast's life out.
    toastBarAnimatesProvider.overrideWithValue(false),
    authApiProvider.overrideWithValue(fakeAuth),
    passkeysProvider.overrideWithValue(passkeys),
    settingsStoreProvider.overrideWithValue(fakeSettings),
    flagStoreProvider.overrideWith((ref, key) => flags.putIfAbsent(key, FakeFlagStore.new)),
    urlOpenerProvider.overrideWithValue(opener),
    modelStoreProvider.overrideWithValue(models),
    feedbackPlatformProvider.overrideWithValue(FakeFeedbackPlatform()),
    homeRepositoryProvider.overrideWithValue(homeRepo ?? FakeHomeRepository()),
    recurringRepositoryProvider.overrideWithValue(
      FakeRecurringRepository(homeRepo ?? FakeHomeRepository()),
    ),
    widgetStoreProvider.overrideWithValue(FakeWidgetStore()),
    homeCacheStoreProvider.overrideWithValue(FakeCacheStore()),
    widgetSnapshotWriterProvider.overrideWithValue(
      (summary, {required currency, required locale, required timezone}) async {},
    ),
  ];
  final replaced = {for (final o in overrides) o.origin};
  final container = ProviderContainer(
    overrides: [
      for (final o in defaults)
        if (!replaced.contains(o.origin)) o,
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LukitasApp()),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Something on screen never settles (quick capture listening): frames for two seconds.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  final env = SettingsEnv(
    container: container,
    auth: fakeAuth,
    settings: fakeSettings,
    flags: flags,
    opener: opener,
    models: models,
    passkeys: passkeys,
  );
  if (location != null) {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }
  return env;
}

/// Opens the menu of home's face button, where Ajustes and a guest's "Guarda tu progreso" are.
Future<void> openAccountMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home.account')));
  await tester.pumpAndSettle();
}
