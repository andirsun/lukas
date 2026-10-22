//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_reports_trend_get200_response_months_inner.g.dart';

/// V1ReportsTrendGet200ResponseMonthsInner
///
/// Properties:
/// * [month]
/// * [income]
/// * [expenses]
/// * [budget]
@BuiltValue()
abstract class V1ReportsTrendGet200ResponseMonthsInner
    implements
        Built<
          V1ReportsTrendGet200ResponseMonthsInner,
          V1ReportsTrendGet200ResponseMonthsInnerBuilder
        > {
  @BuiltValueField(wireName: r'month')
  String get month;

  @BuiltValueField(wireName: r'income')
  int get income;

  @BuiltValueField(wireName: r'expenses')
  int get expenses;

  @BuiltValueField(wireName: r'budget')
  int get budget;

  V1ReportsTrendGet200ResponseMonthsInner._();

  factory V1ReportsTrendGet200ResponseMonthsInner([
    void updates(V1ReportsTrendGet200ResponseMonthsInnerBuilder b),
  ]) = _$V1ReportsTrendGet200ResponseMonthsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ReportsTrendGet200ResponseMonthsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ReportsTrendGet200ResponseMonthsInner> get serializer =>
      _$V1ReportsTrendGet200ResponseMonthsInnerSerializer();
}

class _$V1ReportsTrendGet200ResponseMonthsInnerSerializer
    implements PrimitiveSerializer<V1ReportsTrendGet200ResponseMonthsInner> {
  @override
  final Iterable<Type> types = const [
    V1ReportsTrendGet200ResponseMonthsInner,
    _$V1ReportsTrendGet200ResponseMonthsInner,
  ];

  @override
  final String wireName = r'V1ReportsTrendGet200ResponseMonthsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ReportsTrendGet200ResponseMonthsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'month';
    yield serializers.serialize(object.month, specifiedType: const FullType(String));
    yield r'income';
    yield serializers.serialize(object.income, specifiedType: const FullType(int));
    yield r'expenses';
    yield serializers.serialize(object.expenses, specifiedType: const FullType(int));
    yield r'budget';
    yield serializers.serialize(object.budget, specifiedType: const FullType(int));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ReportsTrendGet200ResponseMonthsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ReportsTrendGet200ResponseMonthsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'month':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.month = valueDes;
          break;
        case r'income':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.income = valueDes;
          break;
        case r'expenses':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.expenses = valueDes;
          break;
        case r'budget':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.budget = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ReportsTrendGet200ResponseMonthsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ReportsTrendGet200ResponseMonthsInnerBuilder();
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
