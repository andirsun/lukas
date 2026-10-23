import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../home/saved_feedback.dart';
import '../home/toast.dart';
import '../l10n/app_localizations.dart';
import '../ui/amount_field.dart';
import '../ui/lk_theme.dart';
import '../ui/name_field.dart';
import 'add_form.dart';
import 'add_repository.dart';
import 'add_request.dart';
import 'save_outcome.dart';

/// The add, edit or capture sheets open now that hold the person's input. A plain registry, not
/// state: it is read when a link arrives (lib/launch/launch_links.dart), never watched.
class SheetsWithInput {
  final _open = <Object>{};

  /// Whether any open sheet holds input.
  bool get any => _open.isNotEmpty;

  void mark(Object sheet, {required bool hasInput}) =>
      hasInput ? _open.add(sheet) : _open.remove(sheet);
}

final sheetsWithInputProvider = Provider<SheetsWithInput>((ref) => SheetsWithInput());

/// What the add sheet's parts (the kind and amount, the name and categories, the keypad and
/// Guardar) share while it is open. It holds the form and the controllers behind it, the save and
/// what it answered, and the suggestions; [AddSession.of] gives a part the state and rebuilds it
/// when anything in it changes. The sheet itself is [LkSheet] (lib/ui/sheet.dart): this wraps it
/// (`LkSheet.show(wrap: ...)`), so it lives and dies with the sheet's route.
///
/// Built by `openAddSheet` and `openEditSheet`.
class AddSheet extends ConsumerStatefulWidget {
  const AddSheet({super.key, required this.request, required this.nameIt, required this.child});

  final AddRequest request;

  /// Opens a saved movement on its name ("Ponerle nombre" on the toast).
  final Future<void> Function(BuildContext context, Transaction tx) nameIt;
  final Widget child;

  @override
  ConsumerState<AddSheet> createState() => AddSheetState();
}

class AddSheetState extends ConsumerState<AddSheet> {
  AddRequest get request => widget.request;

  /// Null until home has loaded (the categories and the currency are in its figures).
  AddForm? form;
  final name = TextEditingController();
  final nameFocus = FocusNode();
  final note = TextEditingController();
  final noteFocus = FocusNode();

  var saving = false;
  HomeFailure? failure;
  var moreOpen = false;

  /// What home holds now, and the words, for the parts to read.
  HomeState home = const HomeState();
  late AppLocalizations l10n;

  List<TransactionSuggestion> _suggestions = const [];
  String? _askedFor;
  var _suggestionSeq = 0;
  Timer? _pause;
  var _version = 0;

  /// Read once here: dispose may not use ref.
  late final SheetsWithInput _withInput;

  @override
  void initState() {
    super.initState();
    _withInput = ref.read(sheetsWithInputProvider);
  }

  @override
  void dispose() {
    _withInput.mark(this, hasInput: false);
    _pause?.cancel();
    form?.dispose();
    name.dispose();
    nameFocus.dispose();
    note.dispose();
    noteFocus.dispose();
    super.dispose();
  }

