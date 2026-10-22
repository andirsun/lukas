//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_by_category_get200_response_items_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_reports_by_category_get200_response.g.dart';

/// V1ReportsByCategoryGet200Response
///
/// Properties:
/// * [total]
/// * [items]
@BuiltValue()
abstract class V1ReportsByCategoryGet200Response
    implements Built<V1ReportsByCategoryGet200Response, V1ReportsByCategoryGet200ResponseBuilder> {
  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'items')
  BuiltList<V1ReportsByCategoryGet200ResponseItemsInner> get items;

  V1ReportsByCategoryGet200Response._();

  factory V1ReportsByCategoryGet200Response([
    void updates(V1ReportsByCategoryGet200ResponseBuilder b),
  ]) = _$V1ReportsByCategoryGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ReportsByCategoryGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ReportsByCategoryGet200Response> get serializer =>
      _$V1ReportsByCategoryGet200ResponseSerializer();
}

class _$V1ReportsByCategoryGet200ResponseSerializer
    implements PrimitiveSerializer<V1ReportsByCategoryGet200Response> {
  @override
  final Iterable<Type> types = const [
    V1ReportsByCategoryGet200Response,
    _$V1ReportsByCategoryGet200Response,
  ];

  @override
  final String wireName = r'V1ReportsByCategoryGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ReportsByCategoryGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total';
    yield serializers.serialize(object.total, specifiedType: const FullType(int));
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [
        FullType(V1ReportsByCategoryGet200ResponseItemsInner),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ReportsByCategoryGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ReportsByCategoryGet200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.total = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(V1ReportsByCategoryGet200ResponseItemsInner),
            ]),
          ) as BuiltList<V1ReportsByCategoryGet200ResponseItemsInner>;
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
  V1ReportsByCategoryGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ReportsByCategoryGet200ResponseBuilder();
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
