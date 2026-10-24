@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/import/budgets_form.dart';
import 'package:lukitas/import/import_state.dart';
import 'package:lukitas/ui/app_shell.dart';
import 'package:lukitas/welcome/budgets_step.dart';
import 'package:lukitas/welcome/categories_step.dart';
import 'package:lukitas/welcome/category_chips.dart';
import 'package:lukitas/welcome/currency_step.dart';
import 'package:lukitas/welcome/import_step.dart';
import 'package:lukitas/welcome/suggested_categories.dart';
import 'package:lukitas/welcome/welcome_step.dart';

import '../import/fakes.dart' show importOf, sampleStats;
import '../support/parity.dart';
import '../support/parity_home.dart' show precacheLukitas;

/// The welcome's steps against the stories that show them: `onboarding-welcome--*`
/// (apps/web/app/features/onboarding/Onboarding.stories.tsx), each as Storybook shows it after its
/// `play` function: the welcome, the currency, the categories (in English too), the import's
/// sources, preview (with its rows with problems, and the currency it switched) and result, and the
/// budgets (with pesos, and with no categories). The `Flow*` stories run the whole flow against a
/// fake API and are ported as widget tests (test/welcome/welcome_flow_test.dart).
///
/// Each story renders one step with state held by the story; so does each test here. Storybook pads
/// every story by 16px, so the steps sit in a [ShellFrame] with that padding (and no 🎤, which only
/// the bar has). The steps are full screens, with the footer at the bottom of the phone.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

Widget _frame(Widget screen) =>
    ShellFrame(padding: const EdgeInsets.all(16), showMic: false, child: screen);

void _noop() {}

Finder _key(String key) => find.byKey(Key(key));

/// The story's `userEvent.click` left the focus on the control it clicked, which Chrome rings (a
/// script's click counts as the keyboard): the control takes the focus, and a key puts the app in
/// keyboard mode, where it shows.
Future<void> _focusRinged(WidgetTester t, String key) async {
  final focus = t.widget<Focus>(find.descendant(of: _key(key), matching: find.byType(Focus)).first);
  focus.focusNode!.requestFocus();
  await t.pump();
  await t.sendKeyEvent(LogicalKeyboardKey.shift);
}

Future<void> _tap(WidgetTester t, String key) async {
  await t.ensureVisible(_key(key));
  await t.pumpAndSettle();
  await t.tap(_key(key));
  await t.pumpAndSettle();
}

// -- The harnesses: the state a story holds ----------------------------------------------------------

class _Currency extends StatefulWidget {
  const _Currency();

  @override
  State<_Currency> createState() => _CurrencyState();
}

class _CurrencyState extends State<_Currency> {
  var _value = 'COP';

  @override
  Widget build(BuildContext context) => CurrencyStep(
    value: _value,
    onChange: (code) => setState(() => _value = code),
    onBack: _noop,
    onSkip: _noop,
    onNext: _noop,
  );
}

/// `CategoriesHarness`: their own "Mascotas" first, then the suggestions, which come chosen.
class _Categories extends StatefulWidget {
  const _Categories(this.locale);

  final String locale;

  @override
  State<_Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<_Categories> {
  late final chips = [
    const CategoryChipModel(
      id: 'own-1',
      source: ChipSource.category,
      name: 'Mascotas',
      glyph: '🐶',
      tint: '#2fd388',
      kind: CategoryKindEnum.expense,
    ),
    ...categoryChips([], widget.locale),
  ];
  late final selected = {
    for (final c in chips)
      if (c.source == ChipSource.suggestion) c.id,
  };

  @override
  Widget build(BuildContext context) => CategoriesStep(
    chips: chips,
    selected: selected,
    onToggle: (id) async => setState(() {
      if (!selected.remove(id)) selected.add(id);
    }),
    onCreate: (_) async {},
    onEdit: (_, _) async {},
    onRemove: (_) async {},
    transactionsOf: (_) async => (count: 0, capped: false),
    errorText: (_) => '',
    onBack: _noop,
    onSkip: _noop,
    onNext: _noop,
  );
}

/// `ImportHarness`: the import step in [initial]; choosing a source opens or closes the how-to.
class _Import extends StatefulWidget {
  const _Import(this.initial, {this.prefillBasis});

  final ImportState initial;
  final String? prefillBasis;

  @override
  State<_Import> createState() => _ImportState();
}

class _ImportState extends State<_Import> {
  late ImportState state = widget.initial;

  @override
  Widget build(BuildContext context) => ImportStep(
    state: state,
    onSource: ({required budge}) =>
        setState(() => state = budge ? const ImportIdle() : const ImportSources()),
    onChoose: _noop,
    onConfirm: _noop,
    onDiscard: _noop,
    prefillBasis: widget.prefillBasis,
    onBack: _noop,
    onSkip: _noop,
    onNext: _noop,
  );
}

BudgetCategory _budgetCategory(String key) {
  final c = suggestedCategories.firstWhere((s) => s.key == key);
  return BudgetCategory(
    id: key,
    name: c.names['es']!,
    glyph: c.glyph,
    tint: Color(int.parse('ff${c.tint.substring(1)}', radix: 16)),
  );
}

/// `BudgetsHarness`.
class _Budgets extends StatefulWidget {
  const _Budgets({required this.currency, this.empty = false});

  final String currency;
  final bool empty;

  @override
  State<_Budgets> createState() => _BudgetsState();
}

class _BudgetsState extends State<_Budgets> {
  final drafts = <String, String>{};

