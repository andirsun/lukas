import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/l10n/app_localizations.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

/// The message keys of an ARB catalog: everything but `@@locale` and `@key` metadata.
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

/// The argument names an ICU message uses: `{name}`, and the `{count, plural, …}` and
/// `{x, select, …}` variables, at any depth. Branch bodies such as `=1{…}` are not arguments.
Set<String> _arguments(String message) {
  final names = <String>{};
  var i = 0;

  void skipSpaces() {
    while (i < message.length && message[i].trim().isEmpty) {
      i++;
    }
  }

  String readUntil(Set<String> stops) {
    final start = i;
    while (i < message.length && !stops.contains(message[i])) {
      i++;
    }
    return message.substring(start, i).trim();
  }

  // Reads plain text and arguments until an unmatched `}` (or the end), which it leaves unread.
  void text() {
    while (i < message.length && message[i] != '}') {
      if (message[i] != '{') {
        i++;
        continue;
      }
      i++; // {
      final name = readUntil({',', '}'});
      names.add(name);
      if (i < message.length && message[i] == ',') {
        i++; // ,
        final type = readUntil({',', '}'});
        if ((type == 'plural' || type == 'select') && message[i] == ',') {
          i++; // ,
          skipSpaces();
          while (i < message.length && message[i] != '}') {
            readUntil({'{'}); // the selector: =0, one, other, a select value
            i++; // {
            text();
            i++; // }
            skipSpaces();
          }
        }
      }
      i++; // } closing the argument
    }
  }

  text();
  return names;
}

void main() {
  final es = _arb('es');
  final en = _arb('en');

  test('ARB parity: es and en have the same keys', () {
    expect(_messageKeys(en), _messageKeys(es));
  });

  test('ARB parity: es and en have the same placeholders', () {
    for (final key in _messageKeys(es)) {
      final declared =
          ((es['@$key'] as Map<String, dynamic>?)?['placeholders'] as Map<String, dynamic>?)?.keys
              .toSet() ??
          <String>{};
      expect(_arguments(es[key] as String), declared, reason: 'es "$key" vs its @$key metadata');
      expect(_arguments(en[key] as String), declared, reason: 'en "$key" vs the es template');
    }
  });

  test('the ICU argument reader ignores plural branch bodies', () {
    expect(
      _arguments('{count, plural, =0{Nada} =1{Uno en {category}} other{{count} en {category}}}'),
      {'count', 'category'},
    );
  });

  testWidgets('plurals and placeholders render in es and en', (tester) async {
    late AppLocalizations esL10n;
    late AppLocalizations enL10n;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('es'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            esL10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            enL10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(esL10n.appName, 'Lukitas');
    expect(esL10n.savedMovements(1, 'Mercado'), 'Guardaste 1 movimiento en Mercado');
    expect(esL10n.savedMovements(3, 'Mercado'), 'Guardaste 3 movimientos en Mercado');
    expect(enL10n.savedMovements(1, 'Mercado'), 'You saved 1 movement in Mercado');
    expect(enL10n.savedMovements(3, 'Mercado'), 'You saved 3 movements in Mercado');
  });
}
