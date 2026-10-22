//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_categories_id_patch_request.g.dart';

/// V1CategoriesIdPatchRequest
///
/// Properties:
/// * [name]
/// * [icon]
/// * [color]
/// * [sortOrder]
/// * [kind]
/// * [archived]
@BuiltValue()
abstract class V1CategoriesIdPatchRequest
    implements Built<V1CategoriesIdPatchRequest, V1CategoriesIdPatchRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'icon')
  String? get icon;

  @BuiltValueField(wireName: r'color')
  String? get color;

  @BuiltValueField(wireName: r'sortOrder')
  int? get sortOrder;

  @BuiltValueField(wireName: r'kind')
  V1CategoriesIdPatchRequestKindEnum? get kind;
  // enum kindEnum {  expense,  income,  };

  @BuiltValueField(wireName: r'archived')
  bool? get archived;

  V1CategoriesIdPatchRequest._();

  factory V1CategoriesIdPatchRequest([void updates(V1CategoriesIdPatchRequestBuilder b)]) =
      _$V1CategoriesIdPatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1CategoriesIdPatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1CategoriesIdPatchRequest> get serializer =>
      _$V1CategoriesIdPatchRequestSerializer();
}

class _$V1CategoriesIdPatchRequestSerializer
    implements PrimitiveSerializer<V1CategoriesIdPatchRequest> {
  @override
  final Iterable<Type> types = const [V1CategoriesIdPatchRequest, _$V1CategoriesIdPatchRequest];

  @override
  final String wireName = r'V1CategoriesIdPatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1CategoriesIdPatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(object.name, specifiedType: const FullType(String));
    }
    if (object.icon != null) {
      yield r'icon';
      yield serializers.serialize(object.icon, specifiedType: const FullType(String));
    }
    if (object.color != null) {
      yield r'color';
      yield serializers.serialize(object.color, specifiedType: const FullType(String));
    }
    if (object.sortOrder != null) {
      yield r'sortOrder';
      yield serializers.serialize(object.sortOrder, specifiedType: const FullType(int));
    }
    if (object.kind != null) {
      yield r'kind';
      yield serializers.serialize(
        object.kind,
        specifiedType: const FullType(V1CategoriesIdPatchRequestKindEnum),
      );
    }
    if (object.archived != null) {
      yield r'archived';
      yield serializers.serialize(object.archived, specifiedType: const FullType(bool));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesIdPatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1CategoriesIdPatchRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'icon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.icon = valueDes;
          break;
        case r'color':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
            specifiedType: const FullType.nullable(V1CategoriesIdPatchRequestKindEnum),
          ) as V1CategoriesIdPatchRequestKindEnum?;
          if (valueDes == null) continue;
          result.kind = valueDes;
          break;
        case r'archived':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(bool)) as bool?;
          if (valueDes == null) continue;
          result.archived = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1CategoriesIdPatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1CategoriesIdPatchRequestBuilder();
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

class V1CategoriesIdPatchRequestKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'expense')
  static const V1CategoriesIdPatchRequestKindEnum expense =
      _$v1CategoriesIdPatchRequestKindEnum_expense;
  @BuiltValueEnumConst(wireName: r'income')
  static const V1CategoriesIdPatchRequestKindEnum income =
      _$v1CategoriesIdPatchRequestKindEnum_income;

  static Serializer<V1CategoriesIdPatchRequestKindEnum> get serializer =>
      _$v1CategoriesIdPatchRequestKindEnumSerializer;

  const V1CategoriesIdPatchRequestKindEnum._(String name) : super(name);

  static BuiltSet<V1CategoriesIdPatchRequestKindEnum> get values =>
      _$v1CategoriesIdPatchRequestKindEnumValues;
  static V1CategoriesIdPatchRequestKindEnum valueOf(String name) =>
      _$v1CategoriesIdPatchRequestKindEnumValueOf(name);
}
