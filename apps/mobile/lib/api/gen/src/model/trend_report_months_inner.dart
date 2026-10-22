//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trend_report_months_inner.g.dart';

/// TrendReportMonthsInner
///
/// Properties:
/// * [month]
/// * [income]
/// * [expenses]
/// * [budget]
@BuiltValue()
abstract class TrendReportMonthsInner
    implements Built<TrendReportMonthsInner, TrendReportMonthsInnerBuilder> {
  @BuiltValueField(wireName: r'month')
  String get month;

  @BuiltValueField(wireName: r'income')
  int get income;

  @BuiltValueField(wireName: r'expenses')
  int get expenses;

  @BuiltValueField(wireName: r'budget')
  int get budget;

  TrendReportMonthsInner._();

  factory TrendReportMonthsInner([void updates(TrendReportMonthsInnerBuilder b)]) =
      _$TrendReportMonthsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrendReportMonthsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrendReportMonthsInner> get serializer => _$TrendReportMonthsInnerSerializer();
}

class _$TrendReportMonthsInnerSerializer implements PrimitiveSerializer<TrendReportMonthsInner> {
  @override
  final Iterable<Type> types = const [TrendReportMonthsInner, _$TrendReportMonthsInner];

  @override
  final String wireName = r'TrendReportMonthsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrendReportMonthsInner object, {
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
    TrendReportMonthsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrendReportMonthsInnerBuilder result,
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
  TrendReportMonthsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrendReportMonthsInnerBuilder();
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
