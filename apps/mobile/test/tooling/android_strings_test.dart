import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The Android string resources (the widget, the Quick Settings tile, the two notices) in the four
// languages: values/ is Spanish, the default; values-en, values-it and values-pt follow. They are
// read by Kotlin with no Flutter running, so nothing else would notice a missing or changed word.

const _res = 'android/app/src/main/res';
const _folders = {'es': 'values', 'en': 'values-en', 'it': 'values-it', 'pt': 'values-pt'};

class _Entry {
  _Entry(this.value, {required this.translatable});

  final String value;
  final bool translatable;
}

Map<String, _Entry> _strings(String folder) {
  final source = File('$_res/$folder/strings.xml').readAsStringSync();
  final out = <String, _Entry>{};
  for (final m in RegExp(
    r'<string\s+name="(\w+)"([^>]*)>(.*?)</string>',
    dotAll: true,
  ).allMatches(source)) {
    out[m.group(1)!] = _Entry(
      m.group(3)!,
      translatable: !m.group(2)!.contains('translatable="false"'),
    );
  }
  return out;
}

/// The printf-style arguments of a resource: `%1$s`, `%1$d`, and a literal `%%` ignored.
List<String> _formats(String value) =>
    [for (final m in RegExp(r'%(\d+\$[sd])').allMatches(value.replaceAll('%%', ''))) m.group(1)!]
      ..sort();

void main() {
  final all = {for (final e in _folders.entries) e.key: _strings(e.value)};
  final es = all['es']!;
  final translatable = {
    for (final e in es.entries)
      if (e.value.translatable) e.key,
  };

  test('values/ is the Spanish default and has strings', () {
    expect(translatable, isNotEmpty);
  });

  for (final language in ['en', 'it', 'pt']) {
    group(language, () {
      test('has exactly the Spanish keys that are translatable', () {
        expect(all[language]!.keys.toSet(), translatable);
      });

      test('keeps the printf arguments of every string', () {
        for (final key in translatable) {
          expect(
            _formats(all[language]![key]!.value),
            _formats(es[key]!.value),
            reason: '$language "$key"',
          );
        }
      });

      test('has no empty strings', () {
        for (final entry in all[language]!.entries) {
          expect(entry.value.value.trim(), isNotEmpty, reason: '$language "${entry.key}"');
        }
      });

      test('escapes apostrophes the Android way', () {
        for (final entry in all[language]!.entries) {
          expect(
            RegExp(r"(?<!\\)'").hasMatch(entry.value.value),
            isFalse,
            reason: '$language "${entry.key}" has an unescaped apostrophe',
          );
        }
      });
    });
  }

  test('values-pt is European Portuguese: no Brazilian words', () {
    final brazilian = RegExp(
      r'(?<![\p{L}])(celular|tela|usuário|registrar|você|gastando|salvar|arquivo|deletar|baixar|aplicativo|cadastro|conta corrente|ônibus)(?![\p{L}])',
      caseSensitive: false,
      unicode: true,
    );
    for (final entry in all['pt']!.entries) {
      expect(entry.value.value, isNot(matches(brazilian)), reason: 'pt "${entry.key}"');
    }
  });

  test('Italian and Portuguese do not use the Colombian slang', () {
    final slang = RegExp(r'(?<![\p{L}])(lukas?|lucas|palos?)(?![\p{L}])', unicode: true);
    for (final language in ['it', 'pt']) {
      for (final entry in all[language]!.entries) {
        expect(entry.value.value, isNot(matches(slang)), reason: '$language "${entry.key}"');
      }
    }
  });
}
