//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_me_patch_request.g.dart';

/// V1MePatchRequest
///
/// Properties:
/// * [timezone]
/// * [locale]
/// * [currency]
/// * [onboardingCompleted]
@BuiltValue()
abstract class V1MePatchRequest implements Built<V1MePatchRequest, V1MePatchRequestBuilder> {
  @BuiltValueField(wireName: r'timezone')
  String? get timezone;

  @BuiltValueField(wireName: r'locale')
  V1MePatchRequestLocaleEnum? get locale;
  // enum localeEnum {  es,  en,  };

  @BuiltValueField(wireName: r'currency')
  V1MePatchRequestCurrencyEnum? get currency;
  // enum currencyEnum {  COP,  USD,  EUR,  };

  @BuiltValueField(wireName: r'onboardingCompleted')
  V1MePatchRequestOnboardingCompletedEnum? get onboardingCompleted;
  // enum onboardingCompletedEnum {  true,  };

  V1MePatchRequest._();

  factory V1MePatchRequest([void updates(V1MePatchRequestBuilder b)]) = _$V1MePatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1MePatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1MePatchRequest> get serializer => _$V1MePatchRequestSerializer();
}

class _$V1MePatchRequestSerializer implements PrimitiveSerializer<V1MePatchRequest> {
  @override
  final Iterable<Type> types = const [V1MePatchRequest, _$V1MePatchRequest];

  @override
  final String wireName = r'V1MePatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1MePatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.timezone != null) {
      yield r'timezone';
      yield serializers.serialize(object.timezone, specifiedType: const FullType(String));
    }
    if (object.locale != null) {
      yield r'locale';
      yield serializers.serialize(
        object.locale,
        specifiedType: const FullType(V1MePatchRequestLocaleEnum),
      );
    }
    if (object.currency != null) {
      yield r'currency';
      yield serializers.serialize(
        object.currency,
        specifiedType: const FullType(V1MePatchRequestCurrencyEnum),
      );
    }
    if (object.onboardingCompleted != null) {
      yield r'onboardingCompleted';
      yield serializers.serialize(
        object.onboardingCompleted,
        specifiedType: const FullType(V1MePatchRequestOnboardingCompletedEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1MePatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1MePatchRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.timezone = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(V1MePatchRequestLocaleEnum),
          ) as V1MePatchRequestLocaleEnum?;
          if (valueDes == null) continue;
          result.locale = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(V1MePatchRequestCurrencyEnum),
          ) as V1MePatchRequestCurrencyEnum?;
          if (valueDes == null) continue;
          result.currency = valueDes;
          break;
        case r'onboardingCompleted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(V1MePatchRequestOnboardingCompletedEnum),
          ) as V1MePatchRequestOnboardingCompletedEnum?;
          if (valueDes == null) continue;
          result.onboardingCompleted = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1MePatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1MePatchRequestBuilder();
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

class V1MePatchRequestLocaleEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'es')
  static const V1MePatchRequestLocaleEnum es = _$v1MePatchRequestLocaleEnum_es;
  @BuiltValueEnumConst(wireName: r'en')
  static const V1MePatchRequestLocaleEnum en = _$v1MePatchRequestLocaleEnum_en;

  static Serializer<V1MePatchRequestLocaleEnum> get serializer =>
      _$v1MePatchRequestLocaleEnumSerializer;

  const V1MePatchRequestLocaleEnum._(String name) : super(name);

  static BuiltSet<V1MePatchRequestLocaleEnum> get values => _$v1MePatchRequestLocaleEnumValues;
  static V1MePatchRequestLocaleEnum valueOf(String name) =>
      _$v1MePatchRequestLocaleEnumValueOf(name);
}

class V1MePatchRequestCurrencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'COP')
  static const V1MePatchRequestCurrencyEnum COP = _$v1MePatchRequestCurrencyEnum_COP;
  @BuiltValueEnumConst(wireName: r'USD')
  static const V1MePatchRequestCurrencyEnum USD = _$v1MePatchRequestCurrencyEnum_USD;
  @BuiltValueEnumConst(wireName: r'EUR')
  static const V1MePatchRequestCurrencyEnum EUR = _$v1MePatchRequestCurrencyEnum_EUR;

  static Serializer<V1MePatchRequestCurrencyEnum> get serializer =>
      _$v1MePatchRequestCurrencyEnumSerializer;

  const V1MePatchRequestCurrencyEnum._(String name) : super(name);

  static BuiltSet<V1MePatchRequestCurrencyEnum> get values => _$v1MePatchRequestCurrencyEnumValues;
  static V1MePatchRequestCurrencyEnum valueOf(String name) =>
      _$v1MePatchRequestCurrencyEnumValueOf(name);
}

class V1MePatchRequestOnboardingCompletedEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'true')
  static const V1MePatchRequestOnboardingCompletedEnum true_ =
      _$v1MePatchRequestOnboardingCompletedEnum_true_;

  static Serializer<V1MePatchRequestOnboardingCompletedEnum> get serializer =>
      _$v1MePatchRequestOnboardingCompletedEnumSerializer;

  const V1MePatchRequestOnboardingCompletedEnum._(String name) : super(name);

  static BuiltSet<V1MePatchRequestOnboardingCompletedEnum> get values =>
      _$v1MePatchRequestOnboardingCompletedEnumValues;
  static V1MePatchRequestOnboardingCompletedEnum valueOf(String name) =>
      _$v1MePatchRequestOnboardingCompletedEnumValueOf(name);
}
