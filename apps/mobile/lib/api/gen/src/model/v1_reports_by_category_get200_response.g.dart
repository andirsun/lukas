// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_reports_by_category_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ReportsByCategoryGet200Response extends V1ReportsByCategoryGet200Response {
  @override
  final int total;
  @override
  final BuiltList<V1ReportsByCategoryGet200ResponseItemsInner> items;

  factory _$V1ReportsByCategoryGet200Response([
    void Function(V1ReportsByCategoryGet200ResponseBuilder)? updates,
  ]) => (V1ReportsByCategoryGet200ResponseBuilder()..update(updates))._build();

  _$V1ReportsByCategoryGet200Response._({required this.total, required this.items}) : super._();
  @override
  V1ReportsByCategoryGet200Response rebuild(
    void Function(V1ReportsByCategoryGet200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ReportsByCategoryGet200ResponseBuilder toBuilder() =>
      V1ReportsByCategoryGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ReportsByCategoryGet200Response &&
        total == other.total &&
        items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1ReportsByCategoryGet200Response')
          ..add('total', total)
          ..add('items', items))
        .toString();
  }
}

class V1ReportsByCategoryGet200ResponseBuilder
    implements
        Builder<V1ReportsByCategoryGet200Response, V1ReportsByCategoryGet200ResponseBuilder> {
  _$V1ReportsByCategoryGet200Response? _$v;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  ListBuilder<V1ReportsByCategoryGet200ResponseItemsInner>? _items;
  ListBuilder<V1ReportsByCategoryGet200ResponseItemsInner> get items =>
      _$this._items ??= ListBuilder<V1ReportsByCategoryGet200ResponseItemsInner>();
  set items(ListBuilder<V1ReportsByCategoryGet200ResponseItemsInner>? items) =>
      _$this._items = items;

  V1ReportsByCategoryGet200ResponseBuilder() {
    V1ReportsByCategoryGet200Response._defaults(this);
  }

  V1ReportsByCategoryGet200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ReportsByCategoryGet200Response other) {
    _$v = other as _$V1ReportsByCategoryGet200Response;
  }

  @override
  void update(void Function(V1ReportsByCategoryGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ReportsByCategoryGet200Response build() => _build();

  _$V1ReportsByCategoryGet200Response _build() {
    _$V1ReportsByCategoryGet200Response _$result;
    try {
      _$result =
          _$v ??
          _$V1ReportsByCategoryGet200Response._(
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'V1ReportsByCategoryGet200Response',
              'total',
            ),
            items: items.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1ReportsByCategoryGet200Response',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
