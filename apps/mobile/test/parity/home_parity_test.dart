@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:built_value/serializer.dart' show Serializer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/home/lukitas_face.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/ui/app_shell.dart';
import 'package:lukitas/ui/lk_theme.dart';
import 'package:lukitas/ui/press_button.dart';

import '../settings/fakes.dart' show FakeFlagStore;
import '../support/parity.dart';

/// Home against the stories that show it: `demo-screens--home-in-pesos`, `home-home--transactions`,
/// `home-home--empty-month` and `home-home--day-theme` (apps/web/app/demo/Demo.stories.tsx and
/// apps/web/app/features/home/Home.stories.tsx), each as Storybook shows it after its `play`
/// function.
///
/// The app reads what the story's fake API answered (test/parity/fixtures, saved after the play
/// function ran): the profile, the summary, the categories and the month's first page of
/// movements. Storybook pads every story by 16px around the screen and fixes the bottom bar to the
/// viewport, so the screen sits in a [ShellFrame] of the same padding.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

Object? _json(ParityFixture fixture, String path) => fixture.get(path).body;

T _read<T>(Serializer<T> serializer, Object? json) =>
    standardSerializers.deserializeWith(serializer, json) as T;

/// The story's API as a [HomeRepository]: it answers what the fixture holds. [pending] is a
/// movement the story's `play` function paid (the fixture was saved afterwards): it starts pending
/// here, so the app does what the story did.
class _FixtureRepository implements HomeRepository {
  _FixtureRepository(this.fixture, {this.pending}) {
    for (final item
        in (_json(fixture, '/v1/transactions?limit=50&month=2026-10')! as Map)['items'] as List) {
      final tx = _read(Transaction.serializer, item);
      items.add(
        tx.name == pending ? tx.rebuild((b) => b.status = TransactionStatusEnum.pending) : tx,
      );
    }
  }

  final ParityFixture fixture;
  final String? pending;
  final items = <Transaction>[];

  @override
  Future<HomeProfile> profile() async {
    final me = _json(fixture, '/v1/me')! as Map;
    return HomeProfile(
      id: me['id']! as String,
      currency: me['currency']! as String,
      timezone: me['timezone']! as String,
    );
  }

  @override
  Future<Summary> summary(String month) async =>
      _read(Summary.serializer, _json(fixture, '/v1/summary?month=$month'));

  @override
  Future<List<Category>> categories() async => [
    for (final c in _json(fixture, '/v1/categories?includeArchived=true')! as List)
      _read(Category.serializer, c),
  ];

  @override
  Future<TransactionsPage> transactions(String month, {String? cursor}) async =>
      TransactionsPage(List.of(items), null);

  @override
  Future<Transaction> markPaid(String id) async {
    final index = items.indexWhere((t) => t.id == id);
    return items[index] = items[index].rebuild((b) => b.status = TransactionStatusEnum.paid);
  }

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<Transaction> restore(String id) async => throw UnimplementedError();
}

class _NoCacheStore implements HomeCacheStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String json) async {}

  @override
  Future<void> clear() async {}
}

