//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_transaction_repeat.g.dart';

/// CreateTransactionRepeat
///
/// Properties:
/// * [frequency]
/// * [endDate]
@BuiltValue()
abstract class CreateTransactionRepeat
    implements Built<CreateTransactionRepeat, CreateTransactionRepeatBuilder> {
  @BuiltValueField(wireName: r'frequency')
  CreateTransactionRepeatFrequencyEnum get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  CreateTransactionRepeat._();

  factory CreateTransactionRepeat([void updates(CreateTransactionRepeatBuilder b)]) =
      _$CreateTransactionRepeat;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTransactionRepeatBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTransactionRepeat> get serializer =>
      _$CreateTransactionRepeatSerializer();
}

class _$CreateTransactionRepeatSerializer implements PrimitiveSerializer<CreateTransactionRepeat> {
  @override
  final Iterable<Type> types = const [CreateTransactionRepeat, _$CreateTransactionRepeat];

  @override
  final String wireName = r'CreateTransactionRepeat';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTransactionRepeat object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'frequency';
    yield serializers.serialize(
      object.frequency,
      specifiedType: const FullType(CreateTransactionRepeatFrequencyEnum),
    );
    if (object.endDate != null) {
      yield r'endDate';
      yield serializers.serialize(object.endDate, specifiedType: const FullType.nullable(String));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionRepeat object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTransactionRepeatBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'frequency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreateTransactionRepeatFrequencyEnum),
          ) as CreateTransactionRepeatFrequencyEnum;
          result.frequency = valueDes;
          break;
        case r'endDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.endDate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTransactionRepeat deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTransactionRepeatBuilder();
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

class CreateTransactionRepeatFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const CreateTransactionRepeatFrequencyEnum monthly =
      _$createTransactionRepeatFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const CreateTransactionRepeatFrequencyEnum yearly =
      _$createTransactionRepeatFrequencyEnum_yearly;

  static Serializer<CreateTransactionRepeatFrequencyEnum> get serializer =>
      _$createTransactionRepeatFrequencyEnumSerializer;

  const CreateTransactionRepeatFrequencyEnum._(String name) : super(name);

  static BuiltSet<CreateTransactionRepeatFrequencyEnum> get values =>
      _$createTransactionRepeatFrequencyEnumValues;
  static CreateTransactionRepeatFrequencyEnum valueOf(String name) =>
      _$createTransactionRepeatFrequencyEnumValueOf(name);
}
