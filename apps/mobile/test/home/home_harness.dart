import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_repository.dart';
import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_header.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/theme.dart';

import '../settings/fakes.dart' show FakeFlagStore;
import 'fakes.dart';
import 'fixtures.dart';

/// 2026-10-22 10:00 in Bogota (UTC-5).
final testNow = DateTime.utc(2026, 10, 22, 15);

/// What the widget was told, one entry per load of the summary.
class WrittenSnapshot {
  WrittenSnapshot(this.summary, this.currency, this.locale);
  final Summary summary;
  final String currency;
  final String locale;
}

class HomeHarness {
  HomeHarness(this.repo, this.container, this.snapshots, this.edited);

  final FakeHomeRepository repo;
  final ProviderContainer container;
  final List<WrittenSnapshot> snapshots;
  final List<Transaction> edited;
}

/// Home in front of [repo], on a phone-sized screen, in Spanish unless told otherwise.
Future<HomeHarness> pumpHome(
  WidgetTester tester,
  FakeHomeRepository repo, {
  Locale locale = const Locale('es'),
  ThemeMode themeMode = ThemeMode.dark,
  Size size = const Size(390, 844),
  bool withEdit = false,
  bool settle = true,
  FakeCacheStore? cacheStore,
  String? token = 't1',
  DateTime? now,
  DateTime Function()? clock,
  AddRepository? addRepo,
  List<Override> overrides = const [],
  double textScale = 1,
  String? initialMonth,
  bool withMenu = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final snapshots = <WrittenSnapshot>[];
  final edited = <Transaction>[];
  final flags = <String, FakeFlagStore>{};
  final container = ProviderContainer(
    overrides: [
      // What a person put away ("Ahora no") is kept in memory, unless the test keeps flags itself.
      if (!overrides.any((o) => '${o.origin}'.contains('FlagStore')))
        flagStoreProvider.overrideWith((ref, key) => flags.putIfAbsent(key, FakeFlagStore.new)),
      homeRepositoryProvider.overrideWithValue(repo),
      if (addRepo != null) addRepositoryProvider.overrideWithValue(addRepo),
      homeCacheProvider.overrideWithValue(HomeCache(cacheStore ?? FakeCacheStore(), token: token)),
      clockProvider.overrideWithValue(clock ?? () => now ?? testNow),
      lukasVariantProvider.overrideWithValue(() => 1),
      widgetSnapshotWriterProvider.overrideWithValue(
        (summary, {required currency, required locale, required timezone}) async =>
            snapshots.add(WrittenSnapshot(summary, currency, locale)),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: dayTheme,
        darkTheme: nightTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        builder: textScale == 1
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
        home: HomeScreen(
          onEdit: withEdit ? edited.add : null,
          initialMonth: initialMonth,
          menu: withMenu
              ? (context, close) =>
                    HomeMenuLink(key: const Key('menu.entry'), label: 'Ajustes', onPressed: close)
              : null,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
    // Riverpod's dispose task for a tree this one replaced.
    await tester.pump(Duration.zero);
  }
  return HomeHarness(repo, container, snapshots, edited);
}

/// A month in progress: budgets, some paid movements and one pending rent due later.
FakeHomeRepository monthWithBudgets() => FakeHomeRepository(
  budgetTotal: 200000000,
  categoryList: [
    category('cat-groceries', 'Supermercado', icon: '🛒'),
    category('cat-home', 'Hogar', icon: '🏠', color: 'orange'),
  ],
  items: [
    tx(
      'rent',
      '2026-10-25',
      -50000000,
      name: 'Arriendo',
      status: 'pending',
      categoryId: 'cat-home',
    ),
    tx('coffee', '2026-10-22', -450000, name: 'Café'),
    tx('lunch', '2026-10-22', -2800000, name: 'Almuerzo'),
    tx('market', '2026-10-21', -18000000, name: 'Mercado'),
    tx('salary', '2026-10-01', 300000000, name: 'Nómina', categoryId: 'cat-home'),
  ],
);
