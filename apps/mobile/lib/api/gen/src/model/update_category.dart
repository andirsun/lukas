//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_category.g.dart';

/// UpdateCategory
///
/// Properties:
/// * [name]
/// * [icon]
/// * [color]
/// * [sortOrder]
/// * [kind]
/// * [archived]
@BuiltValue()
abstract class UpdateCategory implements Built<UpdateCategory, UpdateCategoryBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'icon')
  String? get icon;

  @BuiltValueField(wireName: r'color')
  String? get color;

  @BuiltValueField(wireName: r'sortOrder')
  int? get sortOrder;

  @BuiltValueField(wireName: r'kind')
  UpdateCategoryKindEnum? get kind;
  // enum kindEnum {  expense,  income,  };

  @BuiltValueField(wireName: r'archived')
  bool? get archived;

  UpdateCategory._();

  factory UpdateCategory([void updates(UpdateCategoryBuilder b)]) = _$UpdateCategory;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateCategoryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateCategory> get serializer => _$UpdateCategorySerializer();
}

class _$UpdateCategorySerializer implements PrimitiveSerializer<UpdateCategory> {
  @override
  final Iterable<Type> types = const [UpdateCategory, _$UpdateCategory];

  @override
  final String wireName = r'UpdateCategory';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateCategory object, {
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
        specifiedType: const FullType(UpdateCategoryKindEnum),
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
    UpdateCategory object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateCategoryBuilder result,
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
            specifiedType: const FullType.nullable(UpdateCategoryKindEnum),
          ) as UpdateCategoryKindEnum?;
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
  UpdateCategory deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateCategoryBuilder();
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

class UpdateCategoryKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'expense')
  static const UpdateCategoryKindEnum expense = _$updateCategoryKindEnum_expense;
  @BuiltValueEnumConst(wireName: r'income')
  static const UpdateCategoryKindEnum income = _$updateCategoryKindEnum_income;

  static Serializer<UpdateCategoryKindEnum> get serializer => _$updateCategoryKindEnumSerializer;

  const UpdateCategoryKindEnum._(String name) : super(name);

  static BuiltSet<UpdateCategoryKindEnum> get values => _$updateCategoryKindEnumValues;
  static UpdateCategoryKindEnum valueOf(String name) => _$updateCategoryKindEnumValueOf(name);
}
