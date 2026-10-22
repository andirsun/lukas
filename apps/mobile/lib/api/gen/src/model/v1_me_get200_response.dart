//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_me_get200_response.g.dart';

/// V1MeGet200Response
///
/// Properties:
/// * [id]
/// * [email]
/// * [timezone]
/// * [locale]
/// * [onboardingCompletedAt]
/// * [currency]
/// * [isAnonymous]
@BuiltValue()
abstract class V1MeGet200Response implements Built<V1MeGet200Response, V1MeGet200ResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'locale')
  String get locale;

  @BuiltValueField(wireName: r'onboardingCompletedAt')
  String? get onboardingCompletedAt;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'isAnonymous')
  bool get isAnonymous;

  V1MeGet200Response._();

  factory V1MeGet200Response([void updates(V1MeGet200ResponseBuilder b)]) = _$V1MeGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1MeGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1MeGet200Response> get serializer => _$V1MeGet200ResponseSerializer();
}

class _$V1MeGet200ResponseSerializer implements PrimitiveSerializer<V1MeGet200Response> {
  @override
  final Iterable<Type> types = const [V1MeGet200Response, _$V1MeGet200Response];

  @override
  final String wireName = r'V1MeGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1MeGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(object.id, specifiedType: const FullType(String));
    yield r'email';
    yield serializers.serialize(object.email, specifiedType: const FullType(String));
    yield r'timezone';
    yield serializers.serialize(object.timezone, specifiedType: const FullType(String));
    yield r'locale';
    yield serializers.serialize(object.locale, specifiedType: const FullType(String));
    yield r'onboardingCompletedAt';
    yield object.onboardingCompletedAt == null
        ? null
        : serializers.serialize(
            object.onboardingCompletedAt,
            specifiedType: const FullType.nullable(String),
          );
    yield r'currency';
    yield serializers.serialize(object.currency, specifiedType: const FullType(String));
    yield r'isAnonymous';
    yield serializers.serialize(object.isAnonymous, specifiedType: const FullType(bool));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1MeGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1MeGet200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.id = valueDes;
          break;
        case r'email':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.email = valueDes;
          break;
        case r'timezone':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.timezone = valueDes;
          break;
        case r'locale':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.locale = valueDes;
          break;
        case r'onboardingCompletedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.onboardingCompletedAt = valueDes;
          break;
        case r'currency':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.currency = valueDes;
          break;
        case r'isAnonymous':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(bool)) as bool;
          result.isAnonymous = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1MeGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1MeGet200ResponseBuilder();
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
