//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'confirm_import.g.dart';

/// ConfirmImport
///
/// Properties:
/// * [adoptFileCurrency]
@BuiltValue()
abstract class ConfirmImport implements Built<ConfirmImport, ConfirmImportBuilder> {
  @BuiltValueField(wireName: r'adoptFileCurrency')
  bool? get adoptFileCurrency;

  ConfirmImport._();

  factory ConfirmImport([void updates(ConfirmImportBuilder b)]) = _$ConfirmImport;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConfirmImportBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConfirmImport> get serializer => _$ConfirmImportSerializer();
}

class _$ConfirmImportSerializer implements PrimitiveSerializer<ConfirmImport> {
  @override
  final Iterable<Type> types = const [ConfirmImport, _$ConfirmImport];

  @override
  final String wireName = r'ConfirmImport';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConfirmImport object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.adoptFileCurrency != null) {
      yield r'adoptFileCurrency';
      yield serializers.serialize(object.adoptFileCurrency, specifiedType: const FullType(bool));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ConfirmImport object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConfirmImportBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'adoptFileCurrency':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(bool)) as bool?;
          if (valueDes == null) continue;
          result.adoptFileCurrency = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConfirmImport deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConfirmImportBuilder();
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
