import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../feedback/feedback.dart';
import '../home/home_controller.dart';
import '../home/home_format.dart';
import '../home/home_repository.dart';
import '../home/saved_feedback.dart';
import '../home/home_widgets.dart';
import '../home/toast.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'add_form.dart';
import 'add_repository.dart';
import 'category_chips.dart';
import 'keypad.dart';
import 'keypad_input.dart';
import 'name_field.dart';

export 'add_form.dart' show Kind;

/// Opens the add sheet (spec section 6.1.3) to enter one movement by hand, on [kind]. It is the
/// one way in: the ＋ on home calls it, and so will the widget's deep link. It needs only the
/// app's providers (the home figures it reads categories and the currency from, and the API), no
/// home screen state.
///
/// Completes when the sheet is closed. A save closes it by itself, updates home and shows the
/// toast with Deshacer.
///
/// [categoryId] preselects a category (the "Agregar gasto" of a category's detail); the sheet
/// falls back to the first of [kind] when it is not one.
Future<void> openAddSheet(BuildContext context, {Kind kind = Kind.expense, String? categoryId}) =>
    _open(context, _Request(kind: kind, categoryId: categoryId));

/// Opens the sheet on an existing [transaction] (a tap on its row, a swipe right, "Ponerle
/// nombre"): saving sends only what changed. [focusName] puts the cursor on the name.
Future<void> openEditSheet(
  BuildContext context,
  Transaction transaction, {
  bool focusName = false,
}) => _open(context, _Request(editing: transaction, focusName: focusName));

class _Request {
  const _Request({this.kind = Kind.expense, this.editing, this.focusName = false, this.categoryId});

  final Kind kind;
  final String? categoryId;
  final Transaction? editing;
  final bool focusName;
}

Future<void> _open(BuildContext context, _Request request) {
  final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
  // Under "remove animations" the sheet appears and goes without sliding.
  final duration = MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : LukitasTokens.durationSheet;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LukitasTokens.radiusXl)),
    ),
    sheetAnimationStyle: AnimationStyle(duration: duration, reverseDuration: duration),
    builder: (context) => AddSheet(request: request),
  );
}

/// Whether sending the same request again can work: no answer at all (offline, a lost
/// connection), a server error or timeout, too many requests, or the first try still running. Not
/// a refusal (a 4xx such as an invalid amount), which says the same every time.
bool canRetrySave(HomeFailure failure) =>
    failure.status == 0 ||
    failure.status >= 500 ||
    failure.status == 408 ||
    failure.status == 429 ||
    failure.code == 'idempotency_in_progress';

String _failureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  if (failure.code == 'idempotency_in_progress') return l10n.addErrorBusy;
  if (failure.code == 'category_not_found') return l10n.addErrorCategory;
  if (failure.status == 404) return l10n.addErrorNotFound;
  if (failure.status == 422) return l10n.addErrorInvalid;
  return failure.status >= 500 ? l10n.errorInternal : l10n.errorGeneric;
}

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

/// The sheet itself. Built by [openAddSheet] and [openEditSheet].
class AddSheet extends ConsumerStatefulWidget {
  const AddSheet({super.key, required this.request});

  final Object request;

