import 'dart:ui' show Locale;

/// The languages Lukitas speaks: Spanish (the default and the fallback), English, Italian and
/// European Portuguese. A region never matters here: `pt-BR` reads `pt` (European Portuguese until
/// a Brazilian variant exists), `it-CH` reads `it`.
const appLanguages = ['es', 'en', 'it', 'pt'];

/// The language the app shows for the phone's [requested] language: its own language code when the
/// app has it among [supported], else Spanish. [supported] is `AppLocalizations.supportedLocales`;
/// Italian and Portuguese join it with their ARB files, and nothing here changes then.
Locale resolveAppLocale(Locale? requested, Iterable<Locale> supported) {
  final code = requested?.languageCode;
  if (code != null && appLanguages.contains(code)) {
    for (final candidate in supported) {
      if (candidate.languageCode == code) return Locale(code);
    }
  }
  return const Locale('es');
}
