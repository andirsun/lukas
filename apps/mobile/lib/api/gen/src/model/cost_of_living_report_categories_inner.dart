//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cost_of_living_report_categories_inner.g.dart';

/// CostOfLivingReportCategoriesInner
///
/// Properties:
/// * [categoryId]
/// * [average]
/// * [type]
@BuiltValue()
abstract class CostOfLivingReportCategoriesInner
    implements Built<CostOfLivingReportCategoriesInner, CostOfLivingReportCategoriesInnerBuilder> {
  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'average')
  int get average;

  @BuiltValueField(wireName: r'type')
  CostOfLivingReportCategoriesInnerTypeEnum get type;
  // enum typeEnum {  fixed,  variable,  };

  CostOfLivingReportCategoriesInner._();

  factory CostOfLivingReportCategoriesInner([
    void updates(CostOfLivingReportCategoriesInnerBuilder b),
  ]) = _$CostOfLivingReportCategoriesInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CostOfLivingReportCategoriesInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CostOfLivingReportCategoriesInner> get serializer =>
      _$CostOfLivingReportCategoriesInnerSerializer();
}

class _$CostOfLivingReportCategoriesInnerSerializer
    implements PrimitiveSerializer<CostOfLivingReportCategoriesInner> {
  @override
  final Iterable<Type> types = const [
    CostOfLivingReportCategoriesInner,
    _$CostOfLivingReportCategoriesInner,
  ];

  @override
  final String wireName = r'CostOfLivingReportCategoriesInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CostOfLivingReportCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'average';
    yield serializers.serialize(object.average, specifiedType: const FullType(int));
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(CostOfLivingReportCategoriesInnerTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CostOfLivingReportCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CostOfLivingReportCategoriesInnerBuilder result,
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
            specifiedType: const FullType(CostOfLivingReportCategoriesInnerTypeEnum),
          ) as CostOfLivingReportCategoriesInnerTypeEnum;
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
  CostOfLivingReportCategoriesInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CostOfLivingReportCategoriesInnerBuilder();
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

class CostOfLivingReportCategoriesInnerTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'fixed')
  static const CostOfLivingReportCategoriesInnerTypeEnum fixed =
      _$costOfLivingReportCategoriesInnerTypeEnum_fixed;
  @BuiltValueEnumConst(wireName: r'variable')
  static const CostOfLivingReportCategoriesInnerTypeEnum variable =
      _$costOfLivingReportCategoriesInnerTypeEnum_variable;

  static Serializer<CostOfLivingReportCategoriesInnerTypeEnum> get serializer =>
      _$costOfLivingReportCategoriesInnerTypeEnumSerializer;

  const CostOfLivingReportCategoriesInnerTypeEnum._(String name) : super(name);

  static BuiltSet<CostOfLivingReportCategoriesInnerTypeEnum> get values =>
      _$costOfLivingReportCategoriesInnerTypeEnumValues;
  static CostOfLivingReportCategoriesInnerTypeEnum valueOf(String name) =>
      _$costOfLivingReportCategoriesInnerTypeEnumValueOf(name);
}
