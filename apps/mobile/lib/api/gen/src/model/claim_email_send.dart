//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'claim_email_send.g.dart';

/// ClaimEmailSend
///
/// Properties:
/// * [email]
@BuiltValue()
abstract class ClaimEmailSend implements Built<ClaimEmailSend, ClaimEmailSendBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  ClaimEmailSend._();

  factory ClaimEmailSend([void updates(ClaimEmailSendBuilder b)]) = _$ClaimEmailSend;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ClaimEmailSendBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ClaimEmailSend> get serializer => _$ClaimEmailSendSerializer();
}

class _$ClaimEmailSendSerializer implements PrimitiveSerializer<ClaimEmailSend> {
  @override
  final Iterable<Type> types = const [ClaimEmailSend, _$ClaimEmailSend];

  @override
  final String wireName = r'ClaimEmailSend';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ClaimEmailSend object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(object.email, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    ClaimEmailSend object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ClaimEmailSendBuilder result,
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
  ClaimEmailSend deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ClaimEmailSendBuilder();
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