  @override
  ConsumerState<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<AddSheet> {
  _Request get _request => widget.request as _Request;

  AddForm? _form;
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _note = TextEditingController();

  var _saving = false;
  HomeFailure? _failure;
  var _moreOpen = false;

  List<TransactionSuggestion> _suggestions = const [];
  String? _askedFor;
  var _suggestionSeq = 0;
  Timer? _pause;

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
    _form?.dispose();
    _name.dispose();
    _nameFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  AddForm _ensureForm(HomeData data, AppLocalizations l10n) {
    final existing = _form;
    if (existing != null) return existing;
    final form = AddForm(
      locale: l10n.localeName,
      currency: data.currency,
      today: data.todayAt(ref.read(clockProvider)()),
      editing: _request.editing,
      kind: _request.kind,
      categoryId: _request.categoryId,
    );
    form.updateChoices(data.categories.values.toList(), data.items);
    _name.text = form.name;
    _note.text = form.note;
    form.addListener(_onFormChanged);
    _form = form;
    _askSuggestions(form);
    if (_request.focusName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocus.requestFocus();
      });
    }
    return form;
  }

  void _onFormChanged() {
    final form = _form!;
    _withInput.mark(this, hasInput: form.hasInput);
    if (_name.text != form.name) _name.text = form.name;
    _askSuggestions(form);
    setState(() {});
  }

  /// Asks for the names that match what is typed: at once for the top ones, after a short pause
  /// while typing.
  void _askSuggestions(AddForm form) {
    final query = form.suggestionQuery;
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
    final request = ++_suggestionSeq;
    try {
      final found = await ref.read(addRepositoryProvider).suggestions(query);
      // Only the latest question counts: an older answer that lands late is dropped.
      if (!mounted || request != _suggestionSeq) return;
      setState(() => _suggestions = found);
    } on Object {
      // The shortcuts are a convenience: without them the name is just typed.
    }
  }

  // -- saving --------------------------------------------------------------------------------

  Future<void> _save(AppLocalizations l10n) async {
    final form = _form;
    if (_saving || form == null || !form.valid) return;
    final editing = form.editing;
    final repo = ref.read(addRepositoryProvider);
    // What outlives the sheet: the toast, Deshacer, and the home update.
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final currency = form.currency;
    final kind = form.kind;
    final categoryName = form.selected?.name ?? '';
    final unnamed = form.name.trim().isEmpty;

    final patch = editing == null ? null : form.patch();
    if (patch != null && patch.isEmpty) {
      navigator.pop();
      return;
    }
    // One key per attempt: made at the first press, the same for Reintentar, new after any edit.
    final input = editing == null ? form.input() : null;
    final key = editing == null ? form.keyForSave() : null;

    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      final Transaction saved = editing == null
          ? await repo.create(input!, idempotencyKey: key!)
          : await repo.update(editing.id, patch!);
      final home = container.read(homeProvider.notifier);
      if (editing == null) {
        // The feel follows the figures (near or over a limit say so), as on the web.
        unawaited(feelSaved(container, home.saved(saved), [saved]));
      } else {
        unawaited(home.updated(saved));
      }
      if (mounted) navigator.pop();
      if (editing == null) {
        _toastCreated(
          container: container,
          messenger: messenger,
          navigator: navigator,
          colors: colors,
          l10n: l10n,
          created: saved,
          kind: kind,
          categoryName: categoryName,
          currency: currency,
          unnamed: unnamed,
        );
      } else {
        showToast(messenger, colors, l10n.addUpdated(saved.name));
      }
    } on HomeFailure catch (failure) {
      if (failure.unauthorized) {
        unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
        if (mounted) navigator.pop();
        return;
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _failure = failure;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _failure = const HomeFailure(500);
        });
      }
    }
  }

  // -- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final home = ref.watch(homeProvider);
    final data = home.data;
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    final Widget content;
    if (data == null) {
      content = _Unloaded(
        failed: home.failure != null,
        message: home.failure == null
            ? l10n.homeLoading
            : (home.failure!.offline ? l10n.errorNetwork : l10n.errorGeneric),
        retryLabel: l10n.retry,
        onRetry: () => unawaited(ref.read(homeProvider.notifier).refresh()),
      );
    } else {
      final form = _ensureForm(data, l10n);
      form.updateChoices(data.categories.values.toList(), data.items);
      content = _body(context, l10n, colors, data, form, size, keyboard);
    }

    final editing = _request.editing != null;
    final title = editing
        ? l10n.addTitleEdit
        : (_form?.kind ?? _request.kind) == Kind.income
        ? l10n.addTitleIncome
        : l10n.addTitleExpense;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Padding(
        key: const Key('add.sheet'),
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(title: title, closeLabel: l10n.addClose),
              Flexible(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    LukitasColors colors,
    HomeData data,
    AddForm form,
    Size size,
    double keyboard,
  ) {
    final locale = l10n.localeName;
    final short = size.height < 800;
    final tight = size.height < 700;
    final choices = form.chips(visible: short ? visibleChipsShort : visibleChipsRoomy);
    final ofKind = form.ofKind;
    final hint = form.cents > 0 ? lukasHint(form.cents, locale, currency: form.currency) : null;
    final sign = form.cents > 0 ? (form.kind == Kind.expense ? '−' : '+') : '';
    final amountText =
        '$sign${formatAmountInput(wholeAmount(form.raw, form.format), form.currency, locale)}';
    final dateText = form.date == form.today
        ? l10n.addToday
        : form.date.isEmpty
        ? ''
        : formatDay(form.date, locale);
    final shortcuts = <NameChoice>[
      for (final s in _suggestions)
        if (data.categories[s.categoryId] case final category? when !category.archived)
          NameChoice(name: s.name, categoryName: category.name, source: s),
    ];
    final editing = form.editing != null;
    final failure = _failure;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The kind and the amount stay in view; what follows scrolls (if it must) under them.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KindSwitch(
                label: l10n.addKindLabel,
                kind: form.kind,
                expenseLabel: l10n.addKindExpense,
                incomeLabel: l10n.addKindIncome,
                onChanged: _saving ? null : form.setKind,
              ),
              const SizedBox(height: LukitasTokens.space2),
              _AmountDisplay(
                key: const Key('add.amount'),
                text: amountText,
                hint: hint,
                color: form.kind == Kind.expense ? colors.over : colors.good,
              ),
            ],
          ),
        ),
        const SizedBox(height: LukitasTokens.space2),
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NameField(
                    controller: _name,
                    focusNode: _nameFocus,
                    placeholder: form.selected?.name ?? l10n.nameFieldLabel,
                    suggestions: shortcuts,
                    onChanged: form.setName,
                    onPick: (choice) {
                      _nameFocus.unfocus();
                      form.pick(choice.source as TransactionSuggestion);
                    },
                  ),
                  const SizedBox(height: LukitasTokens.space2),
                  if (ofKind.isEmpty)
                    Text(
                      form.kind == Kind.income
                          ? l10n.addNoCategoriesIncome
                          : l10n.addNoCategoriesExpense,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.inkMuted,
                      ),
                    )
                  else
                    CategoryChips(
                      chips: choices,
                      selectedId: form.selected?.id,
                      overflow: form.overflow(
                        visible: short ? visibleChipsShort : visibleChipsRoomy,
                      ),
                      expanded: form.allChips,
                      onSelect: form.select,
                      onToggleAll: () => form.allChips = !form.allChips,
                    ),
                  const SizedBox(height: LukitasTokens.space2),
                  _MoreOptions(
                    open: _moreOpen,
                    onToggle: () => setState(() => _moreOpen = !_moreOpen),
                    summary: '$dateText · ${form.pending ? l10n.pending : l10n.paid}',
                    title: l10n.addMoreOptions,
                    children: [
                      _DateField(
                        label: l10n.addDateLabel,
                        text: form.date.isEmpty ? '' : _longDate(form.date, locale),
                        onTap: () => unawaited(_pickDate(context, form)),
                      ),
                      CheckboxListTile(
                        key: const Key('add.pending'),
                        value: form.pending,
                        onChanged: (v) => form.pending = v ?? false,
                        title: Text(
                          l10n.addPendingLabel,
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: colors.brand,
                        checkColor: colors.onBrand,
                        contentPadding: EdgeInsets.zero,
                      ),
                      TextField(
                        key: const Key('add.note'),
                        controller: _note,
                        onChanged: form.setNote,
                        maxLines: 2,
                        maxLength: 1000,
                        style: TextStyle(color: colors.ink, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: l10n.addNoteLabel,
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
                            borderSide: BorderSide(color: colors.stroke, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LukitasTokens.space2),
                ],
              ),
            ),
          ),
        ),
        // Pinned under the content, so every key and Guardar are in view even on short phones.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LukitasTokens.space4,
            LukitasTokens.space2,
            LukitasTokens.space4,
            LukitasTokens.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failure != null)
                _FailureRow(
                  message: _failureMessage(l10n, failure),
                  retryLabel: canRetrySave(failure) ? l10n.retry : null,
                  onRetry: () => unawaited(_save(l10n)),
                ),
              // With the phone's keyboard up (typing a name), it takes the keypad's place.
              if (keyboard == 0) ...[
                Keypad(
                  locale: locale,
                  currency: form.currency,
                  keyHeight: tight ? 44 : 52,
                  onKey: _saving ? (_) {} : form.press,
                ),
                const SizedBox(height: LukitasTokens.space2),
              ],
              FilledButton(
                key: const Key('add.save'),
                onPressed: form.valid && !_saving ? () => unawaited(_save(l10n)) : null,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(tight ? 48 : 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
                  ),
                ),
                child: _saving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const QuietSpinner(),
                          const SizedBox(width: LukitasTokens.space2),
                          Text(l10n.addSaving),
                        ],
                      )
                    : Text(editing ? l10n.addSaveChanges : l10n.addSave),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, AddForm form) async {
    final current = DateTime.tryParse(form.date) ?? DateTime.tryParse(form.today)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    form.setDate(
      '${picked.year.toString().padLeft(4, '0')}-${two(picked.month)}-${two(picked.day)}',
    );
  }
}

