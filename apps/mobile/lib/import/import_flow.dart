// The import's state and writes: a port of apps/web/app/features/onboarding/use-import-flow.ts.
//
// Reading a Budge file, discarding, confirming (with the account adopting the file's currency when
// the preview says so), the follow-up refresh with its prefill, and skipping. While a file is read,
// confirmed or discarded the flow is [ImportFlowState.locked]: SALTAR and Back wait, so nobody
// leaves (or reverts) an import halfway.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../categories/normalize_name.dart';
import '../files/files_channel.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../ui/month_picker.dart' show addMonths;
import 'budget_input.dart';
import 'import_repository.dart';
import 'import_state.dart';

/// What a file picker offers for a Budge export: the CSV types, and the generic ones phones label a
/// `.csv` with (the web's `accept=".csv,text/csv"` is by extension, which the system picker has not).
/// The API reads the file and says when it is not a Budge export.
const csvMimeTypes = [
  'text/csv',
  'text/comma-separated-values',
  'application/csv',
  'application/vnd.ms-excel',
  'text/plain',
  'application/octet-stream',
];

/// The API's limit for an import file (apps/api routes/imports.ts `MAX_BYTES`): the picker never
/// reads past it, and the person is told before anything is sent.
const importMaxBytes = FilesChannel.defaultMaxBytes;

/// The flow's state: where the import is, and the budgets typed or prefilled by category id.
class ImportFlowState {
  const ImportFlowState({this.phase = const ImportSources(), this.drafts = const {}});

  final ImportState phase;

  /// The budget fields' text by category id: what the person typed, and what the import prefilled.
  final Map<String, String> drafts;

  /// A file is being read, confirmed or discarded: SALTAR and Back wait.
  bool get locked => switch (phase) {
    ImportReading() => true,
    ImportPreview(:final confirming, :final discarding) => confirming || discarding,
    ImportImported(:final retrying) => retrying,
    _ => false,
  };

  ImportFlowState copyWith({ImportState? phase, Map<String, String>? drafts}) =>
      ImportFlowState(phase: phase ?? this.phase, drafts: drafts ?? this.drafts);
}

/// "Basado en lo que gastaste en tus últimos 3 meses" (or "…con movimientos", for an old export).
class PrefillBasis {
  const PrefillBasis({required this.months, required this.withActivity});

  final int months;
  final bool withActivity;
}

class ImportFlow extends Notifier<ImportFlowState> {
  ImportRepository get _repo => ref.read(importRepositoryProvider);
  HomeController get _home => ref.read(homeProvider.notifier);

  var _alive = true;

  @override
  ImportFlowState build() {
    _alive = true;
    ref.onDispose(() => _alive = false);
    return const ImportFlowState();
  }

  void _set(ImportFlowState next) {
    if (_alive) state = next;
  }

  void _phase(ImportState phase) => _set(state.copyWith(phase: phase));

  /// Passes a failure on as a [HomeFailure], ending the session when the server no longer knows it.
  HomeFailure _failure(Object error) {
    if (error is FilesFailure) {
      return switch (error.kind) {
        FilesFailureKind.tooLarge => const HomeFailure(413, code: 'import_too_large'),
        _ => const HomeFailure(400, code: 'file_unreadable'),
      };
    }
    if (error is! HomeFailure) return const HomeFailure(0);
    if (error.unauthorized) {
      unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
    }
    return error;
  }

  /// From the list of sources to Budge's how-to and picker (true), and back (false).
  void chooseSource({required bool budge}) =>
      _phase(budge ? const ImportIdle() : const ImportSources());

  void setDraft(String categoryId, String text) =>
      _set(state.copyWith(drafts: {...state.drafts, categoryId: text}));

  /// Replaces every draft (typing in one field also keeps the saved budgets the others show).
  void replaceDrafts(Map<String, String> drafts) => _set(state.copyWith(drafts: drafts));

  /// Shows the document picker and reads the file chosen, within the API's limit. Closing the
  /// picker changes nothing. A file over the limit says so without sending it.
  Future<void> chooseFile() async {
    if (state.locked) return;
    final phase = state.phase;
    if (phase is! ImportIdle) return;
    final PickedFile? picked;
    try {
      picked = await ref
          .read(filesChannelProvider)
          .pickFile(mimeTypes: csvMimeTypes, maxBytes: importMaxBytes);
    } on FilesFailure catch (error) {
      if (error.kind == FilesFailureKind.busy) return;
      _phase(ImportIdle(error: _failure(error)));
      return;
    }
    if (picked == null) return;
    await readFile(picked.name, picked.bytes);
  }

  /// Reads the file. The preview says what confirming would do with the currency: an empty account
  /// takes the file's (`adoptsCurrency`, switched by the API on confirm, atomically); one with
  /// transactions keeps its own and the file's rows are rejected. Nothing changes until the confirm,
  /// so leaving or dropping the preview leaves the account as it was.
  Future<void> readFile(String name, Uint8List bytes) async {
    if (state.locked) return;
    _phase(ImportReading(name));
    try {
      final preview = await _repo.upload(name, bytes);
      final stats = preview.stats;
      final account = _home.state.data?.currency ?? '';
      final fileCurrency = stats.currency;
      final note = fileCurrency != null && fileCurrency.isNotEmpty && fileCurrency != account
          ? CurrencyNote(
              kind: stats.adoptsCurrency ? CurrencyNoteKind.switching : CurrencyNoteKind.locked,
              file: fileCurrency,
              account: account,
              dropsBudgets: stats.dropsBudgets,
            )
          : null;
      _phase(ImportPreview(fileName: name, preview: preview, currencyNote: note));
    } on Object catch (error) {
      _phase(ImportIdle(error: _failure(error)));
    }
  }

