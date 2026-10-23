import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../api/gen/lukitas_api.dart';
import 'add_repository.dart';
import 'idempotency_key.dart';
import 'keypad_input.dart';

enum Kind { expense, income }

/// How many category chips show before "Más" on a roomy screen (two rows of four, "Más" being the
/// eighth), and on a short one (a single row), as the web's `VISIBLE_CHIPS`.
const visibleChipsRoomy = 7;
const visibleChipsShort = 3;

/// The add sheet's state and the rules behind it, a port of the web's `useTransactionForm`
/// (apps/web/app/features/add-transaction/use-add-transaction.ts): the kind, the amount (as raw
/// keypad text), the name and its suggestions, the category, the date, pending and the note; and
/// what saving would send. With [editing] it starts from that movement and builds a patch of what
/// changed.
///
/// The Idempotency-Key belongs to one attempt to save one movement: [keyForSave] makes it the
/// first time it is asked for (the first press of Guardar) and gives the same one back for
/// Reintentar; any change of the input drops it, so the next save is a new attempt.
class AddForm extends ChangeNotifier {
  AddForm({
    required this.locale,
    required this.currency,
    required this.today,
    this.editing,
    Kind kind = Kind.expense,
    String? categoryId,
    String Function()? newKey,
  }) : _newKey = newKey ?? newIdempotencyKey,
       _kind = editing == null ? kind : (editing.amount > 0 ? Kind.income : Kind.expense) {
    final tx = editing;
    if (tx != null) {
      raw = keypadText(tx.amount, locale, currency);
      _name = tx.name;
      _categoryId = tx.categoryId;
      _date = tx.date;
      _pending = tx.status == TransactionStatusEnum.pending;
      _note = tx.note ?? '';
    } else {
      _date = today;
      // Opened from a category's detail: that category, as the web's `openAdd(categoryId)`. It is
      // not something the person chose, so it never counts as input.
      _categoryId = categoryId;
    }
  }

  /// `es` or `en`.
  final String locale;
  final String currency;

  /// Today (`YYYY-MM-DD`) in the profile's time zone.
  final String today;
  final Transaction? editing;
  final String Function() _newKey;

  AmountFormat get format => AmountFormat(locale, currency);

  // -- what the person chose -----------------------------------------------------------------

  Kind _kind;
  String raw = '';
  String _name = '';

  /// The suggestion whose name was picked, while the name is still exactly it.
  String? _picked;

  /// The name was typed in or picked: it is no longer the movement's own, untouched one.
  bool _nameTouched = false;
  String? _categoryId;

  /// Only a category the person picked goes into an edit's patch: never a fallback.
  bool _categoryChosen = false;
  String _date = '';
  bool _pending = false;
  String _note = '';

  /// "Más" was tapped: every category shows.
  bool get allChips => _allChips;
  bool _allChips = false;
  set allChips(bool value) {
    _allChips = value;
    notifyListeners();
  }

  String? _key;

  /// The categories (archived ones too) and the recent movements that order them by use. Set by
  /// the sheet on every build; the form does not notify for it.
  List<Category> _categories = const [];
  List<Transaction> _recent = const [];

  void updateChoices(List<Category> categories, List<Transaction> recent) {
    _categories = categories;
    _recent = recent;
  }

  void _changed() {
    _key = null;
    _hasInput = true;
    notifyListeners();
  }

  bool _hasInput = false;

  /// The person has typed, picked or switched something here (every change comes from them): a
  /// widget or tile link then leaves the sheet alone (lib/launch/launch_links.dart).
  bool get hasInput => _hasInput;

  // -- getters -------------------------------------------------------------------------------

  Kind get kind => _kind;
  String get date => _date;
  bool get pending => _pending;
  String get note => _note;

  Category? get _editingCategory {
    final id = editing?.categoryId;
    return id == null ? null : _categories.where((c) => c.id == id).firstOrNull;
  }

  CategoryKindEnum get _kindEnum =>
      _kind == Kind.income ? CategoryKindEnum.income : CategoryKindEnum.expense;

  /// The categories a movement of this kind can go in, most used first and then in their own
  /// order. An edited movement keeps offering its own category, even archived (first, so it shows
  /// among the visible chips); a new one only goes in active ones.
  List<Category> get ofKind {
    final uses = <String, int>{};
    for (final tx in _recent) {
      uses[tx.categoryId] = (uses[tx.categoryId] ?? 0) + 1;
    }
    final active = [
      for (final c in _categories)
        if (!c.archived && c.kind == _kindEnum) c,
    ];
    final order = {for (var i = 0; i < active.length; i++) active[i].id: i};
    active.sort((a, b) {
      final byUse = (uses[b.id] ?? 0) - (uses[a.id] ?? 0);
      if (byUse != 0) return byUse;
      final bySort = a.sortOrder - b.sortOrder;
      return bySort != 0 ? bySort : order[a.id]! - order[b.id]!;
    });
    final own = _editingCategory;
    return own != null && own.archived && own.kind == _kindEnum ? [own, ...active] : active;
  }

