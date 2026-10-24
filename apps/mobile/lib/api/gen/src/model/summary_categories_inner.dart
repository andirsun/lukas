//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'summary_categories_inner.g.dart';

/// SummaryCategoriesInner
///
/// Properties:
/// * [categoryId]
/// * [budget]
/// * [spent]
/// * [remaining]
/// * [ratio]
/// * [state]
@BuiltValue()
abstract class SummaryCategoriesInner
    implements Built<SummaryCategoriesInner, SummaryCategoriesInnerBuilder> {
  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'budget')
  int? get budget;

  @BuiltValueField(wireName: r'spent')
  int get spent;

  @BuiltValueField(wireName: r'remaining')
  int? get remaining;

  @BuiltValueField(wireName: r'ratio')
  num? get ratio;

  @BuiltValueField(wireName: r'state')
  SummaryCategoriesInnerStateEnum get state;
  // enum stateEnum {  ok,  near,  over,  };

  SummaryCategoriesInner._();

  factory SummaryCategoriesInner([void updates(SummaryCategoriesInnerBuilder b)]) =
      _$SummaryCategoriesInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SummaryCategoriesInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SummaryCategoriesInner> get serializer => _$SummaryCategoriesInnerSerializer();
}

class _$SummaryCategoriesInnerSerializer implements PrimitiveSerializer<SummaryCategoriesInner> {
  @override
  final Iterable<Type> types = const [SummaryCategoriesInner, _$SummaryCategoriesInner];

  @override
  final String wireName = r'SummaryCategoriesInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SummaryCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'budget';
    yield object.budget == null
        ? null
        : serializers.serialize(object.budget, specifiedType: const FullType.nullable(int));
    yield r'spent';
    yield serializers.serialize(object.spent, specifiedType: const FullType(int));
    yield r'remaining';
    yield object.remaining == null
        ? null
        : serializers.serialize(object.remaining, specifiedType: const FullType.nullable(int));
    yield r'ratio';
    yield object.ratio == null
        ? null
        : serializers.serialize(object.ratio, specifiedType: const FullType.nullable(num));
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(SummaryCategoriesInnerStateEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SummaryCategoriesInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SummaryCategoriesInnerBuilder result,
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
        case r'budget':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.budget = valueDes;
          break;
        case r'spent':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.spent = valueDes;
          break;
        case r'remaining':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.remaining = valueDes;
          break;
        case r'ratio':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(num)) as num?;
          if (valueDes == null) continue;
          result.ratio = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SummaryCategoriesInnerStateEnum),
          ) as SummaryCategoriesInnerStateEnum;
          result.state = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SummaryCategoriesInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SummaryCategoriesInnerBuilder();
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

class SummaryCategoriesInnerStateEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ok')
  static const SummaryCategoriesInnerStateEnum ok = _$summaryCategoriesInnerStateEnum_ok;
  @BuiltValueEnumConst(wireName: r'near')
  static const SummaryCategoriesInnerStateEnum near = _$summaryCategoriesInnerStateEnum_near;
  @BuiltValueEnumConst(wireName: r'over')
  static const SummaryCategoriesInnerStateEnum over = _$summaryCategoriesInnerStateEnum_over;

  static Serializer<SummaryCategoriesInnerStateEnum> get serializer =>
      _$summaryCategoriesInnerStateEnumSerializer;

  const SummaryCategoriesInnerStateEnum._(String name) : super(name);

  static BuiltSet<SummaryCategoriesInnerStateEnum> get values =>
      _$summaryCategoriesInnerStateEnumValues;
  static SummaryCategoriesInnerStateEnum valueOf(String name) =>
      _$summaryCategoriesInnerStateEnumValueOf(name);
}
