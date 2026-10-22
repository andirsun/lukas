//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'category_report_items_inner.g.dart';

/// CategoryReportItemsInner
///
/// Properties:
/// * [categoryId]
/// * [name]
/// * [icon]
/// * [color]
/// * [total]
/// * [share]
@BuiltValue()
abstract class CategoryReportItemsInner
    implements Built<CategoryReportItemsInner, CategoryReportItemsInnerBuilder> {
  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'icon')
  String get icon;

  @BuiltValueField(wireName: r'color')
  String get color;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'share')
  num get share;

  CategoryReportItemsInner._();

  factory CategoryReportItemsInner([void updates(CategoryReportItemsInnerBuilder b)]) =
      _$CategoryReportItemsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CategoryReportItemsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CategoryReportItemsInner> get serializer =>
      _$CategoryReportItemsInnerSerializer();
}

class _$CategoryReportItemsInnerSerializer
    implements PrimitiveSerializer<CategoryReportItemsInner> {
  @override
  final Iterable<Type> types = const [CategoryReportItemsInner, _$CategoryReportItemsInner];

  @override
  final String wireName = r'CategoryReportItemsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CategoryReportItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'icon';
    yield serializers.serialize(object.icon, specifiedType: const FullType(String));
    yield r'color';
    yield serializers.serialize(object.color, specifiedType: const FullType(String));
    yield r'total';
    yield serializers.serialize(object.total, specifiedType: const FullType(int));
    yield r'share';
    yield serializers.serialize(object.share, specifiedType: const FullType(num));
  }

  @override
  Object serialize(
    Serializers serializers,
    CategoryReportItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CategoryReportItemsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
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
        case r'total':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.total = valueDes;
          break;
        case r'share':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(num)) as num;
          result.share = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CategoryReportItemsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CategoryReportItemsInnerBuilder();
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