  Category? get selected {
    final list = ofKind;
    final id = _categoryId;
    if (id != null) {
      final match = list.where((c) => c.id == id).firstOrNull;
      if (match != null) return match;
    }
    return list.firstOrNull;
  }

  /// Whether some categories are folded behind "Más" ([visible] chips show before it).
  bool overflow({required int visible}) => ofKind.length > visible + 1;

  /// The chips shown: all of them, or [visible] of them with the selected one always among them.
  List<Category> chips({required int visible}) {
    final list = ofKind;
    if (!overflow(visible: visible) || _allChips) return list;
    final shown = list.take(visible).toList();
    final choice = selected;
    if (choice != null && !shown.contains(choice)) {
      return [...shown.take(visible - 1), choice];
    }
    return shown;
  }

  /// An edited movement whose name is just its category's shows the name as the placeholder, until
  /// the person touches the field: whatever they type after that is kept exactly, even when it
  /// passes through the category's own name on the way to a longer one.
  String get name {
    final own = _editingCategory;
    final untouchedDefault =
        editing != null && !_nameTouched && own != null && _name == own.name && _picked == null;
    return untouchedDefault ? '' : _name;
  }

  /// What the API is asked for while the person types a name. After a pick the full list stays.
  String get suggestionQuery => _picked != null && _name == _picked ? '' : _name.trim();

  /// Pesos: a typed separator only ends the amount; what comes before it is the amount.
  int get cents => amountCents(raw, format);

  bool get valid => cents > 0 && selected != null && _date.isNotEmpty;

  // -- changes -------------------------------------------------------------------------------

  void press(KeypadKey key) {
    final next = pressKey(raw, key, format);
    if (next == raw) return;
    raw = next;
    _changed();
  }

  /// The keypad (or a keyboard, or a paste) made the amount [next], as raw text.
  void setRaw(String next) {
    if (next == raw) return;
    raw = next;
    _changed();
  }

  void setKind(Kind next) {
    final target = next == Kind.income ? CategoryKindEnum.income : CategoryKindEnum.expense;
    // The category chosen under the old kind does not carry over: the new kind starts at its first.
    final keeps = selected?.kind == target;
    _kind = next;
    if (keeps) {
      _changed();
    } else {
      select(null);
    }
  }

  void setName(String next) {
    if (next != _picked) _picked = null;
    _nameTouched = true;
    _name = next;
    _changed();
  }

  void pick(TransactionSuggestion suggestion) {
    _name = suggestion.name;
    _nameTouched = true;
    _picked = suggestion.name;
    final category = _categories.where((c) => c.id == suggestion.categoryId).firstOrNull;
    if (category != null) {
      _kind = category.kind == CategoryKindEnum.income ? Kind.income : Kind.expense;
    }
    select(suggestion.categoryId);
  }

  void select(String? id) {
    _categoryId = id;
    _categoryChosen = true;
    _changed();
  }

  void setDate(String next) {
    _date = next;
    _changed();
  }

  set pending(bool value) {
    _pending = value;
    _changed();
  }

  void setNote(String next) {
    _note = next;
    _changed();
  }

  // -- saving --------------------------------------------------------------------------------

  /// The key of this attempt to save: made the first time it is asked for, the same until the
  /// input changes.
  String keyForSave() => _key ??= _newKey();

  /// What a new movement would be: unnamed, it takes its category's name.
  CreateTransaction? input() {
    final category = selected;
    if (!valid || category == null) return null;
    final trimmed = name.trim();
    final trimmedNote = _note.trim();
    return CreateTransaction(
      (b) => b
        ..name = trimmed.isEmpty ? category.name : trimmed
        ..amount = _kind == Kind.expense ? -cents : cents
        ..categoryId = category.id
        ..date = _date
        ..status = _pending ? CreateTransactionStatusEnum.pending : CreateTransactionStatusEnum.paid
        ..note = trimmedNote.isEmpty ? null : trimmedNote
        ..source_ = CreateTransactionSource_Enum.app,
    );
  }

  /// The fields of [editing] that changed.
  TransactionPatch patch() {
    final tx = editing;
    final next = input();
    if (tx == null || next == null) return const TransactionPatch();
    final nextNote = _note.trim().isEmpty ? null : _note.trim();
    final status = _pending ? TransactionStatusEnum.pending : TransactionStatusEnum.paid;
    final noteChanged = nextNote != tx.note;
    return TransactionPatch(
      name: next.name != tx.name ? next.name : null,
      amount: next.amount != tx.amount ? next.amount : null,
      categoryId: _categoryChosen && next.categoryId != tx.categoryId ? next.categoryId : null,
      date: next.date != tx.date ? next.date : null,
      pending: status != tx.status ? _pending : null,
      setNote: noteChanged,
      note: noteChanged ? nextNote : null,
    );
  }
}
