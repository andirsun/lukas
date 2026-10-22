//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_me_claim_email_verify_post_request.g.dart';

/// V1MeClaimEmailVerifyPostRequest
///
/// Properties:
/// * [email]
/// * [code]
@BuiltValue()
abstract class V1MeClaimEmailVerifyPostRequest
    implements Built<V1MeClaimEmailVerifyPostRequest, V1MeClaimEmailVerifyPostRequestBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'code')
  String get code;

  V1MeClaimEmailVerifyPostRequest._();

  factory V1MeClaimEmailVerifyPostRequest([
    void updates(V1MeClaimEmailVerifyPostRequestBuilder b),
  ]) = _$V1MeClaimEmailVerifyPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1MeClaimEmailVerifyPostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1MeClaimEmailVerifyPostRequest> get serializer =>
      _$V1MeClaimEmailVerifyPostRequestSerializer();
}

class _$V1MeClaimEmailVerifyPostRequestSerializer
    implements PrimitiveSerializer<V1MeClaimEmailVerifyPostRequest> {
  @override
  final Iterable<Type> types = const [
    V1MeClaimEmailVerifyPostRequest,
    _$V1MeClaimEmailVerifyPostRequest,
  ];

  @override
  final String wireName = r'V1MeClaimEmailVerifyPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1MeClaimEmailVerifyPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(object.email, specifiedType: const FullType(String));
    yield r'code';
    yield serializers.serialize(object.code, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1MeClaimEmailVerifyPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1MeClaimEmailVerifyPostRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.email = valueDes;
          break;
        case r'code':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.code = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1MeClaimEmailVerifyPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1MeClaimEmailVerifyPostRequestBuilder();
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
