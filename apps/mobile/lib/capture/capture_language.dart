import '../settings/locale_resolution.dart';

/// The language quick capture works in for an app language [code]: the app's own (Spanish,
/// English, Italian or Portuguese), else Spanish, as `resolveAppLocale` decides the app's language.
/// It picks the voice model and the grammar that biases it.
String captureLanguage(String code) => appLanguages.contains(code) ? code : 'es';

/// The language whose rules read a typed or heard sentence in the capture [language]: each of the
/// app's four has its own (packages/core/quick-capture/README.md), and any other reads as Spanish.
String parserLanguage(String language) => switch (language) {
  'en' => 'en',
  'it' => 'it',
  'pt' => 'pt',
  _ => 'es',
};
