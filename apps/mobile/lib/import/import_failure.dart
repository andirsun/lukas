import '../home/home_repository.dart' show HomeFailure;
import '../l10n/app_localizations.dart';

/// What the import says when something fails: the web's `problemMessage` (`errors.<code>`, the
/// generic text for a code with none).
String importFailureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  return switch (failure.code) {
    'import_duplicate_file' => l10n.errorImportDuplicateFile,
    'import_too_large' => l10n.errorImportTooLarge,
    'import_unrecognized_format' => l10n.errorImportUnrecognizedFormat,
    'import_not_in_preview' => l10n.errorImportNotInPreview,
    'import_currency_changed' => l10n.errorImportCurrencyChanged,
    'currency_locked' => l10n.errorCurrencyLocked,
    'validation_failed' => l10n.addErrorInvalid,
    'not_found' => l10n.budgetErrorNotFound,
    _ =>
      // A proxy that refuses a body that big answers 413 with no code of ours.
      failure.status == 413
          ? l10n.errorImportTooLarge
          : failure.status >= 500
          ? l10n.errorInternal
          : l10n.errorGeneric,
  };
}
