// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Assistant extends Assistant {
  @override
  final String clientId;
  @override
  final String name;
  @override
  final String? icon;
  @override
  final String? uri;
  @override
  final String? domain;
  @override
  final BuiltList<String> scopes;
  @override
  final String connectedAt;
  @override
  final String? lastUsedAt;

  factory _$Assistant([void Function(AssistantBuilder)? updates]) =>
      (AssistantBuilder()..update(updates))._build();

  _$Assistant._({
    required this.clientId,
    required this.name,
    this.icon,
    this.uri,
    this.domain,
    required this.scopes,
    required this.connectedAt,
    this.lastUsedAt,
  }) : super._();
  @override
  Assistant rebuild(void Function(AssistantBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssistantBuilder toBuilder() => AssistantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Assistant &&
        clientId == other.clientId &&
        name == other.name &&
        icon == other.icon &&
        uri == other.uri &&
        domain == other.domain &&
        scopes == other.scopes &&
        connectedAt == other.connectedAt &&
        lastUsedAt == other.lastUsedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, clientId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jc(_$hash, uri.hashCode);
    _$hash = $jc(_$hash, domain.hashCode);
    _$hash = $jc(_$hash, scopes.hashCode);
    _$hash = $jc(_$hash, connectedAt.hashCode);
    _$hash = $jc(_$hash, lastUsedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Assistant')
          ..add('clientId', clientId)
          ..add('name', name)
          ..add('icon', icon)
          ..add('uri', uri)
          ..add('domain', domain)
          ..add('scopes', scopes)
          ..add('connectedAt', connectedAt)
          ..add('lastUsedAt', lastUsedAt))
        .toString();
  }
}

class AssistantBuilder implements Builder<Assistant, AssistantBuilder> {
  _$Assistant? _$v;

  String? _clientId;
  String? get clientId => _$this._clientId;
  set clientId(String? clientId) => _$this._clientId = clientId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _icon;
  String? get icon => _$this._icon;
  set icon(String? icon) => _$this._icon = icon;

  String? _uri;
  String? get uri => _$this._uri;
  set uri(String? uri) => _$this._uri = uri;

  String? _domain;
  String? get domain => _$this._domain;
  set domain(String? domain) => _$this._domain = domain;

  ListBuilder<String>? _scopes;
  ListBuilder<String> get scopes => _$this._scopes ??= ListBuilder<String>();
  set scopes(ListBuilder<String>? scopes) => _$this._scopes = scopes;

  String? _connectedAt;
  String? get connectedAt => _$this._connectedAt;
  set connectedAt(String? connectedAt) => _$this._connectedAt = connectedAt;

  String? _lastUsedAt;
  String? get lastUsedAt => _$this._lastUsedAt;
  set lastUsedAt(String? lastUsedAt) => _$this._lastUsedAt = lastUsedAt;

  AssistantBuilder() {
    Assistant._defaults(this);
  }

  AssistantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _clientId = $v.clientId;
      _name = $v.name;
      _icon = $v.icon;
      _uri = $v.uri;
      _domain = $v.domain;
      _scopes = $v.scopes.toBuilder();
      _connectedAt = $v.connectedAt;
      _lastUsedAt = $v.lastUsedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Assistant other) {
    _$v = other as _$Assistant;
  }

  @override
  void update(void Function(AssistantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Assistant build() => _build();

  _$Assistant _build() {
    _$Assistant _$result;
    try {
      _$result =
          _$v ??
          _$Assistant._(
            clientId: BuiltValueNullFieldError.checkNotNull(clientId, r'Assistant', 'clientId'),
            name: BuiltValueNullFieldError.checkNotNull(name, r'Assistant', 'name'),
            icon: icon,
            uri: uri,
            domain: domain,
            scopes: scopes.build(),
            connectedAt: BuiltValueNullFieldError.checkNotNull(
              connectedAt,
              r'Assistant',
              'connectedAt',
            ),
            lastUsedAt: lastUsedAt,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'scopes';
        scopes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Assistant', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
