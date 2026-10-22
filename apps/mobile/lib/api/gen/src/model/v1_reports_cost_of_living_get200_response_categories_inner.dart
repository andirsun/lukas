//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_reports_cost_of_living_get200_response_categories_inner.g.dart';

/// V1ReportsCostOfLivingGet200ResponseCategoriesInner
///
/// Properties:
/// * [categoryId]
/// * [average]
/// * [type]
@BuiltValue()
abstract class V1ReportsCostOfLivingGet200ResponseCategoriesInner
    implements
        Built<
          V1ReportsCostOfLivingGet200ResponseCategoriesInner,
          V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder
        > {
  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'average')
  int get average;

  @BuiltValueField(wireName: r'type')
  V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum get type;
  // enum typeEnum {  fixed,  variable,  };

  V1ReportsCostOfLivingGet200ResponseCategoriesInner._();

  factory V1ReportsCostOfLivingGet200ResponseCategoriesInner([
    void updates(V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder b),
  ]) = _$V1ReportsCostOfLivingGet200ResponseCategoriesInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ReportsCostOfLivingGet200ResponseCategoriesInner> get serializer =>
      _$V1ReportsCostOfLivingGet200ResponseCategoriesInnerSerializer();
}

class _$V1ReportsCostOfLivingGet200ResponseCategoriesInnerSerializer
    implements PrimitiveSerializer<V1ReportsCostOfLivingGet200ResponseCategoriesInner> {
  @override
  final Iterable<Type> types = const [
    V1ReportsCostOfLivingGet200ResponseCategoriesInner,
    _$V1ReportsCostOfLivingGet200ResponseCategoriesInner,
  ];

  @override
  final String wireName = r'V1ReportsCostOfLivingGet200ResponseCategoriesInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ReportsCostOfLivingGet200ResponseCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'average';
    yield serializers.serialize(object.average, specifiedType: const FullType(int));
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ReportsCostOfLivingGet200ResponseCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder result,
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
        case r'average':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.average = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum,
            ),
          ) as V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ReportsCostOfLivingGet200ResponseCategoriesInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder();
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

class V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'fixed')
  static const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum fixed =
      _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_fixed;
  @BuiltValueEnumConst(wireName: r'variable')
  static const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum variable =
      _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_variable;

  static Serializer<V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum> get serializer =>
      _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumSerializer;

  const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum._(String name) : super(name);

  static BuiltSet<V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum> get values =>
      _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumValues;
  static V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum valueOf(String name) =>
      _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumValueOf(name);
}
