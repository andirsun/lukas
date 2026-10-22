//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_reports_by_category_get200_response_items_inner.g.dart';

/// V1ReportsByCategoryGet200ResponseItemsInner
///
/// Properties:
/// * [categoryId]
/// * [name]
/// * [icon]
/// * [color]
/// * [total]
/// * [share]
@BuiltValue()
abstract class V1ReportsByCategoryGet200ResponseItemsInner
    implements
        Built<
          V1ReportsByCategoryGet200ResponseItemsInner,
          V1ReportsByCategoryGet200ResponseItemsInnerBuilder
        > {
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

  V1ReportsByCategoryGet200ResponseItemsInner._();

  factory V1ReportsByCategoryGet200ResponseItemsInner([
    void updates(V1ReportsByCategoryGet200ResponseItemsInnerBuilder b),
  ]) = _$V1ReportsByCategoryGet200ResponseItemsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ReportsByCategoryGet200ResponseItemsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ReportsByCategoryGet200ResponseItemsInner> get serializer =>
      _$V1ReportsByCategoryGet200ResponseItemsInnerSerializer();
}

class _$V1ReportsByCategoryGet200ResponseItemsInnerSerializer
    implements PrimitiveSerializer<V1ReportsByCategoryGet200ResponseItemsInner> {
  @override
  final Iterable<Type> types = const [
    V1ReportsByCategoryGet200ResponseItemsInner,
    _$V1ReportsByCategoryGet200ResponseItemsInner,
  ];

  @override
  final String wireName = r'V1ReportsByCategoryGet200ResponseItemsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ReportsByCategoryGet200ResponseItemsInner object, {
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
    V1ReportsByCategoryGet200ResponseItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ReportsByCategoryGet200ResponseItemsInnerBuilder result,
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
  V1ReportsByCategoryGet200ResponseItemsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ReportsByCategoryGet200ResponseItemsInnerBuilder();
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
