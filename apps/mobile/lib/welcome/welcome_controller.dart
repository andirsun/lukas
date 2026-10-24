// The welcome's state and writes: a port of apps/web/app/features/onboarding/Welcome.tsx and
// use-categories-step.ts.
//
// The welcome is optional and short: "Configurar en 1 minuto" or "Entrar directo", and every setup
// step has SIGUIENTE (apply what is on screen) and SALTAR (move on with this step's defaults). The
// import comes before the categories, so they start from what the file brought. Each step saves
// what it needs before the next (currency, import, categories); budgets come last and stay drafts
// until the end, so an import that switches the currency can replace amounts typed in the old one.
// Choices not on the server yet (the currency picked, the chips) live in the draft, which the phone
// keeps, so a welcome the app was killed in the middle of is where it was left. Finishing or
// skipping sets the onboarding flag, celebrates and lands on home.
//
// The profile and the categories are home's (the import reads them there too): the welcome asks
// home to look again after each write.
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/device.dart';
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../categories/category_model.dart';
import '../feedback/feedback.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../import/budget_input.dart';
import '../import/import_flow.dart';
import '../import/import_state.dart';
import '../profile/currency.dart';
import '../profile/timezone.dart';
import '../settings/settings_store.dart';
import 'category_chips.dart';
import 'onboarding_api.dart';
import 'onboarding_draft.dart';
import 'onboarding_repository.dart';
import 'suggested_categories.dart';

/// What the device says about where the person is: its languages and its time zone. The currency
/// is preselected from them (the web's `navigator.languages` and `Intl` zone).
class WelcomeDevice {
  const WelcomeDevice({required this.languages, required this.timeZone});

  final List<String> languages;
  final String? timeZone;
}

final welcomeDeviceProvider = Provider<WelcomeDevice>((ref) {
  final hints = ref.watch(deviceHintsProvider);
  final tags = [for (final l in PlatformDispatcher.instance.locales) l.toLanguageTag()];
  return WelcomeDevice(languages: tags.isEmpty ? [hints.locale] : tags, timeZone: hints.timezone);
});

final onboardingDraftStoreProvider = Provider<OnboardingDraftStore>(
  (ref) => OnboardingDraftStore(ref.watch(settingsStoreProvider)),
);

/// Why a chip stayed chosen when tapped.
sealed class CategoryNotice {
  const CategoryNotice(this.name);

  final String name;
}

/// It has transactions.
class HasTransactionsNotice extends CategoryNotice {
  const HasTransactionsNotice(super.name, {required this.count, required this.capped});

  final int count;
  final bool capped;
}

/// They could not be counted.
class UnknownNotice extends CategoryNotice {
  const UnknownNotice(super.name);
}

class WelcomeState {
  const WelcomeState({
    this.draft,
    this.currency,
    this.hasTransactions,
    this.selected,
    this.seeded = false,
    this.notice,
    this.busy = false,
    this.error,
    this.loadFailure,
  });

  /// What the person chose that the server doesn't have; null until read.
  final OnboardingDraft? draft;

  /// The currency on the step: null until it is preselected.
  final String? currency;

  /// The account has a transaction already: its currency is locked. Null until known.
  final bool? hasTransactions;

  /// The chip ids that are chosen: null until the categories are known.
  final Set<String>? selected;

  /// The budget fields hold what the categories already have.
  final bool seeded;
  final CategoryNotice? notice;

  /// A step's write is in flight: the buttons wait.
  final bool busy;

  /// The failure of the last write, shown on its step.
  final HomeFailure? error;

  /// Reading what the welcome starts from failed.
  final HomeFailure? loadFailure;

  bool get ready =>
      draft != null && currency != null && hasTransactions != null && selected != null && seeded;

  WelcomeState copyWith({
    OnboardingDraft? draft,
    String? currency,
    bool? hasTransactions,
    Set<String>? selected,
    bool? seeded,
    CategoryNotice? Function()? notice,
    bool? busy,
    HomeFailure? Function()? error,
    HomeFailure? Function()? loadFailure,
  }) => WelcomeState(
    draft: draft ?? this.draft,
    currency: currency ?? this.currency,
    hasTransactions: hasTransactions ?? this.hasTransactions,
    selected: selected ?? this.selected,
    seeded: seeded ?? this.seeded,
    notice: notice == null ? this.notice : notice(),
    busy: busy ?? this.busy,
    error: error == null ? this.error : error(),
    loadFailure: loadFailure == null ? this.loadFailure : loadFailure(),
  );
}

