//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_categories_post_request.g.dart';

/// V1CategoriesPostRequest
///
/// Properties:
/// * [name]
/// * [icon]
/// * [color]
/// * [sortOrder]
/// * [kind]
@BuiltValue()
abstract class V1CategoriesPostRequest
    implements Built<V1CategoriesPostRequest, V1CategoriesPostRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'icon')
  String get icon;

  @BuiltValueField(wireName: r'color')
  String get color;

  @BuiltValueField(wireName: r'sortOrder')
  int? get sortOrder;

  @BuiltValueField(wireName: r'kind')
  V1CategoriesPostRequestKindEnum get kind;
  // enum kindEnum {  expense,  income,  };

  V1CategoriesPostRequest._();

  factory V1CategoriesPostRequest([void updates(V1CategoriesPostRequestBuilder b)]) =
      _$V1CategoriesPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1CategoriesPostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1CategoriesPostRequest> get serializer =>
      _$V1CategoriesPostRequestSerializer();
}

class _$V1CategoriesPostRequestSerializer implements PrimitiveSerializer<V1CategoriesPostRequest> {
  @override
  final Iterable<Type> types = const [V1CategoriesPostRequest, _$V1CategoriesPostRequest];

  @override
  final String wireName = r'V1CategoriesPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1CategoriesPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'icon';
    yield serializers.serialize(object.icon, specifiedType: const FullType(String));
    yield r'color';
    yield serializers.serialize(object.color, specifiedType: const FullType(String));
    if (object.sortOrder != null) {
      yield r'sortOrder';
      yield serializers.serialize(object.sortOrder, specifiedType: const FullType(int));
    }
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(V1CategoriesPostRequestKindEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1CategoriesPostRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.name = valueDes;
          break;
        case r'icon':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.icon = valueDes;
          break;
        case r'color':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.color = valueDes;
          break;
        case r'sortOrder':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.sortOrder = valueDes;
          break;
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1CategoriesPostRequestKindEnum),
          ) as V1CategoriesPostRequestKindEnum;
          result.kind = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1CategoriesPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1CategoriesPostRequestBuilder();
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

class V1CategoriesPostRequestKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'expense')
  static const V1CategoriesPostRequestKindEnum expense = _$v1CategoriesPostRequestKindEnum_expense;
  @BuiltValueEnumConst(wireName: r'income')
  static const V1CategoriesPostRequestKindEnum income = _$v1CategoriesPostRequestKindEnum_income;

  static Serializer<V1CategoriesPostRequestKindEnum> get serializer =>
      _$v1CategoriesPostRequestKindEnumSerializer;

  const V1CategoriesPostRequestKindEnum._(String name) : super(name);

  static BuiltSet<V1CategoriesPostRequestKindEnum> get values =>
      _$v1CategoriesPostRequestKindEnumValues;
  static V1CategoriesPostRequestKindEnum valueOf(String name) =>
      _$v1CategoriesPostRequestKindEnumValueOf(name);
}