/// The demo's notice (apps/web/app/demo/DemoBanner.tsx), which the app does not have (spec §5): a
/// stand-in of the same size and look, so the screen under it can be compared. `border-b-2
/// bg-surface-sunken px-4 py-2`, a row of the notice (`text-[13px] leading-snug`) and a small
/// "Crear mi cuenta" button.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final text = TextStyle(
      fontFamily: LkText.textFamily,
      fontFamilyFallback: parityFallbackFamilies,
      fontSize: 13,
      height: 1.375,
      fontWeight: FontWeight.w700,
      leadingDistribution: TextLeadingDistribution.even,
      color: colors.ink,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(bottom: BorderSide(color: colors.stroke, width: 2)),
      ),
      child: Padding(
        // 8px inside the 2px border, which a DecoratedBox does not add.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8 + 2),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('🧪', style: text),
                  Expanded(
                    // Blink makes the three lines 53.63px (Flutter rounds each up to 18).
                    child: SizedBox(
                      height: 53.63,
                      child: Text(
                        'Estás en el demo: los datos son inventados y se borran al recargar.',
                        style: text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PressButton.text('Crear mi cuenta', size: PressSize.sm, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

/// Home in the story's frame, reading [repo].
Widget _home({bool banner = false, double? height}) => ShellFrame(
  // The web's page is as long as its content, and its background gradient with it.
  screenHeight: height,
  padding: const EdgeInsets.all(16),
  banner: banner ? const _DemoBanner() : null,
  // The web has no 🎤 (spec §5); the bar's own pictures show it.
  showMic: false,
  child: HomeScreen(menu: (context, close) => const SizedBox.shrink()),
);

List<Override> _overrides(_FixtureRepository repo) => [
  homeRepositoryProvider.overrideWithValue(repo),
  // Signed out as far as the cache goes: nothing is read or kept.
  homeCacheProvider.overrideWithValue(HomeCache(_NoCacheStore(), token: null)),
  widgetSnapshotWriterProvider.overrideWithValue(
    (summary, {required currency, required locale, required timezone}) async {},
  ),
  // The web's shots pin `Math.random` to 0: Lukitas says the first phrasing of every line.
  lukasVariantProvider.overrideWithValue(() => 1),
  flagStoreProvider.overrideWith((ref, key) => FakeFlagStore()),
];

/// Lukitas' sprite sheets decode in real time, which `pumpAndSettle` does not wait for: decode them
/// first, so the picture is taken with him in it.
Future<void> _sprites(WidgetTester t) async {
  await t.runAsync(() async {
    final context = t.element(find.byType(HomeScreen));
    for (final mood in LukitasMood.values) {
      await precacheImage(AssetImage(mood.sheet), context);
    }
  });
  await t.pumpAndSettle();
}

/// `userEvent.click` on a control, then a key: keyboard mode, where the focused control shows its
/// ring, as Chrome rings what a script's click focused.
Future<void> _keyboardMode(WidgetTester t) => t.sendKeyEvent(LogicalKeyboardKey.shift);

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('home parity: the demo\'s home in pesos, the banner on top ($theme)', (t) async {
      final fixture = ParityFixtures.load('demo-screens--home-in-pesos');
      await parityGolden(
        t,
        'home-in-pesos',
        _home(banner: true, height: 3402.02),
        theme: theme,
        overrides: _overrides(_FixtureRepository(fixture)),
        act: _sprites,
      );
    });

    testWidgets('home parity: Movimientos, the pending Spotify paid ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--transactions');
      await parityGolden(
        t,
        'home-transactions',
        _home(height: 1029.89),
        theme: theme,
        overrides: _overrides(_FixtureRepository(fixture, pending: 'Spotify')),
        act: (t) async {
          await _sprites(t);
          await t.tap(find.text('Movimientos'));
          await t.pumpAndSettle();
          // The story pays the pending subscription from its badge.
          await t.tap(find.text('PENDIENTE'));
          await t.pumpAndSettle();
          // A click focuses a button in Chrome; a tap does not in Flutter.
          Focus.of(t.element(find.text('PAGADO'))).requestFocus();
          // Its toast is gone by the time the picture is taken; Lukitas still talks about it.
          await t.pump(const Duration(seconds: 6));
          await t.pumpAndSettle();
          await _keyboardMode(t);
        },
      );
    });

    testWidgets('home parity: an empty month, the card for budgets ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--empty-month');
      await parityGolden(
        t,
        'home-empty-month',
        _home(),
        theme: theme,
        overrides: _overrides(_FixtureRepository(fixture)),
        act: (t) async {
          await _sprites(t);
          await t.tap(find.text('Movimientos'));
          await t.pumpAndSettle();
          // The story opens the add sheet from "Agregar gasto" and closes it again: the focus
          // goes back to the button, which Chrome rings.
          await _keyboardMode(t);
          Focus.of(t.element(find.text('AGREGAR GASTO'))).requestFocus();
        },
      );
    });
  }

  testWidgets('home parity: day theme, Movimientos tapped (day)', (t) async {
    final fixture = ParityFixtures.load('home-home--day-theme');
    await parityGolden(
      t,
      'home-day-theme',
      _home(height: 1029.89),
      theme: 'day',
      overrides: _overrides(_FixtureRepository(fixture)),
      act: (t) async {
        await _sprites(t);
        await t.tap(find.text('Movimientos'));
        await t.pumpAndSettle();
        await _keyboardMode(t);
      },
    );
  });
}