  @override
  Widget build(BuildContext context) => BudgetsStep(
    categories: widget.empty
        ? const []
        : [
            for (final key in ['groceries', 'eating_out', 'home']) _budgetCategory(key),
          ],
    drafts: drafts,
    onChange: (id, text) => setState(() => drafts[id] = text),
    currency: widget.currency,
    onBack: _noop,
    onSkip: _noop,
    onNext: _noop,
  );
}

ImportState _preview({List<Map<String, Object?>>? rejected, CurrencyNote? note}) => ImportPreview(
  fileName: 'budge.csv',
  preview: importOf({...sampleStats(), 'rejected': ?rejected}, id: 'preview-sample'),
  currencyNote: note,
);

Future<void> _enter(WidgetTester t, String id, String text) async {
  await t.enterText(_key('budget.field.$id'), text);
  await t.pump();
}

void main() {
  for (final theme in ['night', 'day']) {
    void pair(
      String name,
      String id,
      String story,
      Widget Function() screen,
      Future<void> Function(WidgetTester t)? act, {
      Locale locale = const Locale('es'),
    }) {
      testWidgets('welcome parity: $name ($theme)', (t) async {
        ParityFixtures.load('onboarding-welcome--$story');
        await parityGolden(
          t,
          id,
          _frame(screen()),
          theme: theme,
          locale: locale,
          act: (t) async {
            await precacheLukitas(t);
            await act?.call(t);
          },
        );
      });
    }

    pair(
      'the welcome',
      'welcome-intro',
      'welcome',
      () => const WelcomeStep(currency: 'COP', onSetup: _noop, onDirect: _noop),
      (t) async {
        // The story clicks "Configurar" and then "Entrar directo".
        await _focusRinged(t, 'welcome.direct');
      },
    );

    pair('the currency', 'welcome-currency', 'currency', _Currency.new, (t) async {
      await _tap(t, 'welcome.currency.EUR');
      // The story ends clicking Atrás.
      await _focusRinged(t, 'welcome.back');
    });

    pair(
      'the categories',
      'welcome-categories',
      'categories-preselected',
      () => const _Categories('es'),
      (t) async {
        // The story drops every spending suggestion, then clicks Siguiente.
        for (final c in suggestedCategories.where((s) => s.kind == CategoryKindEnum.expense)) {
          await _tap(t, 'welcome.chip.s:${c.key}');
        }
        await _focusRinged(t, 'welcome.next');
      },
    );

    pair(
      'the import\'s sources',
      'welcome-import-sources',
      'import-sources',
      () => const _Import(ImportSources()),
      (t) async {
        // The story opens Budge's how-to and goes back to the list.
        await _tap(t, 'import.source.budge');
        await _tap(t, 'import.otherSource');
      },
    );

    pair(
      'the import\'s preview',
      'welcome-import-preview',
      'import-preview',
      () => _Import(_preview()),
      (t) async {
        await _tap(t, 'import.rejected.toggle');
        await _focusRinged(t, 'import.rejected.toggle');
      },
    );

    pair(
      'a file with many rows with problems',
      'welcome-import-rejected',
      'import-many-rejected',
      () => _Import(
        _preview(
          rejected: [
            for (var i = 0; i < 45; i++) {'line': 7 + i, 'reason': 'currency_mismatch'},
          ],
        ),
      ),
      (t) async {
        await _tap(t, 'import.rejected.toggle');
        await _focusRinged(t, 'import.rejected.toggle');
      },
    );

    pair(
      'the currency the file switched to',
      'welcome-import-switched',
      'import-switched-currency',
      () => _Import(
        _preview(
          note: const CurrencyNote(kind: CurrencyNoteKind.switched, file: 'EUR', account: 'COP'),
        ),
      ),
      null,
    );

    pair(
      'imported',
      'welcome-imported',
      'imported',
      () => _Import(
        ImportImported(
          result: importOf(
            {...sampleStats(), 'inserted': 19},
            id: 'preview-sample',
            status: 'confirmed',
          ),
          prefilled: true,
          currencyNote: null,
        ),
        prefillBasis: 'Basado en lo que gastaste en tus últimos 3 meses',
      ),
      null,
    );

    pair(
      'the budgets',
      'welcome-budgets',
      'budgets-running-total',
      () => const _Budgets(currency: 'EUR'),
      (t) async {
        await _enter(t, 'groceries', '300');
        await _enter(t, 'eating_out', '120,50');
        await _enter(t, 'home', '600');
        // A letter is not typed at all.
        await _enter(t, 'home', '600x');
        await _enter(t, 'home', '');
        await _enter(t, 'home', '12500,5');
        await t.pumpAndSettle();
      },
    );

    pair(
      'no spending categories',
      'welcome-budgets-empty',
      'budgets-without-categories',
      () => const _Budgets(currency: 'EUR', empty: true),
      null,
    );
  }

  testWidgets('welcome parity: the categories, in English (day)', (t) async {
    ParityFixtures.load('onboarding-welcome--categories-in-english');
    await parityGolden(
      t,
      'welcome-categories-english',
      _frame(const _Categories('en')),
      theme: 'day',
      locale: const Locale('en'),
      act: precacheLukitas,
    );
  });

  testWidgets('welcome parity: the budgets in pesos (day)', (t) async {
    ParityFixtures.load('onboarding-welcome--budgets-in-pesos');
    await parityGolden(
      t,
      'welcome-budgets-pesos',
      _frame(const _Budgets(currency: 'COP')),
      theme: 'day',
      act: (t) async {
        await precacheLukitas(t);
        await _enter(t, 'groceries', '300000');
        await _enter(t, 'home', '4300000');
        await t.pumpAndSettle();
      },
    );
  });
}
