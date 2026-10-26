import '../settings/locale_resolution.dart';

/// The language quick capture works in for an app language [code]: the app's own (Spanish,
/// English, Italian or Portuguese), else Spanish, as `resolveAppLocale` decides the app's language.
/// It picks the voice model and the grammar that biases it.
String captureLanguage(String code) => appLanguages.contains(code) ? code : 'es';

/// The language whose rules read a typed or heard sentence in the capture [language]. Spanish and
/// English have their own words; Italian and Portuguese read digits, decimal commas and the
/// connectors they share with Spanish until their own word lists exist, so what is typed in them
/// works for amounts and never fails. (The Italian and Portuguese parsers plug in here.)
String parserLanguage(String language) => language == 'en' ? 'en' : 'es';
