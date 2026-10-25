//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/cost_of_living_report_categories_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cost_of_living_report.g.dart';

/// CostOfLivingReport
///
/// Properties:
/// * [months]
/// * [total]
/// * [fixed]
/// * [variable]
/// * [categories]
@BuiltValue()
abstract class CostOfLivingReport implements Built<CostOfLivingReport, CostOfLivingReportBuilder> {
  @BuiltValueField(wireName: r'months')
  int get months;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'fixed')
  int get fixed;

  @BuiltValueField(wireName: r'variable')
  int get variable;

  @BuiltValueField(wireName: r'categories')
  BuiltList<CostOfLivingReportCategoriesInner> get categories;

  CostOfLivingReport._();

  factory CostOfLivingReport([void updates(CostOfLivingReportBuilder b)]) = _$CostOfLivingReport;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CostOfLivingReportBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CostOfLivingReport> get serializer => _$CostOfLivingReportSerializer();
}

class _$CostOfLivingReportSerializer implements PrimitiveSerializer<CostOfLivingReport> {
  @override
  final Iterable<Type> types = const [CostOfLivingReport, _$CostOfLivingReport];

  @override
  final String wireName = r'CostOfLivingReport';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CostOfLivingReport object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'months';
    yield serializers.serialize(object.months, specifiedType: const FullType(int));
    yield r'total';
    yield serializers.serialize(object.total, specifiedType: const FullType(int));
    yield r'fixed';
    yield serializers.serialize(object.fixed, specifiedType: const FullType(int));
    yield r'variable';
    yield serializers.serialize(object.variable, specifiedType: const FullType(int));
    yield r'categories';
    yield serializers.serialize(
      object.categories,
      specifiedType: const FullType(BuiltList, [FullType(CostOfLivingReportCategoriesInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CostOfLivingReport object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CostOfLivingReportBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'months':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.months = valueDes;
          break;
        case r'total':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.total = valueDes;
          break;
        case r'fixed':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.fixed = valueDes;
          break;
        case r'variable':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.variable = valueDes;
          break;
        case r'categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CostOfLivingReportCategoriesInner)]),
          ) as BuiltList<CostOfLivingReportCategoriesInner>;
          result.categories.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CostOfLivingReport deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CostOfLivingReportBuilder();
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
