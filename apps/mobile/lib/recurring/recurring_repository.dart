import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/client.dart';
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_repository.dart';

/// What the form sends: the web's `NewRecurrence` (apps/web/app/api/queries.ts), the body of
/// `POST /v1/recurrences`. An expense's [amount] is negative, in hundredths; [monthOfYear] is set
/// for a yearly one only, and [endDate] when it ends.
class NewRecurrence {
  const NewRecurrence({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.dayOfMonth,
    required this.monthOfYear,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final int amount;
  final String categoryId;
  final RecurrenceFrequencyEnum frequency;
  final int dayOfMonth;
  final int? monthOfYear;
  final String startDate;
  final String? endDate;
}

/// What the recurring payments read and change on the server, as the web's queries do
/// (apps/web/app/api/queries.ts `useRecurrences`, `useCreateRecurrence`, `useUpdateRecurrence` and
/// `useDeleteRecurrence`).
abstract interface class RecurringRepository {
  /// `GET /v1/recurrences`: the account's rules, oldest first. The API also adds each one's pending
  /// transaction to this month and the next as it reads them.
  Future<List<Recurrence>> list();

  /// `POST /v1/recurrences`. The route takes no idempotency key (unlike a transaction's), so the
  /// form never sends one twice: it is held while a save is on its way.
  Future<Recurrence> create(NewRecurrence values);

  /// `PATCH /v1/recurrences/{id}` with every field of [values], a cleared end date and a monthly
  /// rule's month as explicit `null`s (the web sends them so). The category goes only when
  /// [categoryChanged]: one archived since stays as it is, without a 422.
  Future<Recurrence> update(String id, NewRecurrence values, {required bool categoryChanged});

  /// `DELETE /v1/recurrences/{id}`: the rule goes, and its unpaid pending transactions from this
  /// month on; what was paid stays.
  Future<void> delete(String id);
}

/// [RecurringRepository] over the generated client (and Dio for the PATCH, whose nulls the
/// generated serializer leaves out).
class ApiRecurringRepository implements RecurringRepository {
  ApiRecurringRepository(this._client);

  final ApiClient _client;

  DefaultApi get _api => _client.api.getDefaultApi();

  static Future<T> _settle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<List<Recurrence>> list() => _settle(() async {
    final data = (await _api.listRecurrences()).data;
    if (data == null) throw const HomeFailure(500);
    return data.toList();
  });

  @override
  Future<Recurrence> create(NewRecurrence values) => _settle(() async {
    final made = (await _api.createRecurrence(
      createRecurrence: CreateRecurrence(
        (b) => b
          ..name = values.name
          ..amount = values.amount
          ..categoryId = values.categoryId
          ..frequency = switch (values.frequency) {
            RecurrenceFrequencyEnum.yearly => CreateRecurrenceFrequencyEnum.yearly,
            _ => CreateRecurrenceFrequencyEnum.monthly,
          }
          ..dayOfMonth = values.dayOfMonth
          ..monthOfYear = values.monthOfYear
          ..startDate = values.startDate
          ..endDate = values.endDate,
      ),
    )).data;
    if (made == null) throw const HomeFailure(500);
    return made;
  });

  @override
  Future<Recurrence> update(String id, NewRecurrence values, {required bool categoryChanged}) =>
      _settle(() async {
        final response = await _client.dio.patch<Object?>(
          '/v1/recurrences/$id',
          data: {
            'name': values.name,
            'amount': values.amount,
            if (categoryChanged) 'categoryId': values.categoryId,
            'frequency': values.frequency.name,
            'dayOfMonth': values.dayOfMonth,
            'monthOfYear': values.monthOfYear,
            'startDate': values.startDate,
            'endDate': values.endDate,
          },
        );
        final body = response.data;
        if (body == null) throw const HomeFailure(500);
        return standardSerializers.deserializeWith(Recurrence.serializer, body)!;
      });

  @override
  Future<void> delete(String id) => _settle(() async {
    await _api.deleteRecurrence(id: id);
  });
}

/// The recurring payments' repository for the signed-in session (rebuilt when the token changes).
final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => ApiRecurringRepository(ref.watch(apiClientProvider)),
);
