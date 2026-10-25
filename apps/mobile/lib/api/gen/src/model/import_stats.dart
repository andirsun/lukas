//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:lukitas/api/gen/src/model/import_stats_average_monthly_spending_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/import_stats_rejected_inner.dart';
import 'package:lukitas/api/gen/src/model/import_stats_average_window.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'import_stats.g.dart';

/// ImportStats
///
/// Properties:
/// * [transactions]
/// * [duplicates]
/// * [newCategories]
/// * [rejected]
/// * [from]
/// * [to]
/// * [averageMonthlySpending]
/// * [currency]
/// * [averageWindow]
/// * [adoptsCurrency]
/// * [dropsBudgets]
/// * [inserted]
@BuiltValue()
abstract class ImportStats implements Built<ImportStats, ImportStatsBuilder> {
  @BuiltValueField(wireName: r'transactions')
  int get transactions;

  @BuiltValueField(wireName: r'duplicates')
  int get duplicates;

  @BuiltValueField(wireName: r'newCategories')
  BuiltList<String> get newCategories;

  @BuiltValueField(wireName: r'rejected')
  BuiltList<ImportStatsRejectedInner> get rejected;

  @BuiltValueField(wireName: r'from')
  String? get from;

  @BuiltValueField(wireName: r'to')
  String? get to;

  @BuiltValueField(wireName: r'averageMonthlySpending')
  BuiltList<ImportStatsAverageMonthlySpendingInner> get averageMonthlySpending;

  @BuiltValueField(wireName: r'currency')
  String? get currency;

  @BuiltValueField(wireName: r'averageWindow')
  ImportStatsAverageWindow? get averageWindow;

  @BuiltValueField(wireName: r'adoptsCurrency')
  bool get adoptsCurrency;

  @BuiltValueField(wireName: r'dropsBudgets')
  bool get dropsBudgets;

  @BuiltValueField(wireName: r'inserted')
  int? get inserted;

  ImportStats._();

  factory ImportStats([void updates(ImportStatsBuilder b)]) = _$ImportStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ImportStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ImportStats> get serializer => _$ImportStatsSerializer();
}

class _$ImportStatsSerializer implements PrimitiveSerializer<ImportStats> {
  @override
  final Iterable<Type> types = const [ImportStats, _$ImportStats];

  @override
  final String wireName = r'ImportStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ImportStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'transactions';
    yield serializers.serialize(object.transactions, specifiedType: const FullType(int));
    yield r'duplicates';
    yield serializers.serialize(object.duplicates, specifiedType: const FullType(int));
    yield r'newCategories';
    yield serializers.serialize(
      object.newCategories,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'rejected';
    yield serializers.serialize(
      object.rejected,
      specifiedType: const FullType(BuiltList, [FullType(ImportStatsRejectedInner)]),
    );
    yield r'from';
    yield object.from == null
        ? null
        : serializers.serialize(object.from, specifiedType: const FullType.nullable(String));
    yield r'to';
    yield object.to == null
        ? null
        : serializers.serialize(object.to, specifiedType: const FullType.nullable(String));
    yield r'averageMonthlySpending';
    yield serializers.serialize(
      object.averageMonthlySpending,
      specifiedType: const FullType(BuiltList, [FullType(ImportStatsAverageMonthlySpendingInner)]),
    );
    yield r'currency';
    yield object.currency == null
        ? null
        : serializers.serialize(object.currency, specifiedType: const FullType.nullable(String));
    yield r'averageWindow';
    yield object.averageWindow == null
        ? null
        : serializers.serialize(
            object.averageWindow,
            specifiedType: const FullType.nullable(ImportStatsAverageWindow),
          );
    yield r'adoptsCurrency';
    yield serializers.serialize(object.adoptsCurrency, specifiedType: const FullType(bool));
    yield r'dropsBudgets';
    yield serializers.serialize(object.dropsBudgets, specifiedType: const FullType(bool));
    if (object.inserted != null) {
      yield r'inserted';
      yield serializers.serialize(object.inserted, specifiedType: const FullType(int));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ImportStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ImportStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'transactions':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.transactions = valueDes;
          break;
        case r'duplicates':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.duplicates = valueDes;
          break;
        case r'newCategories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.newCategories.replace(valueDes);
          break;
        case r'rejected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ImportStatsRejectedInner)]),
          ) as BuiltList<ImportStatsRejectedInner>;
          result.rejected.replace(valueDes);
          break;
        case r'from':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.from = valueDes;
          break;
        case r'to':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.to = valueDes;
          break;
        case r'averageMonthlySpending':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(ImportStatsAverageMonthlySpendingInner),
            ]),
          ) as BuiltList<ImportStatsAverageMonthlySpendingInner>;
          result.averageMonthlySpending.replace(valueDes);
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.currency = valueDes;
          break;
        case r'averageWindow':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ImportStatsAverageWindow),
          ) as ImportStatsAverageWindow?;
          if (valueDes == null) continue;
          result.averageWindow.replace(valueDes);
          break;
        case r'adoptsCurrency':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(bool)) as bool;
          result.adoptsCurrency = valueDes;
          break;
        case r'dropsBudgets':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(bool)) as bool;
          result.dropsBudgets = valueDes;
          break;
        case r'inserted':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.inserted = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ImportStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ImportStatsBuilder();
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
