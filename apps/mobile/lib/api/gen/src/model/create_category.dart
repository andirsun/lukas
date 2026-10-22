//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_category.g.dart';

/// CreateCategory
///
/// Properties:
/// * [name]
/// * [icon]
/// * [color]
/// * [sortOrder]
/// * [kind]
@BuiltValue()
abstract class CreateCategory implements Built<CreateCategory, CreateCategoryBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'icon')
  String get icon;

  @BuiltValueField(wireName: r'color')
  String get color;

  @BuiltValueField(wireName: r'sortOrder')
  int? get sortOrder;

  @BuiltValueField(wireName: r'kind')
  CreateCategoryKindEnum get kind;
  // enum kindEnum {  expense,  income,  };

  CreateCategory._();

  factory CreateCategory([void updates(CreateCategoryBuilder b)]) = _$CreateCategory;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateCategoryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateCategory> get serializer => _$CreateCategorySerializer();
}

class _$CreateCategorySerializer implements PrimitiveSerializer<CreateCategory> {
  @override
  final Iterable<Type> types = const [CreateCategory, _$CreateCategory];

  @override
  final String wireName = r'CreateCategory';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateCategory object, {
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
    yield serializers.serialize(object.kind, specifiedType: const FullType(CreateCategoryKindEnum));
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateCategory object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateCategoryBuilder result,
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
            specifiedType: const FullType(CreateCategoryKindEnum),
          ) as CreateCategoryKindEnum;
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
  CreateCategory deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateCategoryBuilder();
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

class CreateCategoryKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'expense')
  static const CreateCategoryKindEnum expense = _$createCategoryKindEnum_expense;
  @BuiltValueEnumConst(wireName: r'income')
  static const CreateCategoryKindEnum income = _$createCategoryKindEnum_income;

  static Serializer<CreateCategoryKindEnum> get serializer => _$createCategoryKindEnumSerializer;

  const CreateCategoryKindEnum._(String name) : super(name);

  static BuiltSet<CreateCategoryKindEnum> get values => _$createCategoryKindEnumValues;
  static CreateCategoryKindEnum valueOf(String name) => _$createCategoryKindEnumValueOf(name);
}
