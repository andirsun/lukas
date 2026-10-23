// The vocabulary of the grammar-biased Vosk pass (voice spike report, "Follow-up: vocabulary
// biasing"): the words amounts, kinds, dates and separators are said with, and `[unk]` for
// everything else. Vosk combines these single words into any sequence ("noventa y nueve mil
// novecientos"). Every word here is in both small models' vocabularies. Pure Dart.
import 'dart:convert';

import '../parser/words.dart' show fold;

/// What a grammar word is for. Merge rule v2 (merge.dart) treats [number] words differently from
/// the rest.
enum GrammarClass { number, currency, kind, date, separator }

const _es = <GrammarClass, List<String>>{
  GrammarClass.number: [
    // Numbers.
    'cero', 'un', 'uno', 'una', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', //
    'nueve', 'diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', //
    'dieciocho', 'diecinueve', 'veinte', 'veintiún', 'veintiuno', 'veintiuna', 'veintidós', //
    'veintitrés', 'veinticuatro', 'veinticinco', 'veintiséis', 'veintisiete', 'veintiocho', //
    'veintinueve', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', //
    'noventa', 'cien', 'ciento', 'doscientos', 'doscientas', 'trescientos', 'trescientas', //
    'cuatrocientos', 'cuatrocientas', 'quinientos', 'quinientas', 'seiscientos', //
    'seiscientas', 'setecientos', 'setecientas', 'ochocientos', 'ochocientas', 'novecientos', //
    'novecientas',
    // Multipliers and the words around a number.
    'mil', 'millón', 'millones', 'luca', 'lucas', 'luka', 'lukas', 'palo', 'palos', 'medio', //
    'coma', 'punto', 'con',
  ],
  GrammarClass.currency: ['euro', 'euros', 'dólar', 'dólares', 'peso', 'pesos'],
  GrammarClass.kind: ['gasté', 'pagué', 'compré', 'me', 'pagaron', 'recibí', 'llegó'],
  GrammarClass.date: [
    'hoy', 'ayer', 'antier', 'anteayer', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', //
    'sábado', 'domingo',
  ],
  GrammarClass.separator: ['y', 'también'],
};

const _en = <GrammarClass, List<String>>{
  GrammarClass.number: [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', //
    'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', //
    'nineteen', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety', //
    'hundred', 'thousand', 'million', 'point',
  ],
  GrammarClass.currency: ['dollar', 'dollars', 'euro', 'euros', 'pesos'],
  GrammarClass.kind: ['spent', 'paid', 'got'],
  GrammarClass.date: [
    'today', 'yesterday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', //
    'sunday',
  ],
  GrammarClass.separator: ['and', 'also'],
};

Map<GrammarClass, List<String>> _vocabulary(String locale) => locale == 'en' ? _en : _es;

final _classes = {
  for (final locale in ['es', 'en'])
    locale: {
      for (final entry in _vocabulary(locale).entries)
        for (final word in entry.value) fold(word): entry.key,
    },
};

/// The class of [word] in [locale]'s grammar, accents and case aside; null when it is not a
/// grammar word (`[unk]` included).
GrammarClass? grammarClass(String word, String locale) =>
    _classes[locale == 'en' ? 'en' : 'es']![fold(word)];

/// The grammar for Vosk's `Recognizer(model, rate, grammar)`: a JSON array of the words plus
/// `[unk]`.
///
/// Plain UTF-8, never `\u` escapes: Vosk silently ignores every accented word written as an escape
/// (gasté, millón, veintidós…), the spike's first trap. `jsonEncode` writes non-ASCII characters
/// as they are.
String grammarJson(String locale) =>
    jsonEncode([for (final words in _vocabulary(locale).values) ...words, '[unk]']);