/// `22 oct 2026` / `Oct 22, 2026`: the date as the date field shows it.
String _longDate(String date, String locale) {
  final parsed = DateTime.tryParse(date);
  return parsed == null ? date : DateFormat.yMMMd(locale).format(parsed);
}

/// The toast after a new movement: what was saved, Deshacer (which takes it away again) and, for
/// a movement saved without a name, "Ponerle nombre" (which opens it on its name). Everything it
/// needs is passed in: the sheet is gone by the time anyone taps.
void _toastCreated({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required NavigatorState navigator,
  required LukitasColors colors,
  required AppLocalizations l10n,
  required Transaction created,
  required Kind kind,
  required String categoryName,
  required String currency,
  required bool unnamed,
}) {
  final locale = l10n.localeName;
  final amount = formatMoney(created.amount.abs(), currency, locale);
  final hint = lukasHint(created.amount, locale, currency: currency);
  final line = kind == Kind.income
      ? l10n.addSavedIncome(categoryName, amount)
      : l10n.addSavedExpense(categoryName, amount);
  showToast(
    messenger,
    colors,
    hint == null ? line : '$line $hint',
    actionLabel: l10n.undo,
    onAction: () => unawaited(_undoCreated(container, messenger, colors, l10n, created)),
    extraLabel: unnamed ? l10n.addNameIt : null,
    onExtra: unnamed
        ? () {
            if (navigator.mounted) {
              unawaited(openEditSheet(navigator.context, created, focusName: true));
            }
          }
        : null,
  );
}

