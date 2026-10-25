//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_budget.g.dart';

/// SetBudget
///
/// Properties:
/// * [amount]
/// * [effectiveFrom]
@BuiltValue()
abstract class SetBudget implements Built<SetBudget, SetBudgetBuilder> {
  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'effectiveFrom')
  String get effectiveFrom;

  SetBudget._();

  factory SetBudget([void updates(SetBudgetBuilder b)]) = _$SetBudget;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetBudgetBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetBudget> get serializer => _$SetBudgetSerializer();
}

class _$SetBudgetSerializer implements PrimitiveSerializer<SetBudget> {
  @override
  final Iterable<Type> types = const [SetBudget, _$SetBudget];

  @override
  final String wireName = r'SetBudget';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetBudget object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    yield r'effectiveFrom';
    yield serializers.serialize(object.effectiveFrom, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    SetBudget object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetBudgetBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amount':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.amount = valueDes;
          break;
        case r'effectiveFrom':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.effectiveFrom = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SetBudget deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetBudgetBuilder();
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
