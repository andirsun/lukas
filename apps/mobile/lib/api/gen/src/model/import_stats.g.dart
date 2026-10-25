// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ImportStats extends ImportStats {
  @override
  final int transactions;
  @override
  final int duplicates;
  @override
  final BuiltList<String> newCategories;
  @override
  final BuiltList<ImportStatsRejectedInner> rejected;
  @override
  final String? from;
  @override
  final String? to;
  @override
  final BuiltList<ImportStatsAverageMonthlySpendingInner> averageMonthlySpending;
  @override
  final String? currency;
  @override
  final ImportStatsAverageWindow? averageWindow;
  @override
  final bool adoptsCurrency;
  @override
  final bool dropsBudgets;
  @override
  final int? inserted;

  factory _$ImportStats([void Function(ImportStatsBuilder)? updates]) =>
      (ImportStatsBuilder()..update(updates))._build();

  _$ImportStats._({
    required this.transactions,
    required this.duplicates,
    required this.newCategories,
    required this.rejected,
    this.from,
    this.to,
    required this.averageMonthlySpending,
    this.currency,
    this.averageWindow,
    required this.adoptsCurrency,
    required this.dropsBudgets,
    this.inserted,
  }) : super._();
  @override
  ImportStats rebuild(void Function(ImportStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ImportStatsBuilder toBuilder() => ImportStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportStats &&
        transactions == other.transactions &&
        duplicates == other.duplicates &&
        newCategories == other.newCategories &&
        rejected == other.rejected &&
        from == other.from &&
        to == other.to &&
        averageMonthlySpending == other.averageMonthlySpending &&
        currency == other.currency &&
        averageWindow == other.averageWindow &&
        adoptsCurrency == other.adoptsCurrency &&
        dropsBudgets == other.dropsBudgets &&
        inserted == other.inserted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, transactions.hashCode);
    _$hash = $jc(_$hash, duplicates.hashCode);
    _$hash = $jc(_$hash, newCategories.hashCode);
    _$hash = $jc(_$hash, rejected.hashCode);
    _$hash = $jc(_$hash, from.hashCode);
    _$hash = $jc(_$hash, to.hashCode);
    _$hash = $jc(_$hash, averageMonthlySpending.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, averageWindow.hashCode);
    _$hash = $jc(_$hash, adoptsCurrency.hashCode);
    _$hash = $jc(_$hash, dropsBudgets.hashCode);
    _$hash = $jc(_$hash, inserted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportStats')
          ..add('transactions', transactions)
          ..add('duplicates', duplicates)
          ..add('newCategories', newCategories)
          ..add('rejected', rejected)
          ..add('from', from)
          ..add('to', to)
          ..add('averageMonthlySpending', averageMonthlySpending)
          ..add('currency', currency)
          ..add('averageWindow', averageWindow)
          ..add('adoptsCurrency', adoptsCurrency)
          ..add('dropsBudgets', dropsBudgets)
          ..add('inserted', inserted))
        .toString();
  }
}

class ImportStatsBuilder implements Builder<ImportStats, ImportStatsBuilder> {
  _$ImportStats? _$v;

  int? _transactions;
  int? get transactions => _$this._transactions;
  set transactions(int? transactions) => _$this._transactions = transactions;

  int? _duplicates;
  int? get duplicates => _$this._duplicates;
  set duplicates(int? duplicates) => _$this._duplicates = duplicates;

  ListBuilder<String>? _newCategories;
  ListBuilder<String> get newCategories => _$this._newCategories ??= ListBuilder<String>();
  set newCategories(ListBuilder<String>? newCategories) => _$this._newCategories = newCategories;

  ListBuilder<ImportStatsRejectedInner>? _rejected;
  ListBuilder<ImportStatsRejectedInner> get rejected =>
      _$this._rejected ??= ListBuilder<ImportStatsRejectedInner>();
  set rejected(ListBuilder<ImportStatsRejectedInner>? rejected) => _$this._rejected = rejected;

  String? _from;
  String? get from => _$this._from;
  set from(String? from) => _$this._from = from;

  String? _to;
  String? get to => _$this._to;
  set to(String? to) => _$this._to = to;

  ListBuilder<ImportStatsAverageMonthlySpendingInner>? _averageMonthlySpending;
  ListBuilder<ImportStatsAverageMonthlySpendingInner> get averageMonthlySpending =>
      _$this._averageMonthlySpending ??= ListBuilder<ImportStatsAverageMonthlySpendingInner>();
  set averageMonthlySpending(
    ListBuilder<ImportStatsAverageMonthlySpendingInner>? averageMonthlySpending,
  ) => _$this._averageMonthlySpending = averageMonthlySpending;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  ImportStatsAverageWindowBuilder? _averageWindow;
  ImportStatsAverageWindowBuilder get averageWindow =>
      _$this._averageWindow ??= ImportStatsAverageWindowBuilder();
  set averageWindow(ImportStatsAverageWindowBuilder? averageWindow) =>
      _$this._averageWindow = averageWindow;

  bool? _adoptsCurrency;
  bool? get adoptsCurrency => _$this._adoptsCurrency;
  set adoptsCurrency(bool? adoptsCurrency) => _$this._adoptsCurrency = adoptsCurrency;

  bool? _dropsBudgets;
  bool? get dropsBudgets => _$this._dropsBudgets;
  set dropsBudgets(bool? dropsBudgets) => _$this._dropsBudgets = dropsBudgets;

  int? _inserted;
  int? get inserted => _$this._inserted;
  set inserted(int? inserted) => _$this._inserted = inserted;

  ImportStatsBuilder() {
    ImportStats._defaults(this);
  }

  ImportStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _transactions = $v.transactions;
      _duplicates = $v.duplicates;
      _newCategories = $v.newCategories.toBuilder();
      _rejected = $v.rejected.toBuilder();
      _from = $v.from;
      _to = $v.to;
      _averageMonthlySpending = $v.averageMonthlySpending.toBuilder();
      _currency = $v.currency;
      _averageWindow = $v.averageWindow?.toBuilder();
      _adoptsCurrency = $v.adoptsCurrency;
      _dropsBudgets = $v.dropsBudgets;
      _inserted = $v.inserted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportStats other) {
    _$v = other as _$ImportStats;
  }

  @override
  void update(void Function(ImportStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportStats build() => _build();

  _$ImportStats _build() {
    _$ImportStats _$result;
    try {
      _$result =
          _$v ??
          _$ImportStats._(
            transactions: BuiltValueNullFieldError.checkNotNull(
              transactions,
              r'ImportStats',
              'transactions',
            ),
            duplicates: BuiltValueNullFieldError.checkNotNull(
              duplicates,
              r'ImportStats',
              'duplicates',
            ),
            newCategories: newCategories.build(),
            rejected: rejected.build(),
            from: from,
            to: to,
            averageMonthlySpending: averageMonthlySpending.build(),
            currency: currency,
            averageWindow: _averageWindow?.build(),
            adoptsCurrency: BuiltValueNullFieldError.checkNotNull(
              adoptsCurrency,
              r'ImportStats',
              'adoptsCurrency',
            ),
            dropsBudgets: BuiltValueNullFieldError.checkNotNull(
              dropsBudgets,
              r'ImportStats',
              'dropsBudgets',
            ),
            inserted: inserted,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'newCategories';
        newCategories.build();
        _$failedField = 'rejected';
        rejected.build();

        _$failedField = 'averageMonthlySpending';
        averageMonthlySpending.build();

        _$failedField = 'averageWindow';
        _averageWindow?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'ImportStats', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