Future<void> _undoCreated(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  LukitasColors colors,
  AppLocalizations l10n,
  Transaction created,
) async {
  try {
    await container.read(homeProvider.notifier).remove(created);
  } on HomeFailure catch (failure) {
    showToast(
      messenger,
      colors,
      failure.offline ? l10n.errorNetwork : l10n.errorGeneric,
      error: true,
    );
    return;
  }
  container.read(feedbackProvider)(FeedbackEvent.undo);
  showToast(messenger, colors, l10n.addUndone(created.name));
}

// -- pieces ----------------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.closeLabel});

  final String title;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.stroke,
            borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: LukitasTokens.space4, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(color: colors.ink, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              IconButton(
                key: const Key('add.close'),
                tooltip: closeLabel,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KindSwitch extends StatelessWidget {
  const _KindSwitch({
    required this.label,
    required this.kind,
    required this.expenseLabel,
    required this.incomeLabel,
    required this.onChanged,
  });

  final String label;
  final Kind kind;
  final String expenseLabel;
  final String incomeLabel;
  final ValueChanged<Kind>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    Widget segment(Kind value, String text) {
      final selected = kind == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: text,
          excludeSemantics: true,
          child: GestureDetector(
            key: Key('add.kind.${value.name}'),
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(LukitasTokens.radiusMd - 2),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? colors.onBrand : colors.inkMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
          border: Border.all(color: colors.stroke, width: 2),
        ),
        child: Row(
          children: [segment(Kind.expense, expenseLabel), segment(Kind.income, incomeLabel)],
        ),
      ),
    );
  }
}

/// The amount in big type with its lukas hint. Screen readers hear it once typing pauses, not on
/// every key.
class _AmountDisplay extends StatefulWidget {
  const _AmountDisplay({super.key, required this.text, required this.hint, required this.color});

  final String text;
  final String? hint;
  final Color color;

  @override
  State<_AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<_AmountDisplay> {
  late String _heard = _spoken;
  Timer? _timer;

  String get _spoken => widget.hint == null ? widget.text : '${widget.text} ${widget.hint}';

  @override
  void didUpdateWidget(_AmountDisplay old) {
    super.didUpdateWidget(old);
    if (_spoken == _heard) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _heard = _spoken);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Semantics(
      liveRegion: true,
      label: _heard,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.text),
              if (widget.hint != null)
                TextSpan(
                  text: ' ${widget.hint}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.inkMuted,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: widget.color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _MoreOptions extends StatelessWidget {
  const _MoreOptions({
    required this.open,
    required this.onToggle,
    required this.title,
    required this.summary,
    required this.children,
  });

  final bool open;
  final VoidCallback onToggle;
  final String title;
  final String summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: '$title, $summary',
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('add.more'),
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
                border: Border.all(color: colors.controlEdge, width: 2),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(color: colors.ink, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: LukitasTokens.space2),
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.inkMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: LukitasTokens.space2),
                  Text(open ? '▴' : '▾', style: TextStyle(color: colors.inkMuted)),
                ],
              ),
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: LukitasTokens.space2),
          for (final child in children) ...[child, const SizedBox(height: LukitasTokens.space2)],
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.text, required this.onTap});

  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Semantics(
      button: true,
      label: '$label, $text',
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('add.date'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space3),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
            border: Border.all(color: colors.stroke, width: 2),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(color: colors.inkMuted, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.ink, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureRow extends StatelessWidget {
  const _FailureRow({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String? retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: LukitasTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: TextStyle(color: colors.over, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (retryLabel != null)
            TextButton(
              key: const Key('add.retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: colors.gold),
              child: Text(retryLabel!),
            ),
        ],
      ),
    );
  }
}

/// The sheet before the categories are known (home has not loaded): a spinner, or why it failed.
class _Unloaded extends StatelessWidget {
  const _Unloaded({
    required this.failed,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool failed;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Padding(
      padding: const EdgeInsets.all(LukitasTokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!failed) const QuietSpinner(size: 28),
          const SizedBox(height: LukitasTokens.space3),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
            ),
          ),
          if (failed) ...[
            const SizedBox(height: LukitasTokens.space3),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ],
      ),
    );
  }
}
