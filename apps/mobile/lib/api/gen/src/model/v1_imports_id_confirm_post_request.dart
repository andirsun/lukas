//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_imports_id_confirm_post_request.g.dart';

/// V1ImportsIdConfirmPostRequest
///
/// Properties:
/// * [adoptFileCurrency]
@BuiltValue()
abstract class V1ImportsIdConfirmPostRequest
    implements Built<V1ImportsIdConfirmPostRequest, V1ImportsIdConfirmPostRequestBuilder> {
  @BuiltValueField(wireName: r'adoptFileCurrency')
  bool? get adoptFileCurrency;

  V1ImportsIdConfirmPostRequest._();

  factory V1ImportsIdConfirmPostRequest([void updates(V1ImportsIdConfirmPostRequestBuilder b)]) =
      _$V1ImportsIdConfirmPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ImportsIdConfirmPostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ImportsIdConfirmPostRequest> get serializer =>
      _$V1ImportsIdConfirmPostRequestSerializer();
}

class _$V1ImportsIdConfirmPostRequestSerializer
    implements PrimitiveSerializer<V1ImportsIdConfirmPostRequest> {
  @override
  final Iterable<Type> types = const [
    V1ImportsIdConfirmPostRequest,
    _$V1ImportsIdConfirmPostRequest,
  ];

  @override
  final String wireName = r'V1ImportsIdConfirmPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ImportsIdConfirmPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.adoptFileCurrency != null) {
      yield r'adoptFileCurrency';
      yield serializers.serialize(object.adoptFileCurrency, specifiedType: const FullType(bool));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ImportsIdConfirmPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ImportsIdConfirmPostRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'adoptFileCurrency':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(bool)) as bool?;
          if (valueDes == null) continue;
          result.adoptFileCurrency = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ImportsIdConfirmPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ImportsIdConfirmPostRequestBuilder();
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
