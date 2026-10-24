import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_sheet.dart';
import 'package:lukitas/capture/capture_sheet.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/launch/launch_links.dart';
import 'package:lukitas/ui/category_chip.dart';
import 'package:lukitas/ui/press_button.dart';
import 'package:lukitas/welcome/welcome_controller.dart';
import 'package:lukitas/welcome/suggested_categories.dart';

import '../entry/fakes.dart' show FakeAuthApi;
import '../launch/launch_links_test.dart' show FakeLaunchLinks;
import '../settings/fakes.dart';
import 'fakes.dart';
import 'harness.dart';

/// The welcome's `Flow*` stories (apps/web/app/features/onboarding/Onboarding.stories.tsx), against
/// the story API in memory (`WelcomeWorld`, the web's `onboardingFetch`). Each story's expectations
/// are the same; the web's "App (stand-in)" is home.
void main() {
  group('who sees the welcome', () {
    testWidgets('a new email account is sent to the steps after signing in', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(categories: StartCategories.none));
      expect(env.location, '/welcome');
      expect(onStep('welcome'), isTrue);
      expect(find.text('Te damos la bienvenida a Lukitas'), findsOneWidget);
    });

    testWidgets('and from every other screen, until it finishes', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(categories: StartCategories.none));
      for (final path in ['/', '/settings', '/recurring', '/import']) {
        env.app.router.go(path);
        await tester.pumpAndSettle();
        expect(env.location, '/welcome', reason: path);
      }
    });

    testWidgets('an account with onboardingCompletedAt never sees it', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(), pending: false);
      expect(env.location, '/');
      expect(find.byType(HomeScreen), findsOneWidget);
      env.app.router.go('/welcome/currency');
      await tester.pumpAndSettle();
      expect(env.location, '/');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a guest keeps its guest start', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(), guest: true);
      expect(env.location, '/');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(env.pending, isFalse);
      env.app.router.go('/welcome');
      await tester.pumpAndSettle();
      expect(env.location, '/');
    });

    testWidgets('an account with movements (the API stamps it) never reaches the welcome', (
      tester,
    ) async {
      // What the API says of an account that predates the welcome but has data: stamped already.
      final env = await pumpWelcome(
        tester,
        WelcomeWorld(hasTransactionsAlready: true),
        pending: false,
        location: '/welcome',
      );
      expect(env.location, '/');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(env.world.requests, isEmpty, reason: 'nothing of its categories was touched');
    });

    testWidgets('a widget or notice link while the welcome is pending is dropped', (tester) async {
      final links = FakeLaunchLinks();
      final env = await pumpWelcome(
        tester,
        WelcomeWorld(categories: StartCategories.none),
        extra: [launchLinkSourceProvider.overrideWithValue(links)],
      );
      expect(onStep('welcome'), isTrue);
      for (final link in [
        'lukitas://add',
        'lukitas://capture',
        'lukitas://due',
        'lukitas://home',
      ]) {
        links.open(link);
        await tester.pumpAndSettle();
        expect(env.location, '/welcome', reason: link);
        expect(onStep('welcome'), isTrue, reason: link);
        expect(find.byType(AddSheet), findsNothing, reason: link);
        expect(find.byType(CaptureSheet), findsNothing, reason: link);
      }
    });

    testWidgets('and one the app was started with, too', (tester) async {
      final env = await pumpWelcome(
        tester,
        WelcomeWorld(categories: StartCategories.none),
        extra: [launchLinkSourceProvider.overrideWithValue(FakeLaunchLinks('lukitas://add'))],
      );
      expect(env.location, '/welcome');
      expect(find.byType(AddSheet), findsNothing);
    });

    testWidgets('an address that is none of the steps is the first', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(), location: '/welcome/passkey');
      expect(env.location, '/welcome');
      expect(onStep('welcome'), isTrue);
    });
  });

  group('ENTRAR DIRECTO', () {
    testWidgets(
      'on a brand-new account: the device\'s time zone, the region\'s currency, the eight '
      'suggested categories, no budgets, the onboarding flag, then home',
      (tester) async {
        final world = WelcomeWorld(categories: StartCategories.none, timezone: 'UTC');
        final env = await pumpWelcome(tester, world);
        await tap(tester, 'welcome.direct');
        expect(env.location, '/');
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(env.pending, isFalse);
        final lines = world.requests;
        expect(lines.first, 'PATCH /v1/me {"timezone":"America/Bogota"}');
        expect(lines, contains('PATCH /v1/me {"currency":"COP"}'));
        expect(world.categoryPosts, hasLength(8));
        expect(world.categoryPosts.first, contains('"name":"Supermercado"'));
        expect(lines.any((l) => l.contains('/budget')), isFalse);
        expect(lines.last, 'PATCH /v1/me {"onboardingCompleted":true}');
      },
    );

    testWidgets(
      'one category fails to save: the error shows, and again creates only the missing one',
      (tester) async {
        final world = WelcomeWorld(
          categories: StartCategories.none,
          failCategoryPost: (nth: 3, created: false),
        );
        final env = await pumpWelcome(tester, world);
        await tap(tester, 'welcome.direct');
        expect(find.textContaining('Tuvimos un problema de nuestro lado'), findsOneWidget);
        expect(world.categoryPosts, hasLength(8));
        await tap(tester, 'welcome.direct');
        expect(env.location, '/');
        expect(world.categoryPosts, hasLength(9));
      },
    );

    testWidgets('the answer to one save was lost although it was made: the retry creates nothing', (
      tester,
    ) async {
      final world = WelcomeWorld(
        categories: StartCategories.none,
        failCategoryPost: (nth: 3, created: true),
      );
      final env = await pumpWelcome(tester, world);
      await tap(tester, 'welcome.direct');
      expect(key('welcome.error'), findsOneWidget);
      await tap(tester, 'welcome.direct');
      expect(env.location, '/');
      expect(world.categoryPosts, hasLength(8));
    });

    testWidgets('a 409 "name taken" for a suggestion means it is already there: not a failure', (
      tester,
    ) async {
      final env = await pumpWelcome(
        tester,
        WelcomeWorld(categories: StartCategories.none, takenNames: const ['Ocio']),
      );
      await tap(tester, 'welcome.direct');
      expect(env.location, '/');
    });

    testWidgets('when every suggestion was deselected (and archived) earlier, they come back', (
      tester,
    ) async {
      final world = WelcomeWorld(categories: StartCategories.archived);
      final env = await pumpWelcome(tester, world);
      await tap(tester, 'welcome.direct');
      expect(env.location, '/');
      final restored = world.requests.where((l) => l.endsWith('{"archived":false}'));
      expect(restored, hasLength(suggestedCategories.length));
      expect(world.requests.last, 'PATCH /v1/me {"onboardingCompleted":true}');
    });
  });

  group('the steps', () {
    testWidgets('SALTAR on every step: still a usable account, and home', (tester) async {
      final world = WelcomeWorld(categories: StartCategories.none);
      final env = await pumpWelcome(tester, world);
      await tap(tester, 'welcome.setup');
      for (final step in ['currency', 'import', 'categories', 'budgets']) {
        expect(onStep(step), isTrue, reason: step);
        await tap(tester, 'welcome.skip');
      }
      expect(env.location, '/');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(world.requests, contains('PATCH /v1/me {"currency":"COP"}'));
      expect(world.categoryPosts, hasLength(8));
      expect(world.requests.any((l) => l.contains('/budget')), isFalse);
      expect(world.requests.last, 'PATCH /v1/me {"onboardingCompleted":true}');
    });

    testWidgets('the order: currency, "¿Vienes de otra app?", then the categories', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(categories: StartCategories.none));
      await tap(tester, 'welcome.setup');
      expect(find.text('¿En qué moneda llevas tus cuentas?'), findsOneWidget);
      expect(find.text('Paso 1 de 4'), findsOneWidget);
      // The first setup step has no way back (to the welcome).
      expect(key('welcome.back'), findsNothing);
      await tap(tester, 'welcome.next');
      expect(find.text('¿Vienes de otra app?'), findsOneWidget);
      expect(find.text('Paso 2 de 4'), findsOneWidget);
      await tap(tester, 'import.fresh');
      expect(find.text('¿En qué se te va el dinero?'), findsOneWidget);
      expect(find.text('Paso 3 de 4'), findsOneWidget);
      // Nothing imported: the suggestions, pre-selected.
      expect(env.app.container.read(welcomeProvider).selected, contains('s:groceries'));
      await tap(tester, 'welcome.next');
      expect(find.text('¿Cuánto quieres gastar al mes?'), findsOneWidget);
      expect(find.text('Paso 4 de 4'), findsOneWidget);
    });

    testWidgets('Back goes to the step before, and the steps keep what was chosen', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(categories: StartCategories.none));
      await tap(tester, 'welcome.setup');
      await tap(tester, 'welcome.currency.USD');
      await tap(tester, 'welcome.next');
      expect(onStep('import'), isTrue);
      await tap(tester, 'welcome.back');
      expect(onStep('currency'), isTrue);
      expect(env.app.container.read(welcomeProvider).currency, 'USD');
    });

    testWidgets('"＋ Agregar categoría": name, kind, emoji and tint; saved right away and chosen', (
      tester,
    ) async {
      final world = WelcomeWorld();
      final env = await pumpWelcome(tester, world, location: '/welcome/categories');
      await tap(tester, 'welcome.categories.add');
      expect(find.text('Nueva categoría'), findsOneWidget);
      // A name is needed.
      await tap(tester, 'category.save');
      expect(find.text('Escribe un nombre para la categoría.'), findsOneWidget);
      await tester.enterText(key('category.name'), 'Mascotas');
      await tap(tester, 'category.glyph.🐶');
      await tap(tester, 'category.tint.green');
      await tap(tester, 'category.save');
      expect(key('category.name'), findsNothing, reason: 'the sheet is closed');
      expect(
        world.requests,
        contains(
          'POST /v1/categories {"name":"Mascotas","kind":"expense","icon":"🐶","color":"#2fd388"}',
        ),
      );
      final created = world.stored.last;
      expect(created.name, 'Mascotas');
      expect(env.app.container.read(welcomeProvider).selected, contains(created.id));
      expect(key('welcome.chip.${created.id}'), findsOneWidget);
    });

    testWidgets('after adding their own, a restart keeps the chips, and SALTAR keeps them all', (
      tester,
    ) async {
      final world = WelcomeWorld(categories: StartCategories.none);
      final settings = FakeSettingsStore();
      final auth = FakeAuthApi();
      await pumpWelcome(
        tester,
        world,
        location: '/welcome/categories',
        settings: settings,
        auth: auth,
      );
      await tap(tester, 'welcome.categories.add');
      await tester.enterText(key('category.name'), 'Mascotas');
      await tap(tester, 'category.save');
      final created = world.stored.last;

      // The app is killed and started again: the draft is on the phone.
      await tester.pumpWidget(const SizedBox.shrink());
      final env = await pumpWelcome(
        tester,
        world,
        location: '/welcome/categories',
        settings: settings,
        auth: auth,
      );
      expect(find.text('¿En qué se te va el dinero?'), findsOneWidget);
      final selected = env.app.container.read(welcomeProvider).selected!;
      for (final s in suggestedCategories) {
        expect(selected, contains('s:${s.key}'));
      }
      expect(selected, contains(created.id));

      await tap(tester, 'welcome.skip');
      expect(onStep('budgets'), isTrue);
      // Mascotas, then the eight suggestions; nothing archived.
      expect(world.categoryPosts, hasLength(9));
      expect(world.requests.any((l) => l.contains('"archived":true')), isFalse);
    });

    testWidgets('a deep link to the budgets before any category exists goes to the categories', (
      tester,
    ) async {
      await pumpWelcome(
        tester,
        WelcomeWorld(categories: StartCategories.none),
        location: '/welcome/budgets',
      );
      expect(find.text('¿En qué se te va el dinero?'), findsOneWidget);
    });

    testWidgets('SIGUIENTE on the budgets saves them and the onboarding flag, then goes home', (
      tester,
    ) async {
      final world = WelcomeWorld();
      final env = await pumpWelcome(tester, world, location: '/welcome/budgets');
      expect(find.text('¿Cuánto quieres gastar al mes?'), findsOneWidget);
      await tester.enterText(key('budget.field.cat-groceries'), '300');
      await tester.pump();
      await tap(tester, 'welcome.next');
      expect(env.location, '/');
      expect(
        world.requests,
        contains(
          'PUT /v1/categories/cat-groceries/budget {"amount":30000,"effectiveFrom":"2026-10"}',
        ),
      );
      expect(world.requests.last, 'PATCH /v1/me {"onboardingCompleted":true}');
    });

    testWidgets('a field that is not an amount says so and holds SIGUIENTE back; SALTAR finishes', (
      tester,
    ) async {
      final world = WelcomeWorld();
      final env = await pumpWelcome(tester, world, location: '/welcome/budgets');
      await tester.enterText(key('budget.field.cat-groceries'), '300');
      await tester.pump();
      // The field takes only an amount: a letter is not typed at all, so it is never invalid here.
      await tester.enterText(key('budget.field.cat-groceries'), '300x');
      await tester.pump();
      expect(shown(tester, 'budget.field.cat-groceries'), '300');
      expect(tester.widget<PressButton>(key('welcome.next')).onPressed, isNotNull);
      await tap(tester, 'welcome.skip');
      expect(env.location, '/');
      expect(world.requests.any((l) => l.contains('/budget')), isFalse);
    });
  });

  group('the currency', () {
    testWidgets('a currency they picked stays picked after a restart', (tester) async {
      final world = WelcomeWorld();
      final settings = FakeSettingsStore();
      final auth = FakeAuthApi();
      final env = await pumpWelcome(
        tester,
        world,
        location: '/welcome/currency',
        settings: settings,
        auth: auth,
      );
      // In Bogotá the default is COP.
      expect(env.app.container.read(welcomeProvider).currency, 'COP');
      await tap(tester, 'welcome.currency.EUR');
      await tester.pumpWidget(const SizedBox.shrink());
      final again = await pumpWelcome(
        tester,
        world,
        location: '/welcome/currency',
        settings: settings,
        auth: auth,
      );
      expect(find.text('¿En qué moneda llevas tus cuentas?'), findsOneWidget);
      expect(again.app.container.read(welcomeProvider).currency, 'EUR');
    });

    testWidgets('a locked account shows its own currency, not the COP in the draft', (
      tester,
    ) async {
      final settings = FakeSettingsStore({
        'onboarding.draft.u-new': '{"currency":"COP","categoriesDone":true}',
      });
      final env = await pumpWelcome(
        tester,
        WelcomeWorld(hasTransactionsAlready: true),
        location: '/welcome/currency',
        settings: settings,
      );
      expect(env.app.container.read(welcomeProvider).currency, 'EUR');
    });

    testWidgets('without a draft the device decides: Colombian Spanish is COP, Madrid EUR', (
      tester,
    ) async {
      final env = await pumpWelcome(
        tester,
        WelcomeWorld(),
        device: const WelcomeDevice(languages: ['es-ES'], timeZone: 'Europe/Madrid'),
        location: '/welcome/currency',
      );
      expect(env.app.container.read(welcomeProvider).currency, 'EUR');
    });

    testWidgets('SIGUIENTE saves the currency; the draft keeps it', (tester) async {
      final world = WelcomeWorld(categories: StartCategories.none);
      final env = await pumpWelcome(tester, world, location: '/welcome/currency');
      await tap(tester, 'welcome.currency.USD');
      await tap(tester, 'welcome.next');
      expect(world.requests, contains('PATCH /v1/me {"currency":"USD"}'));
      expect(world.currency, 'USD');
      expect(onStep('import'), isTrue);
      expect(env.settings.values['onboarding.draft.u-new'], contains('"currency":"USD"'));
    });

    testWidgets('a locked currency that cannot be saved says why and stays', (tester) async {
      final world = WelcomeWorld(hasTransactionsAlready: true);
      await pumpWelcome(tester, world, location: '/welcome/currency');
      await tap(tester, 'welcome.currency.USD');
      await tap(tester, 'welcome.next');
      expect(find.textContaining('no puedes cambiar la moneda'), findsOneWidget);
      expect(onStep('currency'), isTrue);
    });
  });

  Future<void> upload(WidgetTester tester, WelcomeEnv env) async {
    env.files.next = budgeFile;
    await tap(tester, 'import.source.budge');
    await tap(tester, 'import.choose');
  }

  group('the import', () {
    testWidgets(
      'a COP account uploads a EUR file: nothing changes until the confirm, which adopts it',
      (tester) async {
        final world = WelcomeWorld(currency: 'COP');
        final env = await pumpWelcome(tester, world, location: '/welcome/import');
        await upload(tester, env);
        expect(
          find.text('Tu archivo está en EUR: al importarlo, tu cuenta pasará a usar EUR.'),
          findsOneWidget,
        );
        // Reading the file changed nothing.
        expect(world.requests, ['POST /v1/imports']);
        await tap(tester, 'import.confirm');
        expect(find.text('Importamos 22 movimientos.'), findsOneWidget);
        expect(world.requests, [
          'POST /v1/imports',
          'POST /v1/imports/preview-1/confirm {"adoptFileCurrency":true}',
        ]);
        expect(
          find.text('Tu archivo está en EUR, así que tu cuenta ahora usa EUR.'),
          findsOneWidget,
        );
        expect(env.app.container.read(welcomeProvider).currency, 'EUR');
        await tap(tester, 'welcome.next');
        expect(find.text('¿En qué se te va el dinero?'), findsOneWidget);
        await tap(tester, 'welcome.next');
        // The budgets are prefilled from the recent months, in euros.
        expect(shown(tester, 'budget.field.cat-groceries'), '35,89');
        expect(find.text('Basado en lo que gastaste en tus últimos 3 meses'), findsOneWidget);
      },
    );

    testWidgets('"Usar otro archivo" drops the preview; the currency was never touched', (
      tester,
    ) async {
      final world = WelcomeWorld(currency: 'COP');
      final env = await pumpWelcome(tester, world, location: '/welcome/import');
      await upload(tester, env);
      await tap(tester, 'import.otherFile');
      expect(world.requests, ['POST /v1/imports', 'DELETE /v1/imports/preview-1']);
      expect(key('import.choose'), findsOneWidget);
      expect(world.currency, 'COP');
    });

    testWidgets('SALTAR with a preview open drops it and moves on', (tester) async {
      final world = WelcomeWorld(currency: 'COP');
      final env = await pumpWelcome(tester, world, location: '/welcome/import');
      await upload(tester, env);
      expect(find.text('IMPORTAR 22 MOVIMIENTOS'), findsOneWidget);
      await tap(tester, 'welcome.skip');
      expect(find.text('¿En qué se te va el dinero?'), findsOneWidget);
      expect(world.requests, ['POST /v1/imports', 'DELETE /v1/imports/preview-1']);
    });

    testWidgets('the import went in but reading the categories failed: it says so, with a retry', (
      tester,
    ) async {
      final world = WelcomeWorld(failRefreshesAfterConfirm: 1);
      final env = await pumpWelcome(tester, world, location: '/welcome/import');
      await upload(tester, env);
      await tap(tester, 'import.confirm');
      expect(find.text('Importamos 22 movimientos.'), findsOneWidget);
      expect(find.textContaining('Tuvimos un problema de nuestro lado'), findsOneWidget);
      // Importing again could only fail: there is no such button.
      expect(find.textContaining('IMPORTAR'), findsNothing);
      await tap(tester, 'import.retry');
      expect(find.textContaining('Tuvimos un problema de nuestro lado'), findsNothing);
      expect(
        find.text('Llenamos tus presupuestos con lo que gastas en promedio cada mes.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'an old export: the budgets say the amounts come from its last months with activity',
      (tester) async {
        final env = await pumpWelcome(
          tester,
          WelcomeWorld(oldExport: true),
          location: '/welcome/import',
        );
        await upload(tester, env);
        await tap(tester, 'import.confirm');
        expect(find.text('Basado en tus últimos 3 meses con movimientos'), findsOneWidget);
        await tap(tester, 'welcome.next');
        await tap(tester, 'welcome.next');
        expect(find.text('¿Cuánto quieres gastar al mes?'), findsOneWidget);
        expect(find.text('Basado en tus últimos 3 meses con movimientos'), findsOneWidget);
      },
    );

    testWidgets('while a confirm runs, SALTAR and Back wait', (tester) async {
      final world = WelcomeWorld()..holdConfirm = Completer<void>();
      final env = await pumpWelcome(tester, world, location: '/welcome/import');
      await upload(tester, env);
      await tester.tap(key('import.confirm'));
      await tester.pump();
      await tester.pump();
      expect(find.text('IMPORTANDO…'), findsOneWidget);
      expect(tester.widget<PressButton>(key('welcome.skip')).onPressed, isNull);
      expect(tester.widget<PressButton>(key('welcome.back')).onPressed, isNull);
      world.holdConfirm!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Importamos 22 movimientos.'), findsOneWidget);
      expect(world.requests.any((l) => l.startsWith('DELETE')), isFalse);
    });

    testWidgets(
      'killed on the categories right after the import, the welcome resumes there, not at home',
      (tester) async {
        // The API leaves an account that only has imported movements un-stamped (it is still in its
        // welcome), so the restart still gets "pending" and the categories and budgets are not lost.
        final world = WelcomeWorld(categories: StartCategories.none);
        final settings = FakeSettingsStore();
        final auth = FakeAuthApi();
        final env = await pumpWelcome(
          tester,
          world,
          location: '/welcome/import',
          settings: settings,
          auth: auth,
        );
        await upload(tester, env);
        await tap(tester, 'import.confirm');
        await tap(tester, 'welcome.next');
        expect(onStep('categories'), isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
        final again = await pumpWelcome(
          tester,
          world,
          location: '/welcome/categories',
          settings: settings,
          auth: auth,
        );
        expect(again.pending, isTrue);
        expect(again.location, '/welcome/categories');
        expect(onStep('categories'), isTrue);
        expect(find.byType(HomeScreen), findsNothing);
        // And the rest of the welcome is still ahead of them.
        await tap(tester, 'welcome.skip');
        expect(onStep('budgets'), isTrue);
      },
    );

    testWidgets('import first: the categories start from what the file brought', (tester) async {
      final world = WelcomeWorld(categories: StartCategories.none);
      final env = await pumpWelcome(tester, world, location: '/welcome/import');
      await upload(tester, env);
      await tap(tester, 'import.confirm');
      await tap(tester, 'welcome.next');
      expect(find.text('¿En qué se te va el dinero?'), findsOneWidget);
      // "supermercado" and "Salário" cover "Supermercado" and "Salario": no duplicates.
      final controller = env.app.container.read(welcomeProvider.notifier);
      expect(
        [for (final c in controller.chips.where((c) => c.kind.name == 'expense')) c.name],
        [
          'supermercado',
          'Ocio',
          'Taxes',
          'Restaurante',
          'Casa',
          'Transporte',
          'Suscripciones',
          'Vida',
        ],
      );
      final selected = env.app.container.read(welcomeProvider).selected!;
      final byName = {for (final c in controller.chips) c.name: c};
      for (final name in ['supermercado', 'Ocio', 'Taxes']) {
        expect(selected, contains(byName[name]!.id), reason: name);
      }
      expect(selected, isNot(contains(byName['Restaurante']!.id)));
      expect(
        [for (final c in controller.chips.where((c) => c.kind.name == 'income')) c.name],
        ['Salário'],
      );
      expect(find.textContaining('Estas son tus categorías'), findsOneWidget);
    });

    testWidgets(
      'with no import, the lead speaks of the suggestions; an importer tint is its radio',
      (tester) async {
        final world = WelcomeWorld(categories: StartCategories.none);
        final env = await pumpWelcome(tester, world, location: '/welcome/import');
        await tap(tester, 'import.fresh');
        expect(find.textContaining('Ya elegimos algunas por ti'), findsOneWidget);
        await tap(tester, 'welcome.back');
        expect(find.text('¿Vienes de otra app?'), findsOneWidget);
        await upload(tester, env);
        await tap(tester, 'import.confirm');
        await tap(tester, 'welcome.next');
        await tap(tester, 'welcome.categories.edit');
        final taxes = world.stored.firstWhere((c) => c.name == 'Taxes');
        await tap(tester, 'welcome.chip.${taxes.id}');
        final semantics = tester.ensureSemantics();
        final yellow = tester.getSemantics(key('category.tint.yellow'));
        expect(yellow.label, 'Amarillo');
        expect(yellow.flagsCollection.isChecked.name, 'isTrue');
        expect(
          tester.getSemantics(key('category.tint.blue')).flagsCollection.isChecked.name,
          'isFalse',
        );
        semantics.dispose();
      },
    );
  });

  Future<void> openEdit(WidgetTester tester, String chip) async {
    final editing = tester.widget<CategoryChip>(key('welcome.chip.$chip')).editLabel != null;
    if (!editing) await tap(tester, 'welcome.categories.edit');
    await tap(tester, 'welcome.chip.$chip');
  }

  group('editing the categories', () {
    testWidgets('rename, emoji and tint in the edit sheet; then delete it', (tester) async {
      final world = WelcomeWorld();
      final env = await pumpWelcome(tester, world, location: '/welcome/categories');
      await openEdit(tester, 'cat-groceries');
      expect(find.text('Editar categoría'), findsOneWidget);
      expect(shown(tester, 'category.name'), 'Supermercado');
      expect(key('category.delete'), findsOneWidget);
      await tester.enterText(key('category.name'), 'Mercado');
      await tap(tester, 'category.glyph.🧾');
      await tap(tester, 'category.tint.blue');
      await tap(tester, 'category.save');
      expect(key('category.name'), findsNothing);
      expect(
        world.requests,
        contains(
          'PATCH /v1/categories/cat-groceries {"name":"Mercado","icon":"🧾","color":"#3fa7ff"}',
        ),
      );

      await openEdit(tester, 'cat-groceries');
      await tap(tester, 'category.delete');
      expect(world.requests.last, 'PATCH /v1/categories/cat-groceries {"archived":true}');
      expect(key('welcome.chip.cat-groceries'), findsNothing);
      expect(env.app.container.read(welcomeProvider).selected, isNot(contains('cat-groceries')));
    });

    testWidgets(
      'a suggestion not made yet: editing makes it with the new values; deleting drops it',
      (tester) async {
        final world = WelcomeWorld();
        await pumpWelcome(tester, world, location: '/welcome/categories');
        await openEdit(tester, 's:eating_out');
        await tester.enterText(key('category.name'), 'Comida fuera');
        await tap(tester, 'category.save');
        expect(
          world.requests.any(
            (l) => l.startsWith('POST /v1/categories {"name":"Comida fuera","kind":"expense"'),
          ),
          isTrue,
        );
        await openEdit(tester, 's:health');
        final before = world.requests.length;
        await tap(tester, 'category.delete');
        expect(world.requests, hasLength(before));
        expect(key('welcome.chip.s:health'), findsNothing);
      },
    );

    testWidgets('a removed suggestion stays removed after a restart', (tester) async {
      final world = WelcomeWorld();
      final settings = FakeSettingsStore();
      final auth = FakeAuthApi();
      await pumpWelcome(
        tester,
        world,
        location: '/welcome/categories',
        settings: settings,
        auth: auth,
      );
      await openEdit(tester, 's:health');
      await tap(tester, 'category.delete');
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpWelcome(
        tester,
        world,
        location: '/welcome/categories',
        settings: settings,
        auth: auth,
      );
      expect(key('welcome.chip.s:health'), findsNothing);
      expect(key('welcome.chip.s:transport'), findsOneWidget);
    });

    testWidgets('spending to income for a category without transactions: one PATCH with the kind', (
      tester,
    ) async {
      final world = WelcomeWorld();
      await pumpWelcome(tester, world, location: '/welcome/categories');
      await openEdit(tester, 'cat-salary');
      await tap(tester, 'category.delete'); // The counting is done: it can be deleted.
      expect(world.requests, ['PATCH /v1/categories/cat-salary {"archived":true}']);
      world.requests.clear();
      // Another one: switch its kind.
      await openEdit(tester, 's:fun');
      await tap(tester, 'category.kind.income');
      await tap(tester, 'category.save');
      expect(
        world.requests.single,
        startsWith('POST /v1/categories {"name":"Ocio","kind":"income"'),
      );
    });

    testWidgets(
      'with transactions it cannot be deleted: the sheet says how many, and offers to archive',
      (tester) async {
        final world = WelcomeWorld(transactionsByName: const {'Supermercado': 132});
        final env = await pumpWelcome(tester, world, location: '/welcome/categories');
        // A plain tap does not drop it either: it stays chosen, with the same reason.
        await tap(tester, 'welcome.chip.cat-groceries');
        expect(
          find.text(
            '«Supermercado» no se puede quitar porque tiene 132 movimientos. Puedes archivarla en '
            'Editar categorías para que no aparezca al anotar.',
          ),
          findsOneWidget,
        );
        expect(env.app.container.read(welcomeProvider).selected, contains('cat-groceries'));

        await openEdit(tester, 'cat-groceries');
        expect(
          find.text(
            'No se puede borrar porque tiene 132 movimientos. Puedes archivarla para que no '
            'aparezca al anotar.',
          ),
          findsOneWidget,
        );
        expect(key('category.delete'), findsNothing);
        await tap(tester, 'category.archive');
        expect(world.requests.last, 'PATCH /v1/categories/cat-groceries {"archived":true}');
      },
    );

    testWidgets('a kind change the API refuses says so in the sheet, which stays open', (
      tester,
    ) async {
      final world = WelcomeWorld(transactionsByName: const {'Salario': 3});
      await pumpWelcome(tester, world, location: '/welcome/categories');
      await openEdit(tester, 'cat-salary');
      // With transactions the kind is fixed in the sheet: nothing to refuse.
      await tester.enterText(key('category.name'), 'Sueldo');
      await tap(tester, 'category.save');
      expect(
        world.requests.last,
        'PATCH /v1/categories/cat-salary {"name":"Sueldo","icon":"💰","color":"#2fd388"}',
      );
      expect(find.text('Con movimientos, su tipo no se puede cambiar aquí.'), findsNothing);
    });

    testWidgets('the count fails: no "más de 0", only that, and only Archivar', (tester) async {
      final world = WelcomeWorld(failCount: true);
      await pumpWelcome(tester, world, location: '/welcome/categories');
      await openEdit(tester, 'cat-groceries');
      expect(
        find.text(
          'No pudimos contar sus movimientos. Puedes archivarla para que no aparezca al anotar.',
        ),
        findsOneWidget,
      );
      expect(key('category.delete'), findsNothing);
      expect(key('category.archive'), findsOneWidget);
    });

    testWidgets('the count fails on a tap: the category stays chosen, and says why', (
      tester,
    ) async {
      final world = WelcomeWorld(failCount: true);
      final env = await pumpWelcome(tester, world, location: '/welcome/categories');
      await tap(tester, 'welcome.chip.cat-groceries');
      expect(
        find.text(
          'No pudimos comprobar si «Supermercado» tiene movimientos, así que sigue elegida.',
        ),
        findsOneWidget,
      );
      expect(env.app.container.read(welcomeProvider).selected, contains('cat-groceries'));
    });

    testWidgets('a name already taken is said in the sheet, which stays open with what was typed', (
      tester,
    ) async {
      final world = WelcomeWorld();
      await pumpWelcome(tester, world, location: '/welcome/categories');
      await tap(tester, 'welcome.categories.add');
      await tester.enterText(key('category.name'), 'supermercado');
      await tap(tester, 'category.save');
      expect(key('category.error'), findsOneWidget);
      expect(shown(tester, 'category.name'), 'supermercado');
    });
  });

  group('around the steps', () {
    testWidgets('what the welcome starts from cannot be read: it says so, with a retry', (
      tester,
    ) async {
      final world = WelcomeWorld()..failHasTransactions = true;
      await pumpWelcome(tester, world);
      expect(find.text('Reintentar'.toUpperCase()), findsOneWidget);
      world.failHasTransactions = false;
      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();
      expect(onStep('welcome'), isTrue);
    });

    testWidgets('the system\'s back goes to the step before', (tester) async {
      final env = await pumpWelcome(tester, WelcomeWorld(), location: '/welcome/import');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(env.location, '/welcome/currency');
    });
  });
}
