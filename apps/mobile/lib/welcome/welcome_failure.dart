import '../categories/categories_actions.dart' show categoryFailureMessage;
import '../home/home_repository.dart' show HomeFailure;
import '../import/import_failure.dart';
import '../l10n/app_localizations.dart';

/// What the welcome says when a step fails: the web's `problemMessage` (`errors.<code>`, the generic
/// text for a code with none). Anything that is not a failure of the API is the generic one.
String welcomeFailureMessage(AppLocalizations l10n, Object problem) {
  final failure = problem is HomeFailure ? problem : const HomeFailure(0, code: 'unknown');
  if (failure.code == 'unknown') return l10n.errorGeneric;
  return switch (failure.code) {
    'category_name_taken' || 'category_has_transactions' => categoryFailureMessage(l10n, failure),
    _ => importFailureMessage(l10n, failure),
  };
}
