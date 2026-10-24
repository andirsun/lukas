// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_import.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConfirmImport extends ConfirmImport {
  @override
  final bool? adoptFileCurrency;

  factory _$ConfirmImport([void Function(ConfirmImportBuilder)? updates]) =>
      (ConfirmImportBuilder()..update(updates))._build();

  _$ConfirmImport._({this.adoptFileCurrency}) : super._();
  @override
  ConfirmImport rebuild(void Function(ConfirmImportBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfirmImportBuilder toBuilder() => ConfirmImportBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConfirmImport && adoptFileCurrency == other.adoptFileCurrency;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adoptFileCurrency.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ConfirmImport',
    )..add('adoptFileCurrency', adoptFileCurrency)).toString();
  }
}

class ConfirmImportBuilder implements Builder<ConfirmImport, ConfirmImportBuilder> {
  _$ConfirmImport? _$v;

  bool? _adoptFileCurrency;
  bool? get adoptFileCurrency => _$this._adoptFileCurrency;
  set adoptFileCurrency(bool? adoptFileCurrency) => _$this._adoptFileCurrency = adoptFileCurrency;

  ConfirmImportBuilder() {
    ConfirmImport._defaults(this);
  }

  ConfirmImportBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adoptFileCurrency = $v.adoptFileCurrency;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConfirmImport other) {
    _$v = other as _$ConfirmImport;
  }

  @override
  void update(void Function(ConfirmImportBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConfirmImport build() => _build();

  _$ConfirmImport _build() {
    final _$result = _$v ?? _$ConfirmImport._(adoptFileCurrency: adoptFileCurrency);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
