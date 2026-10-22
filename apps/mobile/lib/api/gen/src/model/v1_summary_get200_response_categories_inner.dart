//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_summary_get200_response_categories_inner.g.dart';

/// V1SummaryGet200ResponseCategoriesInner
///
/// Properties:
/// * [categoryId]
/// * [budget]
/// * [spent]
/// * [remaining]
/// * [ratio]
/// * [state]
@BuiltValue()
abstract class V1SummaryGet200ResponseCategoriesInner
    implements
        Built<
          V1SummaryGet200ResponseCategoriesInner,
          V1SummaryGet200ResponseCategoriesInnerBuilder
        > {
  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'budget')
  int? get budget;

  @BuiltValueField(wireName: r'spent')
  int get spent;

  @BuiltValueField(wireName: r'remaining')
  int? get remaining;

  @BuiltValueField(wireName: r'ratio')
  num? get ratio;

  @BuiltValueField(wireName: r'state')
  V1SummaryGet200ResponseCategoriesInnerStateEnum get state;
  // enum stateEnum {  ok,  near,  over,  };

  V1SummaryGet200ResponseCategoriesInner._();

  factory V1SummaryGet200ResponseCategoriesInner([
    void updates(V1SummaryGet200ResponseCategoriesInnerBuilder b),
  ]) = _$V1SummaryGet200ResponseCategoriesInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1SummaryGet200ResponseCategoriesInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1SummaryGet200ResponseCategoriesInner> get serializer =>
      _$V1SummaryGet200ResponseCategoriesInnerSerializer();
}

class _$V1SummaryGet200ResponseCategoriesInnerSerializer
    implements PrimitiveSerializer<V1SummaryGet200ResponseCategoriesInner> {
  @override
  final Iterable<Type> types = const [
    V1SummaryGet200ResponseCategoriesInner,
    _$V1SummaryGet200ResponseCategoriesInner,
  ];

  @override
  final String wireName = r'V1SummaryGet200ResponseCategoriesInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1SummaryGet200ResponseCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'budget';
    yield object.budget == null
        ? null
        : serializers.serialize(object.budget, specifiedType: const FullType.nullable(int));
    yield r'spent';
    yield serializers.serialize(object.spent, specifiedType: const FullType(int));
    yield r'remaining';
    yield object.remaining == null
        ? null
        : serializers.serialize(object.remaining, specifiedType: const FullType.nullable(int));
    yield r'ratio';
    yield object.ratio == null
        ? null
        : serializers.serialize(object.ratio, specifiedType: const FullType.nullable(num));
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(V1SummaryGet200ResponseCategoriesInnerStateEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1SummaryGet200ResponseCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1SummaryGet200ResponseCategoriesInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
        case r'budget':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.budget = valueDes;
          break;
        case r'spent':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.spent = valueDes;
          break;
        case r'remaining':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.remaining = valueDes;
          break;
        case r'ratio':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(num)) as num?;
          if (valueDes == null) continue;
          result.ratio = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1SummaryGet200ResponseCategoriesInnerStateEnum),
          ) as V1SummaryGet200ResponseCategoriesInnerStateEnum;
          result.state = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1SummaryGet200ResponseCategoriesInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1SummaryGet200ResponseCategoriesInnerBuilder();
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

class V1SummaryGet200ResponseCategoriesInnerStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ok')
  static const V1SummaryGet200ResponseCategoriesInnerStateEnum ok =
      _$v1SummaryGet200ResponseCategoriesInnerStateEnum_ok;
  @BuiltValueEnumConst(wireName: r'near')
  static const V1SummaryGet200ResponseCategoriesInnerStateEnum near =
      _$v1SummaryGet200ResponseCategoriesInnerStateEnum_near;
  @BuiltValueEnumConst(wireName: r'over')
  static const V1SummaryGet200ResponseCategoriesInnerStateEnum over =
      _$v1SummaryGet200ResponseCategoriesInnerStateEnum_over;

  static Serializer<V1SummaryGet200ResponseCategoriesInnerStateEnum> get serializer =>
      _$v1SummaryGet200ResponseCategoriesInnerStateEnumSerializer;

  const V1SummaryGet200ResponseCategoriesInnerStateEnum._(String name) : super(name);

  static BuiltSet<V1SummaryGet200ResponseCategoriesInnerStateEnum> get values =>
      _$v1SummaryGet200ResponseCategoriesInnerStateEnumValues;
  static V1SummaryGet200ResponseCategoriesInnerStateEnum valueOf(String name) =>
      _$v1SummaryGet200ResponseCategoriesInnerStateEnumValueOf(name);
}
