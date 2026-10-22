//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transaction_suggestion.g.dart';

/// TransactionSuggestion
///
/// Properties:
/// * [name]
/// * [categoryId]
@BuiltValue()
abstract class TransactionSuggestion
    implements Built<TransactionSuggestion, TransactionSuggestionBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  TransactionSuggestion._();

  factory TransactionSuggestion([void updates(TransactionSuggestionBuilder b)]) =
      _$TransactionSuggestion;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransactionSuggestionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransactionSuggestion> get serializer => _$TransactionSuggestionSerializer();
}

class _$TransactionSuggestionSerializer implements PrimitiveSerializer<TransactionSuggestion> {
  @override
  final Iterable<Type> types = const [TransactionSuggestion, _$TransactionSuggestion];

  @override
  final String wireName = r'TransactionSuggestion';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransactionSuggestion object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    TransactionSuggestion object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TransactionSuggestionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.name = valueDes;
          break;
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TransactionSuggestion deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransactionSuggestionBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