  AddForm _ensureForm(HomeData data) {
    final existing = form;
    if (existing != null) return existing;
    final created = AddForm(
      locale: l10n.localeName,
      currency: data.currency,
      today: data.todayAt(ref.read(clockProvider)()),
      editing: request.editing,
      kind: request.kind,
      categoryId: request.categoryId,
    );
    created.updateChoices(data.categories.values.toList(), data.items);
    name.text = created.name;
    note.text = created.note;
    created.addListener(_onFormChanged);
    form = created;
    _askSuggestions(created);
    if (request.focusName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) nameFocus.requestFocus();
      });
    }
    return created;
  }

  void _onFormChanged() {
    final current = form!;
    _withInput.mark(this, hasInput: current.hasInput);
    if (name.text != current.name) name.text = current.name;
    _askSuggestions(current);
    setState(() {});
  }

  /// Asks for the names that match what is typed: at once for the top ones, after a short pause
  /// while typing.
  void _askSuggestions(AddForm current) {
    final query = current.suggestionQuery;
    if (query == _askedFor) return;
    _askedFor = query;
    _pause?.cancel();
    if (query.isEmpty) {
      unawaited(_fetchSuggestions(query));
    } else {
      _pause = Timer(const Duration(milliseconds: 200), () => unawaited(_fetchSuggestions(query)));
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    final asked = ++_suggestionSeq;
    try {
      final found = await ref.read(addRepositoryProvider).suggestions(query);
      // Only the latest question counts: an older answer that lands late is dropped.
      if (!mounted || asked != _suggestionSeq) return;
      setState(() => _suggestions = found);
    } on Object {
      // The shortcuts are a convenience: without them the name is just typed.
    }
  }

  /// The recent names that can be offered: those whose category is still active.
  List<NameChoice> get shortcuts {
    final categories = home.data?.categories;
    if (categories == null) return const [];
    return [
      for (final s in _suggestions)
        if (categories[s.categoryId] case final category? when !category.archived)
          NameChoice(name: s.name, categoryName: category.name, source: s),
    ];
  }

  void toggleMore() => setState(() => moreOpen = !moreOpen);

  Future<void> pickDate() async {
    final current = form;
    if (current == null) return;
    final from = DateTime.tryParse(current.date) ?? DateTime.tryParse(current.today)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    current.setDate(
      '${picked.year.toString().padLeft(4, '0')}-${two(picked.month)}-${two(picked.day)}',
    );
  }

  void retryLoad() => unawaited(ref.read(homeProvider.notifier).refresh());

  // -- saving --------------------------------------------------------------------------------

  Future<void> save() async {
    final current = form;
    if (saving || current == null || !current.valid) return;
    final editing = current.editing;
    final repo = ref.read(addRepositoryProvider);
    // What outlives the sheet: the toast, Deshacer, and the home update.
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colors = context.lkColors;
    final words = l10n;
    final currency = current.currency;
    final kind = current.kind;
    final categoryName = current.selected?.name ?? '';
    final unnamed = current.name.trim().isEmpty;

    final patch = editing == null ? null : current.patch();
    if (patch != null && patch.isEmpty) {
      navigator.pop();
      return;
    }
    // One key per attempt: made at the first press, the same for Reintentar, new after any edit.
    final input = editing == null ? current.input() : null;
    final key = editing == null ? current.keyForSave() : null;

    setState(() {
      saving = true;
      failure = null;
    });
    try {
      final Transaction saved = editing == null
          ? await repo.create(input!, idempotencyKey: key!)
          : await repo.update(editing.id, patch!);
      final homeController = container.read(homeProvider.notifier);
      if (editing == null) {
        // The feel follows the figures (near or over a limit say so), as on the web.
        unawaited(feelSaved(container, homeController.saved(saved), [saved]));
      } else {
        unawaited(homeController.updated(saved));
      }
      if (mounted) navigator.pop();
      if (editing == null) {
        toastCreated(
          container: container,
          messenger: messenger,
          navigator: navigator,
          colors: colors,
          l10n: words,
          created: saved,
          kind: kind,
          categoryName: categoryName,
          currency: currency,
          unnamed: unnamed,
          nameIt: widget.nameIt,
        );
      } else {
        showToast(messenger, colors, words.addUpdated(saved.name));
      }
    } on HomeFailure catch (answer) {
      if (answer.unauthorized) {
        unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
        if (mounted) navigator.pop();
        return;
      }
      if (mounted) {
        setState(() {
          saving = false;
          failure = answer;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          saving = false;
          failure = const HomeFailure(500);
        });
      }
    }
  }

  /// Eliminar: the sheet closes at once and the movement goes, with Deshacer on the toast.
  void delete() {
    final tx = form?.editing;
    if (saving || tx == null) return;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.lkColors;
    final words = l10n;
    setState(() => saving = true);
    Navigator.of(context).pop();
    unawaited(
      deleteMovement(
        container: container,
        messenger: messenger,
        colors: colors,
        l10n: words,
        transaction: tx,
      ),
    );
  }

  // -- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    home = ref.watch(homeProvider);
    final data = home.data;
    final AddForm? current;
    if (data == null) {
      current = form;
    } else {
      current = _ensureForm(data)..updateChoices(data.categories.values.toList(), data.items);
    }
    _version++;
    // A physical keyboard and the clipboard type on the keypad (the web's `useAmountKeys`).
    return AddSession(
      state: this,
      version: _version,
      child: AmountKeys(
        raw: current?.raw ?? '',
        currency: current?.currency ?? '',
        onChanged: (next) => current?.setRaw(next),
        child: widget.child,
      ),
    );
  }

  /// The sheet's title: new expense, new income, or editing.
  String title(BuildContext context) {
    final words = AppLocalizations.of(context);
    if (request.editing != null) return words.addTitleEdit;
    return (form?.kind ?? request.kind) == Kind.income
        ? words.addTitleIncome
        : words.addTitleExpense;
  }
}

/// Gives the parts of the open add sheet its [AddSheetState] and rebuilds them when it changes.
class AddSession extends InheritedWidget {
  const AddSession({super.key, required this.state, required this.version, required super.child});

  final AddSheetState state;

  /// Changes with every rebuild of the state: what depends on it rebuilds.
  final int version;

  static AddSheetState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AddSession>()!.state;

  @override
  bool updateShouldNotify(AddSession old) => old.version != version;
}
