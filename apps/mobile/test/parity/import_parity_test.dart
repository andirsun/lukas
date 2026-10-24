@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/budgets/budgets_repository.dart';
import 'package:lukitas/files/files_channel.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_repository.dart';
import 'package:lukitas/import/import_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../import/fakes.dart' show importOf, sampleStats;
import '../support/parity.dart';
import '../support/parity_home.dart';

/// The import page against the stories that show it (`onboarding-import-page--*`,
/// apps/web/app/features/onboarding/ImportPage.stories.tsx), each as Storybook shows it after its
/// `play` function: the sources, Budge's how-to, the preview (the rows with problems opened, the
/// warning before a currency switch, in English), and the result with the budgets (saved too).
///
/// The page reads the profile and the categories the story's fake API answered
/// (test/parity/fixtures). The file's preview is that fake API's too, as the app reads it from
/// `POST /v1/imports` (`SAMPLE_PREVIEW` in apps/web/app/features/onboarding/story-harness.tsx):
/// a POST is not in the fixture, so the same sample is written here, and the account switches to
/// the file's currency on the confirm, as the story's API does. Update the goldens with
/// `flutter test --update-goldens test/parity`, then compare with `dart run tool/parity/compose.dart`
/// (docs/mobile/parity.md).

/// The story's account: [currency] until a confirm that adopts the file's.
class _World {
  _World({required this.currency, this.dropsBudgets = false});

  String currency;

  /// The file is in EUR and the account is not: confirming switches it.
  bool get adopts => currency != 'EUR';

  /// The account has budgets that go with the switch.
  final bool dropsBudgets;
}

/// The story's API as the page's home: the profile (in the currency the account has now) and the
/// categories the fixture holds (the answer after the story played, as the web's last picture shows).
class _StoryHome implements HomeRepository {
  _StoryHome(this.fixture, this.world);

  final ParityFixture fixture;
  final _World world;

  @override
  Future<HomeProfile> profile() async {
    final me = fixtureJson(fixture, '/v1/me')! as Map;
    return HomeProfile(
      id: me['id']! as String,
      currency: world.currency,
      timezone: me['timezone']! as String,
      email: me['email'] as String? ?? '',
    );
  }

  @override
  Future<Summary> summary(String month) async => Summary(
    (b) => b
      ..month = month
      ..budgetTotal = 0
      ..spent = 0
      ..remaining = 0
      ..income = 0
      ..balance = 0,
  );

  @override
  Future<List<Category>> categories() async => [
    for (final c in fixtureJson(fixture, '/v1/categories?includeArchived=true')! as List)
      readBuilt(Category.serializer, c),
  ];

  @override
  Future<TransactionsPage> transactions(String month, {String? cursor}) async =>
      const TransactionsPage([], null);

  @override
  Future<bool> hasTransactions() async => false;

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<Transaction> restore(String id) => throw UnimplementedError();

  @override
  Future<Transaction> markPaid(String id) => throw UnimplementedError();
}

/// `POST /v1/imports` and its confirm, as the story's API answers them.
class _StoryImport implements ImportRepository {
  _StoryImport(this.world);

  final _World world;

  @override
  Future<FileImport> upload(String fileName, Uint8List bytes) async => importOf({
    ...sampleStats(),
    'duplicates': 0,
    'adoptsCurrency': world.adopts,
    'dropsBudgets': world.adopts && world.dropsBudgets,
  }, id: 'preview-1');

  @override
  Future<void> discard(String id) async {}

  @override
  Future<FileImport> confirm(String id, {bool adoptFileCurrency = false}) async {
    if (adoptFileCurrency) world.currency = 'EUR';
    return importOf(
      {...sampleStats(), 'duplicates': 0, 'inserted': 22},
      id: id,
      status: 'confirmed',
    );
  }
}

/// Saving a budget (the page's last button): the story's API accepts it.
class _StoryBudgets implements BudgetsRepository {
  @override
  Future<void> setBudget(String categoryId, int cents, {required String month}) async {}

  @override
  Future<TransactionsPage> categoryTransactions(
    String month,
    String categoryId, {
    String? cursor,
  }) => throw UnimplementedError();

  @override
  Future<int> incomeTotal(String month, String categoryId) => throw UnimplementedError();
}

/// The picker gives the sample file (what the story's `userEvent.upload` hands over).
class _StoryFiles implements FilesChannel {
  @override
  Future<PickedFile?> pickFile({
    required List<String> mimeTypes,
    int maxBytes = FilesChannel.defaultMaxBytes,
  }) async => PickedFile('budge.csv', Uint8List.fromList('Date,Payment\n'.codeUnits));