  /// Drops the preview (never one being confirmed). True when it is gone; on failure it says why.
  Future<bool> discard() async {
    final current = state.phase;
    if (current is! ImportPreview || current.confirming || current.discarding) return false;
    _phase(current.copyWith(discarding: true, error: () => null));
    try {
      await _repo.discard(current.preview.id);
      _phase(const ImportIdle());
      return true;
    } on Object catch (error) {
      _phase(current.copyWith(discarding: false, error: () => _failure(error)));
      return false;
    }
  }

  Future<void> confirm(String locale) async {
    final current = state.phase;
    if (current is! ImportPreview || current.confirming || current.discarding) return;
    _phase(current.copyWith(confirming: true, error: () => null));
    // The rows go in on the server whether or not the page is still there: the flow lives until
    // what the import changed has reached home, the profile and the widget (the web captures its
    // query client for the same reason). Leaving the page mid-confirm must not lose that.
    final link = ref.keepAlive();
    try {
      await _confirm(current, locale);
    } finally {
      link.close();
    }
  }

  Future<void> _confirm(ImportPreview current, String locale) async {
    final FileImport result;
    try {
      final switching = current.currencyNote?.kind == CurrencyNoteKind.switching;
      result = await _repo.confirm(current.preview.id, adoptFileCurrency: switching);
    } on Object catch (error) {
      _phase(current.copyWith(confirming: false, error: () => _failure(error)));
      return;
    }
    final note = current.currencyNote;
    final switched = note?.kind == CurrencyNoteKind.switching
        ? note!.copyWith(kind: CurrencyNoteKind.switched)
        : note;
    // From here the rows are in: whatever happens next, the page says so (confirming again could
    // only fail), and a failed follow-up gets a retry.
    await _afterImport(
      result,
      switched,
      locale,
      currencyChanged: switched?.kind == CurrencyNoteKind.switched,
    );
  }

  /// Refreshes what the import changed, then fills budgets from the file's recent months (the
  /// preview's `averageMonthlySpending`) for the categories without a saved budget whose field is
  /// empty, or all of them when the currency switched (amounts typed in the old currency mean
  /// nothing now). A saved budget is kept as it is. Categories without spending in those months keep
  /// no budget.
  Future<void> _afterImport(
    FileImport result,
    CurrencyNote? currencyNote,
    String locale, {
    bool currencyChanged = false,
  }) async {
    ImportImported imported({bool prefilled = false, HomeFailure? error, bool retrying = false}) =>
        ImportImported(
          result: result,
          prefilled: prefilled,
          currencyNote: currencyNote,
          error: error,
          retrying: retrying,
        );
    _phase(imported(retrying: true));
    try {
      // Everything built from transactions changed, so did the categories (new ones), and the
      // profile when the account took the file's currency: home reads it all again, and the
      // widget's snapshot and the saved month follow.
      if (currencyChanged) {
        await _home.profileChanged();
      } else {
        await _home.reloaded();
      }
      final loaded = ref.read(homeProvider);
      final data = loaded.data;
      // A load that failed leaves the old month on screen, marked stale (or says why).
      if (data == null || loaded.stale || loaded.failure != null) {
        throw loaded.failure ??
            (loaded.staleOffline
                ? const HomeFailure(0)
                : const HomeFailure(500, code: 'internal_error'));
      }
      final averages = {
        for (final a in result.stats.averageMonthlySpending) normalizeName(a.category): a.amount,
      };
      final switched = currencyNote?.kind == CurrencyNoteKind.switched;
      final next = {...state.drafts};
      var prefilled = false;
      for (final c in data.categories.values.where(
        (c) => c.kind == CategoryKindEnum.expense && !c.archived,
      )) {
        final text = next[c.id]?.trim() ?? '';
        // A budget they already saved stays theirs: shown as it is, never replaced by an average
        // (after a currency switch there are none: the API dropped them with the old currency).
        final saved = c.currentBudget;
        if (saved != null && !switched) {
          if (text.isEmpty) next[c.id] = draftFromCents(saved, locale);
          continue;
        }
        final average = averages[normalizeName(c.name)];
        if (average != null && average > 0 && (text.isEmpty || switched)) {
          next[c.id] = draftFromCents(average, locale);
          prefilled = true;
        } else if (switched) {
          next[c.id] = '';
        }
      }
      _set(
        state.copyWith(
          drafts: next,
          phase: imported(prefilled: prefilled),
        ),
      );
    } on Object catch (error) {
      _phase(imported(error: _failure(error)));
    }
  }

  void retry(String locale) {
    final current = state.phase;
    if (current is ImportImported && !current.retrying) {
      unawaited(_afterImport(current.result, current.currencyNote, locale));
    }
  }

  /// SALTAR: true when the step may be left. Never while locked; a pending preview is discarded
  /// first, and a failed discard keeps the step (with the reason) instead of moving on.
  Future<bool> skip() async {
    if (state.locked) return false;
    if (state.phase is ImportPreview) return discard();
    return true;
  }

  /// Where the prefilled budgets came from: the file's recent months, "con movimientos" when the
  /// last complete month is not the window's end (an old export).
  PrefillBasis? prefillBasis() {
    final phase = state.phase;
    if (phase is! ImportImported || !phase.prefilled) return null;
    final window = phase.result.stats.averageWindow;
    final data = ref.read(homeProvider).data;
    if (window == null || data == null) return null;
    final today = data.todayAt(ref.read(clockProvider)());
    final lastComplete = addMonths(today.substring(0, 7), -1);
    return PrefillBasis(months: window.months, withActivity: window.to != lastComplete);
  }
}

/// The import's flow; it starts over each time the page opens.
final importFlowProvider = NotifierProvider.autoDispose<ImportFlow, ImportFlowState>(
  ImportFlow.new,
);
