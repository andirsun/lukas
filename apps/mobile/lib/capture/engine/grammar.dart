// The vocabulary of the grammar-biased Vosk pass (voice spike report, "Follow-up: vocabulary
// biasing"): the words amounts, kinds, dates and separators are said with, and `[unk]` for
// everything else. Vosk combines these single words into any sequence ("noventa y nueve mil
// novecientos"). Every word here is in its language's small model vocabulary: Vosk warns and drops
// a word the model does not know. Spanish and English were checked in the spike; Italian and
// Portuguese are checked by test/capture/grammar_test.dart against test/fixtures/vosk_vocab_*.json
// (the model's words that this grammar and the parser use). Pure Dart.
import 'dart:convert';

import '../parser/words.dart' show fold;
import 'grammar_it_numbers.dart';

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

// Italian writes a number as one word, so its numbers are the compound words of the model
// (grammar_it_numbers.dart) besides the small ones. "centottanta" and "novantatre" and the like
// that the model lacks are left out: the free pass hears them, and the parser reads them.
const _it = <GrammarClass, List<String>>{
  GrammarClass.number: [
    'zero', 'un', 'una', ...italianNumberWordsInModel, //
    // Scales and the words around a number.
    'mila', 'mille', 'milione', 'milioni', 'mezzo', 'mezza', 'virgola',
  ],
  GrammarClass.currency: ['euro', 'dollaro', 'dollari', 'centesimo', 'centesimi'],
  GrammarClass.kind: [
    'ho',
    'speso',
    'pagato',
    'comprato',
    'ricevuto',
    'guadagnato',
    'incassato',
    'mi',
    'hanno',
  ],
  GrammarClass.date: [
    'oggi',
    'ieri',
    'lunedì',
    'martedì',
    'mercoledì',
    'giovedì',
    'venerdì',
    'sabato',
    'domenica',
  ],
  GrammarClass.separator: ['e', 'ed', 'anche'],
};

// European Portuguese spellings first; the Brazilian ones the model is trained on come with them
// (dezesseis, catorze/quatorze…), because that is what it writes.
const _pt = <GrammarClass, List<String>>{
  GrammarClass.number: [
    'zero', 'um', 'uma', 'dois', 'duas', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', //
    'nove', 'dez', 'onze', 'doze', 'treze', 'catorze', 'quatorze', 'quinze', 'dezasseis', //
    'dezassete', 'dezoito', 'dezanove', 'dezesseis', 'dezessete', 'dezenove', 'vinte', 'trinta', //
    'quarenta', 'cinquenta', 'sessenta', 'setenta', 'oitenta', 'noventa', 'cem', 'cento', //
    'duzentos', 'duzentas', 'trezentos', 'trezentas', 'quatrocentos', 'quatrocentas', //
    'quinhentos', 'quinhentas', 'seiscentos', 'seiscentas', 'setecentos', 'setecentas', //
    'oitocentos', 'oitocentas', 'novecentos', 'novecentas',
    // Scales and the words around a number.
    'mil', 'milhão', 'milhões', 'meio', 'meia', 'vírgula',
  ],
  GrammarClass.currency: [
    'euro',
    'euros',
    'dólar',
    'dólares',
    'cêntimo',
    'cêntimos',
    'centavo',
    'centavos',
  ],
  GrammarClass.kind: ['gastei', 'paguei', 'comprei', 'recebi', 'ganhei', 'me', 'pagaram'],
  GrammarClass.date: [
    'hoje', 'ontem', 'anteontem', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', //
    'domingo', 'feira',
  ],
  GrammarClass.separator: ['e', 'também'],
};

Map<GrammarClass, List<String>> _vocabulary(String locale) => switch (locale) {
  'en' => _en,
  'it' => _it,
  'pt' => _pt,
  _ => _es,
};

final _classes = {
  for (final locale in ['es', 'en', 'it', 'pt'])
    locale: {
      for (final entry in _vocabulary(locale).entries)
        for (final word in entry.value) fold(word): entry.key,
    },
};

/// The class of [word] in [locale]'s grammar, accents and case aside; null when it is not a
/// grammar word (`[unk]` included).
GrammarClass? grammarClass(String word, String locale) =>
    _classes[_classes.containsKey(locale) ? locale : 'es']![fold(word)];

/// The grammar for Vosk's `Recognizer(model, rate, grammar)`: a JSON array of the words plus
/// `[unk]`.
///
/// Plain UTF-8, never `\u` escapes: Vosk silently ignores every accented word written as an escape
/// (gasté, millón, veintidós…), the spike's first trap. `jsonEncode` writes non-ASCII characters
/// as they are.
String grammarJson(String locale) =>
    jsonEncode([for (final words in _vocabulary(locale).values) ...words, '[unk]']);
