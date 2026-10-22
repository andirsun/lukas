//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_me_claim_email_send_post_request.g.dart';

/// V1MeClaimEmailSendPostRequest
///
/// Properties:
/// * [email]
@BuiltValue()
abstract class V1MeClaimEmailSendPostRequest
    implements Built<V1MeClaimEmailSendPostRequest, V1MeClaimEmailSendPostRequestBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  V1MeClaimEmailSendPostRequest._();

  factory V1MeClaimEmailSendPostRequest([void updates(V1MeClaimEmailSendPostRequestBuilder b)]) =
      _$V1MeClaimEmailSendPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1MeClaimEmailSendPostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1MeClaimEmailSendPostRequest> get serializer =>
      _$V1MeClaimEmailSendPostRequestSerializer();
}

class _$V1MeClaimEmailSendPostRequestSerializer
    implements PrimitiveSerializer<V1MeClaimEmailSendPostRequest> {
  @override
  final Iterable<Type> types = const [
    V1MeClaimEmailSendPostRequest,
    _$V1MeClaimEmailSendPostRequest,
  ];

  @override
  final String wireName = r'V1MeClaimEmailSendPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1MeClaimEmailSendPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(object.email, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1MeClaimEmailSendPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1MeClaimEmailSendPostRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1MeClaimEmailSendPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1MeClaimEmailSendPostRequestBuilder();
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