  @override
  Future<bool> saveFile(String name, Uint8List bytes, String mime) => throw UnimplementedError();

  @override
  Future<bool> shareFile(String name, Uint8List bytes, String mime) => throw UnimplementedError();
}

/// The page in the story's frame: Storybook's 16px of padding, the bar under it, no 🎤.
Widget _screen() =>
    const ShellFrame(padding: EdgeInsets.all(16), showMic: false, child: ImportScreen());

List<Override> _overrides(ParityFixture fixture, _World world) => [
  ...parityHomeOverrides(_StoryHome(fixture, world)),
  importRepositoryProvider.overrideWithValue(_StoryImport(world)),
  budgetsRepositoryProvider.overrideWithValue(_StoryBudgets()),
  filesChannelProvider.overrideWithValue(_StoryFiles()),
];

Future<void> _tap(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(Key(key)));
  await t.pumpAndSettle();
  await t.tap(find.byKey(Key(key)));
  await t.pumpAndSettle();
}

Future<void> _preview(WidgetTester t) async {
  await _tap(t, 'import.source.budge');
  await _tap(t, 'import.choose');
}

/// The web leaves the page at its top for the picture (the story scrolls back after the focus).
Future<void> _top(WidgetTester t) async {
  t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
  await t.pumpAndSettle();
}

Future<void> _imported(WidgetTester t) async {
  await _preview(t);
  await _tap(t, 'import.confirm');
  await _top(t);
}

void main() {
  for (final theme in ['night', 'day']) {
    void pair(
      String name,
      String id,
      String story,
      Future<void> Function(WidgetTester t)? act, {
      String currency = 'EUR',
      bool budgeted = false,
      Locale locale = const Locale('es'),
    }) {
      testWidgets('import parity: $name ($theme)', (t) async {
        final fixture = ParityFixtures.load('onboarding-import-page--$story');
        await parityGolden(
          t,
          id,
          _screen(),
          theme: theme,
          locale: locale,
          overrides: _overrides(fixture, _World(currency: currency, dropsBudgets: budgeted)),
          act: (t) async {
            await precacheLukitas(t);
            await act?.call(t);
          },
        );
      });
    }

    pair('the sources', 'import-sources', 'sources', null);
    pair('Budge\'s how-to', 'import-how-to', 'how-to', (t) => _tap(t, 'import.source.budge'));
    pair('the preview', 'import-preview', 'preview', _preview);
    pair('the rows with problems', 'import-preview-rejected', 'preview-rejected-open', (t) async {
      await _preview(t);
      await _tap(t, 'import.rejected.toggle');
      // The story's click leaves the focus on the summary, which Chrome rings (a script's click
      // counts as the keyboard).
      Focus.of(
        t.element(
          find
              .descendant(
                of: find.byKey(const Key('import.rejected.toggle')),
                matching: find.byType(GestureDetector),
              )
              .first,
        ),
      ).requestFocus();
      await t.sendKeyEvent(LogicalKeyboardKey.shift);
    });
    pair(
      'the warning before a switch',
      'import-preview-switching',
      'preview-switching',
      _preview,
      currency: 'COP',
      budgeted: true,
    );
    pair('imported', 'import-imported', 'imported', _imported);
    pair('the budgets saved', 'import-budgets-saved', 'budgets-saved', (t) async {
      await _imported(t);
      await _tap(t, 'import.budgets.save');
      await _top(t);
    });
  }

  testWidgets('import parity: the preview in English (day)', (t) async {
    final fixture = ParityFixtures.load('onboarding-import-page--preview-english');
    await parityGolden(
      t,
      'import-preview-english',
      _screen(),
      theme: 'day',
      locale: const Locale('en'),
      overrides: _overrides(fixture, _World(currency: 'EUR')),
      act: (t) async {
        await precacheLukitas(t);
        await _preview(t);
      },
    );
  });

  testWidgets('import parity: imported, the account took the file\'s currency (day)', (t) async {
    final fixture = ParityFixtures.load('onboarding-import-page--imported-switched');
    await parityGolden(
      t,
      'import-imported-switched',
      _screen(),
      theme: 'day',
      overrides: _overrides(fixture, _World(currency: 'COP', dropsBudgets: true)),
      act: (t) async {
        await precacheLukitas(t);
        await _imported(t);
      },
    );
  });
}
