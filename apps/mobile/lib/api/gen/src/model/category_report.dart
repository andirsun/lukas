//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/category_report_items_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'category_report.g.dart';

/// CategoryReport
///
/// Properties:
/// * [total]
/// * [items]
@BuiltValue()
abstract class CategoryReport implements Built<CategoryReport, CategoryReportBuilder> {
  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'items')
  BuiltList<CategoryReportItemsInner> get items;

  CategoryReport._();

  factory CategoryReport([void updates(CategoryReportBuilder b)]) = _$CategoryReport;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CategoryReportBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CategoryReport> get serializer => _$CategoryReportSerializer();
}

class _$CategoryReportSerializer implements PrimitiveSerializer<CategoryReport> {
  @override
  final Iterable<Type> types = const [CategoryReport, _$CategoryReport];

  @override
  final String wireName = r'CategoryReport';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CategoryReport object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total';
    yield serializers.serialize(object.total, specifiedType: const FullType(int));
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(CategoryReportItemsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CategoryReport object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CategoryReportBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.total = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CategoryReportItemsInner)]),
          ) as BuiltList<CategoryReportItemsInner>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CategoryReport deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CategoryReportBuilder();
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
