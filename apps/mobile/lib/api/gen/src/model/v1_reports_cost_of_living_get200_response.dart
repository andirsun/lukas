//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_cost_of_living_get200_response_categories_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_reports_cost_of_living_get200_response.g.dart';

/// V1ReportsCostOfLivingGet200Response
///
/// Properties:
/// * [months]
/// * [total]
/// * [fixed]
/// * [variable]
/// * [categories]
@BuiltValue()
abstract class V1ReportsCostOfLivingGet200Response
    implements
        Built<V1ReportsCostOfLivingGet200Response, V1ReportsCostOfLivingGet200ResponseBuilder> {
  @BuiltValueField(wireName: r'months')
  int get months;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'fixed')
  int get fixed;

  @BuiltValueField(wireName: r'variable')
  int get variable;

  @BuiltValueField(wireName: r'categories')
  BuiltList<V1ReportsCostOfLivingGet200ResponseCategoriesInner> get categories;

  V1ReportsCostOfLivingGet200Response._();

  factory V1ReportsCostOfLivingGet200Response([
    void updates(V1ReportsCostOfLivingGet200ResponseBuilder b),
  ]) = _$V1ReportsCostOfLivingGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ReportsCostOfLivingGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ReportsCostOfLivingGet200Response> get serializer =>
      _$V1ReportsCostOfLivingGet200ResponseSerializer();
}

class _$V1ReportsCostOfLivingGet200ResponseSerializer
    implements PrimitiveSerializer<V1ReportsCostOfLivingGet200Response> {
  @override
  final Iterable<Type> types = const [
    V1ReportsCostOfLivingGet200Response,
    _$V1ReportsCostOfLivingGet200Response,
  ];

  @override
  final String wireName = r'V1ReportsCostOfLivingGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ReportsCostOfLivingGet200Response object, {
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
      specifiedType: const FullType(BuiltList, [
        FullType(V1ReportsCostOfLivingGet200ResponseCategoriesInner),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ReportsCostOfLivingGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ReportsCostOfLivingGet200ResponseBuilder result,
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
            specifiedType: const FullType(BuiltList, [
              FullType(V1ReportsCostOfLivingGet200ResponseCategoriesInner),
            ]),
          ) as BuiltList<V1ReportsCostOfLivingGet200ResponseCategoriesInner>;
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
  V1ReportsCostOfLivingGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ReportsCostOfLivingGet200ResponseBuilder();
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
