// The import's state: a port of apps/web/app/features/onboarding/import-state.ts.
import '../api/gen/lukitas_api.dart';
import '../home/home_repository.dart' show HomeFailure;

/// What the import does with the file's currency, from the preview's stats. [switching]: the account
/// is still empty, so confirming switches it to the file's currency (the API does it in the same
/// transaction as the inserts; [dropsBudgets] when budgets in the old one go with it). [switched]: it
/// did. [locked]: the account already has transactions in [account], so the file's rows are
/// rejected. Nothing changes the currency before the confirm.
enum CurrencyNoteKind { switching, switched, locked }

class CurrencyNote {
  const CurrencyNote({
    required this.kind,
    required this.file,
    required this.account,
    this.dropsBudgets = false,
  });

  final CurrencyNoteKind kind;
  final String file;
  final String account;
  final bool dropsBudgets;

  CurrencyNote copyWith({CurrencyNoteKind? kind}) => CurrencyNote(
    kind: kind ?? this.kind,
    file: file,
    account: account,
    dropsBudgets: dropsBudgets,
  );
}

/// The import: the list of sources, then (Budge) the how-to with the file picker ([ImportIdle]),
/// from there to a confirmed import.
sealed class ImportState {
  const ImportState();
}

class ImportSources extends ImportState {
  const ImportSources();
}

class ImportIdle extends ImportState {
  const ImportIdle({this.error});

  final HomeFailure? error;
}

class ImportReading extends ImportState {
  const ImportReading(this.fileName);

  final String fileName;
}

class ImportPreview extends ImportState {
  const ImportPreview({
    required this.fileName,
    required this.preview,
    required this.currencyNote,
    this.confirming = false,
    this.discarding = false,
    this.error,
  });

  final String fileName;
  final FileImport preview;
  final CurrencyNote? currencyNote;
  final bool confirming;
  final bool discarding;
  final HomeFailure? error;

  ImportPreview copyWith({bool? confirming, bool? discarding, HomeFailure? Function()? error}) =>
      ImportPreview(
        fileName: fileName,
        preview: preview,
        currencyNote: currencyNote,
        confirming: confirming ?? this.confirming,
        discarding: discarding ?? this.discarding,
        error: error == null ? this.error : error(),
      );
}

class ImportImported extends ImportState {
  const ImportImported({
    required this.result,
    required this.prefilled,
    required this.currencyNote,
    this.error,
    this.retrying = false,
  });

  final FileImport result;
  final bool prefilled;
  final CurrencyNote? currencyNote;

  /// The import went in, but reading the categories again failed: offer a retry.
  final HomeFailure? error;
  final bool retrying;
}

/// Rows the import will add: the file's rows minus those already there.
int newRows(FileImport preview) {
  final rows = preview.stats.transactions - preview.stats.duplicates;
  return rows < 0 ? 0 : rows;
}
