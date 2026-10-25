//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_profile.g.dart';

/// UpdateProfile
///
/// Properties:
/// * [timezone]
/// * [locale]
/// * [currency]
/// * [onboardingCompleted]
@BuiltValue()
abstract class UpdateProfile implements Built<UpdateProfile, UpdateProfileBuilder> {
  @BuiltValueField(wireName: r'timezone')
  String? get timezone;

  @BuiltValueField(wireName: r'locale')
  UpdateProfileLocaleEnum? get locale;
  // enum localeEnum {  es,  en,  };

  @BuiltValueField(wireName: r'currency')
  UpdateProfileCurrencyEnum? get currency;
  // enum currencyEnum {  COP,  USD,  EUR,  };

  @BuiltValueField(wireName: r'onboardingCompleted')
  UpdateProfileOnboardingCompletedEnum? get onboardingCompleted;
  // enum onboardingCompletedEnum {  true,  };

  UpdateProfile._();

  factory UpdateProfile([void updates(UpdateProfileBuilder b)]) = _$UpdateProfile;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateProfileBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateProfile> get serializer => _$UpdateProfileSerializer();
}

class _$UpdateProfileSerializer implements PrimitiveSerializer<UpdateProfile> {
  @override
  final Iterable<Type> types = const [UpdateProfile, _$UpdateProfile];

  @override
  final String wireName = r'UpdateProfile';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateProfile object, {
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
        specifiedType: const FullType(UpdateProfileLocaleEnum),
      );
    }
    if (object.currency != null) {
      yield r'currency';
      yield serializers.serialize(
        object.currency,
        specifiedType: const FullType(UpdateProfileCurrencyEnum),
      );
    }
    if (object.onboardingCompleted != null) {
      yield r'onboardingCompleted';
      yield serializers.serialize(
        object.onboardingCompleted,
        specifiedType: const FullType(UpdateProfileOnboardingCompletedEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateProfile object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateProfileBuilder result,
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
            specifiedType: const FullType.nullable(UpdateProfileLocaleEnum),
          ) as UpdateProfileLocaleEnum?;
          if (valueDes == null) continue;
          result.locale = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(UpdateProfileCurrencyEnum),
          ) as UpdateProfileCurrencyEnum?;
          if (valueDes == null) continue;
          result.currency = valueDes;
          break;
        case r'onboardingCompleted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(UpdateProfileOnboardingCompletedEnum),
          ) as UpdateProfileOnboardingCompletedEnum?;
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
  UpdateProfile deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateProfileBuilder();
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

class UpdateProfileLocaleEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'es')
  static const UpdateProfileLocaleEnum es = _$updateProfileLocaleEnum_es;
  @BuiltValueEnumConst(wireName: r'en')
  static const UpdateProfileLocaleEnum en = _$updateProfileLocaleEnum_en;

  static Serializer<UpdateProfileLocaleEnum> get serializer => _$updateProfileLocaleEnumSerializer;

  const UpdateProfileLocaleEnum._(String name) : super(name);

  static BuiltSet<UpdateProfileLocaleEnum> get values => _$updateProfileLocaleEnumValues;
  static UpdateProfileLocaleEnum valueOf(String name) => _$updateProfileLocaleEnumValueOf(name);
}

class UpdateProfileCurrencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'COP')
  static const UpdateProfileCurrencyEnum COP = _$updateProfileCurrencyEnum_COP;
  @BuiltValueEnumConst(wireName: r'USD')
  static const UpdateProfileCurrencyEnum USD = _$updateProfileCurrencyEnum_USD;
  @BuiltValueEnumConst(wireName: r'EUR')
  static const UpdateProfileCurrencyEnum EUR = _$updateProfileCurrencyEnum_EUR;

  static Serializer<UpdateProfileCurrencyEnum> get serializer =>
      _$updateProfileCurrencyEnumSerializer;

  const UpdateProfileCurrencyEnum._(String name) : super(name);

  static BuiltSet<UpdateProfileCurrencyEnum> get values => _$updateProfileCurrencyEnumValues;
  static UpdateProfileCurrencyEnum valueOf(String name) => _$updateProfileCurrencyEnumValueOf(name);
}

class UpdateProfileOnboardingCompletedEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'true')
  static const UpdateProfileOnboardingCompletedEnum true_ =
      _$updateProfileOnboardingCompletedEnum_true_;

  static Serializer<UpdateProfileOnboardingCompletedEnum> get serializer =>
      _$updateProfileOnboardingCompletedEnumSerializer;

  const UpdateProfileOnboardingCompletedEnum._(String name) : super(name);

  static BuiltSet<UpdateProfileOnboardingCompletedEnum> get values =>
      _$updateProfileOnboardingCompletedEnumValues;
  static UpdateProfileOnboardingCompletedEnum valueOf(String name) =>
      _$updateProfileOnboardingCompletedEnumValueOf(name);
}
