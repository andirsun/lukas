//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_trend_get200_response_months_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_reports_trend_get200_response.g.dart';

/// V1ReportsTrendGet200Response
///
/// Properties:
/// * [months]
@BuiltValue()
abstract class V1ReportsTrendGet200Response
    implements Built<V1ReportsTrendGet200Response, V1ReportsTrendGet200ResponseBuilder> {
  @BuiltValueField(wireName: r'months')
  BuiltList<V1ReportsTrendGet200ResponseMonthsInner> get months;

  V1ReportsTrendGet200Response._();

  factory V1ReportsTrendGet200Response([void updates(V1ReportsTrendGet200ResponseBuilder b)]) =
      _$V1ReportsTrendGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ReportsTrendGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ReportsTrendGet200Response> get serializer =>
      _$V1ReportsTrendGet200ResponseSerializer();
}

class _$V1ReportsTrendGet200ResponseSerializer
    implements PrimitiveSerializer<V1ReportsTrendGet200Response> {
  @override
  final Iterable<Type> types = const [V1ReportsTrendGet200Response, _$V1ReportsTrendGet200Response];

  @override
  final String wireName = r'V1ReportsTrendGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ReportsTrendGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'months';
    yield serializers.serialize(
      object.months,
      specifiedType: const FullType(BuiltList, [FullType(V1ReportsTrendGet200ResponseMonthsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ReportsTrendGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ReportsTrendGet200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'months':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(V1ReportsTrendGet200ResponseMonthsInner),
            ]),
          ) as BuiltList<V1ReportsTrendGet200ResponseMonthsInner>;
          result.months.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ReportsTrendGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ReportsTrendGet200ResponseBuilder();
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
