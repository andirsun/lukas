//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/trend_report_months_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trend_report.g.dart';

/// TrendReport
///
/// Properties:
/// * [months]
@BuiltValue()
abstract class TrendReport implements Built<TrendReport, TrendReportBuilder> {
  @BuiltValueField(wireName: r'months')
  BuiltList<TrendReportMonthsInner> get months;

  TrendReport._();

  factory TrendReport([void updates(TrendReportBuilder b)]) = _$TrendReport;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrendReportBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrendReport> get serializer => _$TrendReportSerializer();
}

class _$TrendReportSerializer implements PrimitiveSerializer<TrendReport> {
  @override
  final Iterable<Type> types = const [TrendReport, _$TrendReport];

  @override
  final String wireName = r'TrendReport';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrendReport object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'months';
    yield serializers.serialize(
      object.months,
      specifiedType: const FullType(BuiltList, [FullType(TrendReportMonthsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TrendReport object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrendReportBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'months':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TrendReportMonthsInner)]),
          ) as BuiltList<TrendReportMonthsInner>;
          result.months.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TrendReport deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrendReportBuilder();
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
