import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_repository.dart';
import 'package:lukitas/welcome/onboarding_repository.dart';
import 'package:lukitas/welcome/suggested_categories.dart';

import '../import/fakes.dart' show importOf, sampleStats;

/// An [OnboardingRepository] that answers nothing: a test overrides the calls it makes.
class OnboardingRepositoryStub implements OnboardingRepository {
  @override
  Future<List<Category>> allCategories() => throw UnimplementedError();

  @override
  Future<Category> createCategory({
    required String name,
    required CategoryKindEnum kind,
    required String icon,
    required String color,
    int? sortOrder,
  }) => throw UnimplementedError();

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
    CategoryKindEnum? kind,
    bool? archived,
  }) => throw UnimplementedError();

  @override
  Future<TransactionsPage> categoryTransactions(String categoryId, {String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<void> setBudget(String categoryId, int cents, {required String month}) =>
      throw UnimplementedError();

  @override
  Future<void> patchMe({String? currency, String? timezone, bool? onboardingCompleted}) =>
      throw UnimplementedError();
}

// -- The story API of the welcome, in memory -------------------------------------------------------------

/// How a brand-new account's categories start (the web's `categories` option).
enum StartCategories { none, some, archived }

/// The server of the welcome's `Flow*` stories, in memory (the web's `onboardingFetch`,
/// apps/web/app/features/onboarding/story-harness.tsx): the profile, the categories, the sample
/// Budge file (always in EUR) and what confirming it does. It answers home's reads, the welcome's
/// writes and the import's, and records every write as `METHOD /v1/path {json body}`, in [requests].
class WelcomeWorld implements HomeRepository, OnboardingRepository, ImportRepository {
  WelcomeWorld({
    this.currency = 'EUR',
    this.timezone = 'America/Bogota',
    StartCategories categories = StartCategories.some,
    this.hasTransactionsAlready = false,
    this.oldExport = false,
    this.failCategoryPost,
    this.takenNames = const [],
    this.transactionsByName = const {},
    this.failCount = false,
    this.failConfirmOnce = false,
    this.failBudgetOnce = false,
    this.failRefreshesAfterConfirm = 0,
    bool budgeted = false,
  }) : _confirmFails = failConfirmOnce,
       _budgetFails = failBudgetOnce {
    stored.addAll(switch (categories) {
      StartCategories.none => const <Category>[],
      StartCategories.archived => [
        for (final (i, s) in suggestedCategories.indexed)
          _make('cat-${s.key}', s.names['es']!, s.kind, s.glyph, s.tint, i, archived: true),
      ],
      StartCategories.some => [
        _make(
          'cat-groceries',
          'Supermercado',
          CategoryKindEnum.expense,
          '🛒',
          '#ff9f1c',
          0,
          budget: budgeted ? 30000000 : null,
        ),
        _make('cat-salary', 'Salario', CategoryKindEnum.income, '💰', '#2fd388', 7),
      ],
    });
  }

  String currency;
  String timezone;
  String? onboardingCompletedAt;
  final bool hasTransactionsAlready;
  final bool oldExport;

  /// The Nth category POST (1-based) answers 503, once. `created`: the server made it anyway (the
  /// answer was lost on the way back).
  final ({int nth, bool created})? failCategoryPost;

  /// Names the server says are taken (409) although no list shows them.
  final List<String> takenNames;

  /// Transactions per category name (the categories step counts them before a delete).
  final Map<String, int> transactionsByName;
  final bool failCount;
  final bool failConfirmOnce;
  final bool failBudgetOnce;

  /// After a confirm, this many category reads fail (503).
  final int failRefreshesAfterConfirm;

  /// The account's categories, archived ones too.
  final stored = <Category>[];
  final requests = <String>[];
  var _categoryPosts = 0;
  var _uploads = 0;
  var _confirmed = false;
  var _refreshFailures = 0;
  bool _confirmFails;
  bool _budgetFails;

  /// Reading whether the account has transactions fails (503).
  bool failHasTransactions = false;

  /// While set, a confirm waits for it.
  Completer<void>? holdConfirm;

  /// While set, a category write waits for it.
  Completer<void>? holdWrites;

  Category _make(
    String id,
    String name,
    CategoryKindEnum kind,
    String icon,
    String color,
    int sortOrder, {
    bool archived = false,
    int? budget,
  }) => Category(
    (b) => b
      ..id = id
      ..name = name
      ..kind = kind
      ..icon = icon
      ..color = color
      ..sortOrder = sortOrder
      ..archived = archived
      ..currentBudget = budget,
  );

  /// The writes that are of the categories.
  List<String> get categoryPosts =>
      requests.where((l) => l.startsWith('POST /v1/categories ')).toList();

  void _record(String line) => requests.add(line);

  static String _json(Map<String, Object?> body) => jsonEncode(body);

  // -- Home's reads ------------------------------------------------------------------------------

  @override
  Future<HomeProfile> profile() async =>
      HomeProfile(id: 'u-new', currency: currency, timezone: timezone, email: 'ana@example.com');

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
  Future<List<Category>> categories() async {
    if (_refreshFailures > 0) {
      _refreshFailures -= 1;
      throw const HomeFailure(503, code: 'internal_error');
    }
    return stored.toList();
  }

  @override
  Future<TransactionsPage> transactions(String month, {String? cursor}) async =>
      const TransactionsPage([], null);

  @override
  Future<bool> hasTransactions() async {
    if (failHasTransactions) throw const HomeFailure(503, code: 'internal_error');
    return _confirmed || hasTransactionsAlready;
  }

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<Transaction> restore(String id) => throw UnimplementedError();

  @override
  Future<Transaction> markPaid(String id) => throw UnimplementedError();

  // -- The welcome's -----------------------------------------------------------------------------

  @override
  Future<List<Category>> allCategories() async => stored.toList();

  @override
  Future<Category> createCategory({
    required String name,
    required CategoryKindEnum kind,
    required String icon,
    required String color,
    int? sortOrder,
  }) async {
    _record(
      'POST /v1/categories ${_json({'name': name, 'kind': kind.name, 'icon': icon, 'color': color, 'sortOrder': ?sortOrder})}',
    );
    await holdWrites?.future;
    _categoryPosts += 1;
    // Like the API: names are unique among a person's active categories, ignoring case.
    bool taken(String other) => other.toLowerCase() == name.toLowerCase();
    if (stored.any((c) => !c.archived && taken(c.name)) || takenNames.any(taken)) {
      throw const HomeFailure(409, code: 'category_name_taken');
    }
    final created = _make('cat-${stored.length}', name, kind, icon, color, sortOrder ?? 0);
    final failing = failCategoryPost;
    if (failing != null && failing.nth == _categoryPosts) {
      if (failing.created) stored.add(created);
      throw const HomeFailure(503, code: 'internal_error');
    }
    stored.add(created);
    return created;
  }

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
    CategoryKindEnum? kind,
    bool? archived,
  }) async {
    _record(
      'PATCH /v1/categories/$id ${_json({'name': ?name, 'icon': ?icon, 'color': ?color, if (kind != null) 'kind': kind.name, 'archived': ?archived})}',
    );
    final at = stored.indexWhere((c) => c.id == id);
    final before = stored[at];
    // Like the API: the kind changes only without transactions.
    if (kind != null && kind != before.kind && (transactionsByName[before.name] ?? 0) > 0) {
      throw const HomeFailure(409, code: 'category_has_transactions');
    }
    stored[at] = before.rebuild(
      (b) => b
        ..name = name ?? b.name
        ..icon = icon ?? b.icon
        ..color = color ?? b.color
        ..kind = kind ?? b.kind
        ..archived = archived ?? b.archived,
    );
    return stored[at];
  }

  @override
  Future<TransactionsPage> categoryTransactions(String categoryId, {String? cursor}) async {
    if (failCount) throw const HomeFailure(503, code: 'internal_error');
    final name = stored.where((c) => c.id == categoryId).firstOrNull?.name ?? '';
    final count = (transactionsByName[name] ?? 0).clamp(0, 200);
    return TransactionsPage([for (var i = 0; i < count; i++) _tx('t-$i')], null);
  }

  Transaction _tx(String id) => Transaction(
    (b) => b
      ..id = id
      ..name = id
      ..amount = -100
      ..currency = currency
      ..date = '2026-10-01'
      ..status = TransactionStatusEnum.paid
      ..categoryId = 'cat-groceries'
      ..source_ = TransactionSource_Enum.app
      ..createdAt = '2026-10-01T10:00:00.000Z'
      ..updatedAt = '2026-10-01T10:00:00.000Z',
  );

  @override
  Future<void> setBudget(String categoryId, int cents, {required String month}) async {
    _record(
      'PUT /v1/categories/$categoryId/budget ${_json({'amount': cents, 'effectiveFrom': month})}',
    );
    if (_budgetFails) {
      _budgetFails = false;
      throw const HomeFailure(503, code: 'internal_error');
    }
    final at = stored.indexWhere((c) => c.id == categoryId);
    stored[at] = stored[at].rebuild((b) => b.currentBudget = cents);
  }

  @override
  Future<void> patchMe({String? currency, String? timezone, bool? onboardingCompleted}) async {
    _record(
      'PATCH /v1/me ${_json({'currency': ?currency, 'timezone': ?timezone, if (onboardingCompleted == true) 'onboardingCompleted': true})}',
    );
    if (currency != null) {
      if (_confirmed || hasTransactionsAlready) {
        throw const HomeFailure(409, code: 'currency_locked');
      }
      this.currency = currency;
    }
    if (timezone != null) this.timezone = timezone;
    if (onboardingCompleted == true) onboardingCompletedAt = '2026-10-21T10:00:00.000Z';
  }

  // -- The import's ------------------------------------------------------------------------------

  Map<String, Object?> get _window => oldExport
      ? const {'from': '2025-01', 'to': '2025-03', 'months': 3}
      : const {'from': '2026-07', 'to': '2026-09', 'months': 3};

  @override
  Future<FileImport> upload(String fileName, Uint8List bytes) async {
    _record('POST /v1/imports');
    _uploads += 1;
    // The file is in EUR. Like the API: an empty account in another currency would adopt it on
    // confirm, so the preview counts the rows; with transactions they are rejected.
    final empty = !_confirmed && !hasTransactionsAlready;
    final adopts = currency != 'EUR' && empty;
    final Map<String, Object?> stats = currency == 'EUR' || adopts
        ? {
            ...sampleStats(window: _window),
            'duplicates': 0,
            'adoptsCurrency': adopts,
            'dropsBudgets': adopts && stored.any((c) => c.currentBudget != null),
          }
        : {
            ...sampleStats(),
            'transactions': 0,
            'duplicates': 0,
            'newCategories': <String>[],
            'rejected': [
              {'line': 7, 'reason': 'currency_mismatch'},
            ],
            'from': null,
            'to': null,
            'averageMonthlySpending': <Object>[],
            'averageWindow': null,
          };
    return importOf(stats, id: 'preview-$_uploads');
  }

  @override
  Future<void> discard(String id) async => _record('DELETE /v1/imports/$id');

  @override
  Future<FileImport> confirm(String id, {bool adoptFileCurrency = false}) async {
    _record(
      'POST /v1/imports/$id/confirm${adoptFileCurrency ? ' ${_json({'adoptFileCurrency': true})}' : ''}',
    );
    await holdConfirm?.future;
    if (_confirmFails) {
      _confirmFails = false;
      throw const HomeFailure(503, code: 'internal_error');
    }
    if (currency != 'EUR') {
      // Like the API: a mismatch goes in only by adopting the file's currency, atomically, which
      // drops the budgets in the old one.
      if (!adoptFileCurrency) throw const HomeFailure(409, code: 'import_currency_changed');
      currency = 'EUR';
      for (var i = 0; i < stored.length; i++) {
        stored[i] = stored[i].rebuild((b) => b.currentBudget = null);
      }
    }
    _confirmed = true;
    // Like the importer: the file's categories that don't exist yet (by name, any case or accent)
    // are made, as the file writes them.
    for (final (name, kind, icon, color) in const [
      ('supermercado', CategoryKindEnum.expense, 'cart', 'orange'),
      ('Ocio', CategoryKindEnum.expense, 'star', 'orange'),
      ('Taxes', CategoryKindEnum.expense, 'document', 'yellow'),
      ('Salário', CategoryKindEnum.income, 'salary', 'orange'),
    ]) {
      if (stored.any((c) => normalizeName(c.name) == normalizeName(name))) {
        continue;
      }
      stored.add(_make('cat-${stored.length}', name, kind, icon, color, 0));
    }
    _refreshFailures = failRefreshesAfterConfirm;
    return importOf(
      {...sampleStats(window: _window), 'duplicates': 0, 'inserted': 22},
      id: id,
      status: 'confirmed',
    );
  }
}