class WelcomeController extends Notifier<WelcomeState> {
  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);
  HomeRepository get _homeRepo => ref.read(homeRepositoryProvider);
  OnboardingDraftStore get _drafts => ref.read(onboardingDraftStoreProvider);
  HomeController get _home => ref.read(homeProvider.notifier);
  WelcomeDevice get _device => ref.read(welcomeDeviceProvider);

  var _alive = true;
  var _started = false;
  var _zoneSent = false;

  /// A ref, not state: two taps in one frame must not both start a write.
  var _inFlight = false;

  /// The app's language (`es` or `en`), which the screen tells: the budgets are seeded in it, so
  /// `300,50` is never read back as an English 30050.
  String? _locale;
  String get locale => _locale ?? 'es';

  @override
  WelcomeState build() {
    _alive = true;
    _started = false;
    _zoneSent = false;
    _inFlight = false;
    ref.onDispose(() => _alive = false);
    // A new session (another person signing in) starts from nothing.
    ref.watch(onboardingRepositoryProvider);
    // The import is the welcome's too: it lives as long as the welcome does, and the welcome follows
    // it (the currency it switches to, the categories it brings).
    ref.listen(importFlowProvider, _onImport);
    ref.listen(homeProvider, (_, next) => _onHome(next), fireImmediately: true);
    return const WelcomeState();
  }

  void _set(WelcomeState next) {
    if (_alive) state = next;
  }

  /// The home data the welcome reads: the profile and the categories (archived ones too).
  HomeData? get _data => ref.read(homeProvider).data;

  /// The person's categories as the steps list them: the active ones, in the API's order.
  List<Category> get activeCategories {
    final all = _data?.categories.values ?? const <Category>[];
    return [
      for (final c in all)
        if (!c.archived) c,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Active spending categories, as the budgets step lists them.
  List<Category> get spending => [
    for (final c in activeCategories)
      if (c.kind == CategoryKindEnum.expense) c,
  ];

  /// The language is told by the screen; the seed of the budget fields waits for it.
  void useLocale(String locale) {
    if (_locale == locale) return;
    _locale = locale;
    if (_alive && _data != null) _settle();
  }

  void _onHome(HomeState home) {
    final data = home.data;
    if (data == null) return;
    if (!_started) {
      _started = true;
      unawaited(_start(data));
    } else {
      _settle();
    }
  }

  /// Reads what the welcome starts from: the draft of this person, and whether the account has a
  /// transaction (its currency is then locked).
  Future<void> _start(HomeData data) async {
    try {
      final (draft, has) = await (_drafts.load(data.userId), _homeRepo.hasTransactions()).wait;
      if (!_alive) return;
      _set(state.copyWith(draft: draft, hasTransactions: has, loadFailure: () => null));
      _settle();
      unawaited(_sendZone(data));
    } on Object catch (error) {
      if (!_alive) return;
      _started = false;
      _set(state.copyWith(loadFailure: () => _failure(error)));
    }
  }

  /// Tries the start again after a read failed.
  void retryStart() {
    final data = _data;
    if (data == null || _started) return;
    _started = true;
    _set(state.copyWith(loadFailure: () => null));
    unawaited(_start(data));
  }

  /// A new profile is on UTC: give it the device's zone, so "today" and the months are the person's.
  /// Once, and only while the stored zone is still the default. (The app sends its zone with every
  /// request, so its profile has it from the start; this is the web's rule, for the day it has not.)
  Future<void> _sendZone(HomeData data) async {
    if (_zoneSent) return;
    final next = timeZoneToSave(data.timezone, _device.timeZone, supportedTimeZones());
    if (next == null) return;
    _zoneSent = true;
    try {
      await _repo.patchMe(timezone: next);
      await _home.profileChanged();
    } on Object {
      // A nicety: the person can still set it in settings.
    }
  }

  /// The currency to preselect: with transactions (the currency is locked), the account's, even over
  /// a choice in the draft (an import may have switched it since); else one they chose before; else
  /// the default for where they are (CO -> COP, Europe -> EUR, else USD).
  String? _preset() {
    final data = _data;
    final draft = state.draft;
    final has = state.hasTransactions;
    if (data == null || draft == null || has == null) return null;
    if (has && isSupportedCurrency(data.currency)) return data.currency;
    final chosen = draft.currency;
    if (chosen != null) return chosen;
    return defaultCurrency(_device.languages, _device.timeZone);
  }

  /// Fills in what depends on several reads, once they are all in: the currency, the chosen chips
  /// and the budget fields.
  void _settle() {
    final data = _data;
    final draft = state.draft;
    if (!_alive || data == null || draft == null) return;
    var next = state;
    if (next.currency == null) {
      final first = _preset();
      if (first != null) next = next.copyWith(currency: first);
    }
    if (next.selected == null) {
      final active = activeCategories;
      final fresh = active.isEmpty && !draft.categoriesDone;
      next = next.copyWith(
        selected: {
          ...?draft.selected,
          if (draft.selected == null)
            ...(fresh
                ? suggestedCategories.map((s) => suggestionChipId(s.key))
                : active.map((c) => c.id)),
        },
      );
    }
    if (!next.seeded && _locale != null) {
      final flow = ref.read(importFlowProvider.notifier);
      flow.replaceDrafts({
        for (final c in data.categories.values)
          // `if (c.currentBudget)`: a budget of zero is none.
          if (c.currentBudget != null && c.currentBudget != 0)
            c.id: draftFromCents(c.currentBudget!, locale),
      });
      next = next.copyWith(seeded: true);
    }
    if (!identical(next, state)) _set(next);
  }

  void _onImport(ImportFlowState? before, ImportFlowState now) {
    final phase = now.phase;
    final was = before?.phase;
    if (phase is! ImportImported) return;
    // The rows are in. If the account took the file's currency, so does the step.
    final note = phase.currencyNote;
    if (was is! ImportImported && note?.kind == CurrencyNoteKind.switched) {
      if (isSupportedCurrency(note!.file)) _set(state.copyWith(currency: note.file));
    }
    // Once the categories are read again, what the file brought is chosen.
    final done = !phase.retrying && phase.error == null;
    final wasDone = was is ImportImported && !was.retrying && was.error == null;
    if (done && !wasDone) unawaited(_imported());
  }

  /// After an import: what it brought is chosen; the suggestions it doesn't cover are not. The
  /// account has transactions now, so its currency is locked.
  Future<void> _imported() async {
    if (!_alive) return;
    _choose({for (final c in activeCategories) c.id});
    try {
      final has = await _homeRepo.hasTransactions();
      if (_alive) _set(state.copyWith(hasTransactions: has));
    } on Object {
      // Not knowing keeps what was known.
    }
  }

  HomeFailure _failure(Object error) {
    if (error is HomeFailure) {
      if (error.unauthorized) {
        unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
      }
      return error;
    }
    return const HomeFailure(0);
  }

  void _updateDraft(OnboardingDraft Function(OnboardingDraft) change) {
    final draft = state.draft;
    final data = _data;
    if (draft == null || data == null) return;
    final next = change(draft);
    _set(state.copyWith(draft: next));
    unawaited(_drafts.save(data.userId, next));
  }

  /// A step's current currency chosen on the screen.
  void chooseCurrency(String code) {
    _set(state.copyWith(currency: code));
    _updateDraft((d) => d.copyWith(currency: code));
  }

  /// Clears the error shown on a step (moving to another one).
  void clearError() {
    if (state.error != null) _set(state.copyWith(error: () => null));
  }

  /// Runs one write at a time; a failure is shown on the step and keeps it. True when it went
  /// through.
  Future<bool> _run(Future<void> Function() write) async {
    if (_inFlight) return false;
    _inFlight = true;
    _set(state.copyWith(busy: true, error: () => null));
    try {
      await write();
      return true;
    } on Object catch (problem) {
      if (_alive) _set(state.copyWith(error: () => _failure(problem)));
      return false;
    } finally {
      _inFlight = false;
      if (_alive) _set(state.copyWith(busy: false));
    }
  }

  /// The categories, read again: the screen and the returned list agree. Throws when the read
  /// fails: callers need the fresh list, not a stale one.
  Future<void> _refreshCategories() async {
    await _home.reloaded();
    final home = ref.read(homeProvider);
    if (home.data == null || home.stale || home.failure != null) {
      throw home.failure ??
          (home.staleOffline
              ? const HomeFailure(0)
              : const HomeFailure(500, code: 'internal_error'));
    }
  }

  String get _profileCurrency => _data?.currency ?? '';

  /// The currency set, only while the account is empty (a locked one is not a failure here).
  Future<void> _applyCurrency(String code) async {
    if (code == _profileCurrency) return;
    try {
      await _repo.patchMe(currency: code);
      await _home.profileChanged();
    } on HomeFailure catch (problem) {
      if (problem.code != 'currency_locked') rethrow;
    }
  }

  /// Sets the onboarding flag, celebrates and leaves the welcome (the session sends the person home).
  Future<void> _complete() async {
    final data = _data;
    await _repo.patchMe(onboardingCompleted: true);
    if (data != null) await _drafts.clear(data.userId);
    // What the welcome wrote reaches home: its figures, the categories, the widget.
    unawaited(_home.reloaded());
    if (!_alive) return;
    ref.read(feedbackProvider)(FeedbackEvent.saved);
    await ref.read(sessionProvider.notifier).onboardingDone();
  }

  // -- The steps ---------------------------------------------------------------------------------

  /// ENTRAR DIRECTO: the preselected currency, the suggested categories, no budgets, then the app.
  /// Safe to tap again after a failure: the suggestions are re-read before creating the missing
  /// ones. It never leaves the account without categories: if every one is archived (all deselected
  /// in an earlier visit), the suggestions come back.
  Future<bool> enterDirectly() => _run(() async {
    if (state.hasTransactions != true) await _applyCurrency(state.currency!);
    final all = suggestedCategories.map((s) => s.key).toSet();
    await createSuggestions(_repo, all, locale);
    await _refreshCategories();
    await _complete();
  });

  /// SIGUIENTE on the currency: saved, and kept in the draft.
  Future<bool> saveCurrency() => _run(() async {
    final currency = state.currency!;
    if (currency != _profileCurrency) {
      await _repo.patchMe(currency: currency);
      await _home.profileChanged();
    }
    _updateDraft((d) => d.copyWith(currency: currency));
  });

  /// SALTAR on the currency: the preselected currency, set while the account is empty.
  Future<bool> skipCurrency() => _run(() async {
    final code = _preset() ?? state.currency!;
    if (state.hasTransactions != true) await _applyCurrency(code);
    _set(state.copyWith(currency: code));
  });

  /// SIGUIENTE on the categories: the chosen suggestions made, the deselected ones archived.
  Future<bool> saveCategories() => _run(() async {
    await applyCategorySelection(_repo, chips, state.selected!, locale, archive: true);
    await _refreshCategories();
    _updateDraft((d) => d.copyWith(categoriesDone: true));
  });

  /// SALTAR on the categories: the chosen suggestions made, nothing taken away.
  Future<bool> skipCategories() => _run(() async {
    await applyCategorySelection(_repo, chips, state.selected!, locale, archive: false);
    await _refreshCategories();
    _updateDraft((d) => d.copyWith(categoriesDone: true));
  });

  /// SALTAR or "No, empiezo de cero" on the import: never while it is busy; a pending preview is
  /// dropped first. True when the step may be left.
  Future<bool> skipImport() async {
    var left = false;
    await _run(() async {
      left = await ref.read(importFlowProvider.notifier).skip();
    });
    return left;
  }

  /// SIGUIENTE on the budgets: saves the ones typed or prefilled, then finishes.
  Future<bool> finish() => _run(() async {
    final drafts = ref.read(importFlowProvider).drafts;
    final data = _data;
    final month = data == null ? '' : data.todayAt(ref.read(clockProvider)()).substring(0, 7);
    await saveBudgets(_repo, activeCategories, drafts, locale, month);
    await _complete();
  });

  /// SALTAR on the budgets: finishes without them.
  Future<bool> skipBudgets() => _run(_complete);

  // -- The categories step -------------------------------------------------------------------------

  /// The chips: the person's categories first (after an import, the file's) and then the
  /// suggestions they don't cover, less the ones they removed from the step.
  List<CategoryChipModel> get chips {
    final hidden = state.draft?.hiddenSuggestions.toSet() ?? const <String>{};
    return [
      for (final c in categoryChips(activeCategories, locale))
        if (c.source == ChipSource.category || !hidden.contains(c.suggestionKey ?? '')) c,
    ];
  }

  Set<String> get _current => state.selected ?? <String>{};

  void _choose(Set<String> next) {
    _set(state.copyWith(selected: next));
    _updateDraft((d) => d.copyWith(selected: next.toList()));
  }

  /// Chooses or drops a chip. One of their categories with transactions can't be dropped (that
  /// would archive it with its history out of sight): it stays chosen and the notice says why.
  Future<void> toggle(String id) async {
    _set(state.copyWith(notice: () => null));
    final chip = chips.where((c) => c.id == id).firstOrNull;
    final next = {..._current};
    if (!next.contains(id)) {
      next.add(id);
      _choose(next);
      return;
    }
    if (chip != null && chip.source == ChipSource.category) {
      try {
        final (:count, :capped) = await countCategoryTransactions(_repo, id);
        if (count > 0) {
          _set(
            state.copyWith(
              notice: () => HasTransactionsNotice(chip.name, count: count, capped: capped),
            ),
          );
          return;
        }
      } on Object {
        _set(state.copyWith(notice: () => UnknownNotice(chip.name)));
        return;
      }
    }
    next.remove(id);
    _choose(next);
  }

  /// "＋ Agregar categoría": made right away, and chosen.
  Future<void> create(NewCategory category) async {
    final Category created;
    try {
      created = await _repo.createCategory(
        name: category.name,
        kind: category.kind,
        icon: category.glyph,
        color: category.tint,
      );
    } on Object catch (error) {
      throw _failure(error);
    }
    _choose({..._current, created.id});
    // The sheet closes once it is saved; the chip shows when the list comes back.
    unawaited(_refreshCategories().then((_) {}, onError: (Object _) {}));
  }

  /// How many transactions a chip's category has (a suggestion has none).
  Future<({int count, bool capped})> transactionsOf(String chipId) async {
    final chip = chips.where((c) => c.id == chipId).firstOrNull;
    if (chip == null || chip.source == ChipSource.suggestion) return (count: 0, capped: false);
    return countCategoryTransactions(_repo, chipId);
  }

  /// Saves an edit. A suggestion is made right away with the edited values; one of their categories
  /// is changed in one PATCH (the API refuses a kind change while it has transactions).
  Future<void> edit(String chipId, NewCategory values) async {
    final chip = chips.where((c) => c.id == chipId).firstOrNull;
    if (chip == null) return;
    try {
      if (chip.source == ChipSource.suggestion) {
        final created = await _repo.createCategory(
          name: values.name,
          kind: values.kind,
          icon: values.glyph,
          color: values.tint,
        );
        final next = {..._current}
          ..remove(chipId)
          ..add(created.id);
        _choose(next);
      } else {
        final category = _data?.categories[chipId];
        if (category == null) return;
        await saveCategoryEdit(
          _repo,
          category,
          CategoryEdit(
            name: values.name,
            glyph: values.glyph,
            tint: values.tint,
            kind: values.kind,
          ),
        );
      }
      await _refreshCategories();
    } on Object catch (error) {
      throw _failure(error);
    }
  }

  /// "Eliminar" (no transactions) or "Archivar": one of their categories is archived (the API has no
  /// hard delete); a suggestion not made yet just leaves the step for this session.
  Future<void> remove(String chipId) async {
    final chip = chips.where((c) => c.id == chipId).firstOrNull;
    if (chip == null) return;
    _choose({..._current}..remove(chipId));
    if (chip.source == ChipSource.suggestion) {
      _updateDraft(
        (d) => d.copyWith(hiddenSuggestions: [...d.hiddenSuggestions, chip.suggestionKey ?? '']),
      );
      return;
    }
    try {
      await archiveCategory(_repo, chipId);
      await _refreshCategories();
    } on Object catch (error) {
      throw _failure(error);
    }
  }
}

final welcomeProvider = NotifierProvider.autoDispose<WelcomeController, WelcomeState>(
  WelcomeController.new,
);
