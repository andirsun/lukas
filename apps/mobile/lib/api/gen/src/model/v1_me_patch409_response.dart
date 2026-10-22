//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_me_patch409_response_errors_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_me_patch409_response.g.dart';

/// V1MePatch409Response
///
/// Properties:
/// * [type]
/// * [title]
/// * [status]
/// * [code]
/// * [detail]
/// * [errors]
@BuiltValue()
abstract class V1MePatch409Response
    implements Built<V1MePatch409Response, V1MePatch409ResponseBuilder> {
  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'status')
  int get status;

  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'detail')
  String? get detail;

  @BuiltValueField(wireName: r'errors')
  BuiltList<V1MePatch409ResponseErrorsInner>? get errors;

  V1MePatch409Response._();

  factory V1MePatch409Response([void updates(V1MePatch409ResponseBuilder b)]) =
      _$V1MePatch409Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1MePatch409ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1MePatch409Response> get serializer => _$V1MePatch409ResponseSerializer();
}

class _$V1MePatch409ResponseSerializer implements PrimitiveSerializer<V1MePatch409Response> {
  @override
  final Iterable<Type> types = const [V1MePatch409Response, _$V1MePatch409Response];

  @override
  final String wireName = r'V1MePatch409Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1MePatch409Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(object.type, specifiedType: const FullType(String));
    yield r'title';
    yield serializers.serialize(object.title, specifiedType: const FullType(String));
    yield r'status';
    yield serializers.serialize(object.status, specifiedType: const FullType(int));
    yield r'code';
    yield serializers.serialize(object.code, specifiedType: const FullType(String));
    if (object.detail != null) {
      yield r'detail';
      yield serializers.serialize(object.detail, specifiedType: const FullType(String));
    }
    if (object.errors != null) {
      yield r'errors';
      yield serializers.serialize(
        object.errors,
        specifiedType: const FullType(BuiltList, [FullType(V1MePatch409ResponseErrorsInner)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1MePatch409Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1MePatch409ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.type = valueDes;
          break;
        case r'title':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.title = valueDes;
          break;
        case r'status':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.status = valueDes;
          break;
        case r'code':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.code = valueDes;
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.detail = valueDes;
          break;
        case r'errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [
              FullType(V1MePatch409ResponseErrorsInner),
            ]),
          ) as BuiltList<V1MePatch409ResponseErrorsInner>?;
          if (valueDes == null) continue;
          result.errors.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1MePatch409Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1MePatch409ResponseBuilder();
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
