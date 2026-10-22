//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/transaction_suggestion.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transaction_suggestions.g.dart';

/// TransactionSuggestions
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class TransactionSuggestions
    implements Built<TransactionSuggestions, TransactionSuggestionsBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<TransactionSuggestion> get items;

  TransactionSuggestions._();

  factory TransactionSuggestions([void updates(TransactionSuggestionsBuilder b)]) =
      _$TransactionSuggestions;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransactionSuggestionsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransactionSuggestions> get serializer => _$TransactionSuggestionsSerializer();
}

class _$TransactionSuggestionsSerializer implements PrimitiveSerializer<TransactionSuggestions> {
  @override
  final Iterable<Type> types = const [TransactionSuggestions, _$TransactionSuggestions];

  @override
  final String wireName = r'TransactionSuggestions';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransactionSuggestions object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(TransactionSuggestion)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TransactionSuggestions object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TransactionSuggestionsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TransactionSuggestion)]),
          ) as BuiltList<TransactionSuggestion>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TransactionSuggestions deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransactionSuggestionsBuilder();
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
