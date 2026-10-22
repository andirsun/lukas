//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_categories_get200_response_inner.g.dart';

/// V1CategoriesGet200ResponseInner
///
/// Properties:
/// * [id]
/// * [name]
/// * [kind]
/// * [icon]
/// * [color]
/// * [sortOrder]
/// * [archived]
/// * [currentBudget]
@BuiltValue()
abstract class V1CategoriesGet200ResponseInner
    implements Built<V1CategoriesGet200ResponseInner, V1CategoriesGet200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'kind')
  V1CategoriesGet200ResponseInnerKindEnum get kind;
  // enum kindEnum {  expense,  income,  };

  @BuiltValueField(wireName: r'icon')
  String get icon;

  @BuiltValueField(wireName: r'color')
  String get color;

  @BuiltValueField(wireName: r'sortOrder')
  int get sortOrder;

  @BuiltValueField(wireName: r'archived')
  bool get archived;

  @BuiltValueField(wireName: r'currentBudget')
  int? get currentBudget;

  V1CategoriesGet200ResponseInner._();

  factory V1CategoriesGet200ResponseInner([
    void updates(V1CategoriesGet200ResponseInnerBuilder b),
  ]) = _$V1CategoriesGet200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1CategoriesGet200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1CategoriesGet200ResponseInner> get serializer =>
      _$V1CategoriesGet200ResponseInnerSerializer();
}

class _$V1CategoriesGet200ResponseInnerSerializer
    implements PrimitiveSerializer<V1CategoriesGet200ResponseInner> {
  @override
  final Iterable<Type> types = const [
    V1CategoriesGet200ResponseInner,
    _$V1CategoriesGet200ResponseInner,
  ];

  @override
  final String wireName = r'V1CategoriesGet200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1CategoriesGet200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(object.id, specifiedType: const FullType(String));
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(V1CategoriesGet200ResponseInnerKindEnum),
    );
    yield r'icon';
    yield serializers.serialize(object.icon, specifiedType: const FullType(String));
    yield r'color';
    yield serializers.serialize(object.color, specifiedType: const FullType(String));
    yield r'sortOrder';
    yield serializers.serialize(object.sortOrder, specifiedType: const FullType(int));
    yield r'archived';
    yield serializers.serialize(object.archived, specifiedType: const FullType(bool));
    yield r'currentBudget';
    yield object.currentBudget == null
        ? null
        : serializers.serialize(object.currentBudget, specifiedType: const FullType.nullable(int));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesGet200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1CategoriesGet200ResponseInnerBuilder result,
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
        case r'name':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.name = valueDes;
          break;
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1CategoriesGet200ResponseInnerKindEnum),
          ) as V1CategoriesGet200ResponseInnerKindEnum;
          result.kind = valueDes;
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
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.sortOrder = valueDes;
          break;
        case r'archived':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(bool)) as bool;
          result.archived = valueDes;
          break;
        case r'currentBudget':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.currentBudget = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1CategoriesGet200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1CategoriesGet200ResponseInnerBuilder();
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

class V1CategoriesGet200ResponseInnerKindEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'expense')
  static const V1CategoriesGet200ResponseInnerKindEnum expense =
      _$v1CategoriesGet200ResponseInnerKindEnum_expense;
  @BuiltValueEnumConst(wireName: r'income')
  static const V1CategoriesGet200ResponseInnerKindEnum income =
      _$v1CategoriesGet200ResponseInnerKindEnum_income;

  static Serializer<V1CategoriesGet200ResponseInnerKindEnum> get serializer =>
      _$v1CategoriesGet200ResponseInnerKindEnumSerializer;

  const V1CategoriesGet200ResponseInnerKindEnum._(String name) : super(name);

  static BuiltSet<V1CategoriesGet200ResponseInnerKindEnum> get values =>
      _$v1CategoriesGet200ResponseInnerKindEnumValues;
  static V1CategoriesGet200ResponseInnerKindEnum valueOf(String name) =>
      _$v1CategoriesGet200ResponseInnerKindEnumValueOf(name);
}
