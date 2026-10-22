// Runs every shared quick-capture case (packages/core/quick-capture/cases.json, spec section 5.3)
// against the Dart parser. The file is read from the repo, never copied into the app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/parser/parse.dart';

/// From apps/mobile, where `flutter test` runs.
const casesPath = '../../packages/core/quick-capture/cases.json';

Kind _kind(String value) => Kind.values.byName(value);

ParseContext _context(Map<String, dynamic> c) => ParseContext(
  locale: c['locale'] as String,
  currency: c['currency'] as String,
  today: c['today'] as String,
  timeZone: c['timeZone'] as String,
  categories: [
    for (final k in c['categories'] as List)
      Category(id: k['id'] as String, name: k['name'] as String, kind: _kind(k['kind'] as String)),
  ],
  usual: [
    for (final u in c['usual'] as List)
      Usual(name: u['name'] as String, categoryId: u['categoryId'] as String),
  ],
);

Draft _draft(Map<String, dynamic> d) => Draft(
  amount: d['amount'] as int,
  kind: _kind(d['kind'] as String),
  name: d['name'] as String,
  categoryId: d['categoryId'] as String?,
  date: d['date'] as String,
);

void main() {
  final cases = (jsonDecode(File(casesPath).readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  test('the cases file is there and full', () {
    expect(cases.length, greaterThanOrEqualTo(166));
  });

  group('quick-capture cases', () {
    for (final c in cases) {
      test('${c['id']}: ${c['input']}', () {
        final expected = c['expected'] as Map<String, dynamic>;
        final result = parseSentence(c['input'] as String, _context(c));
        expect(result.drafts, [
          for (final d in expected['drafts'] as List) _draft(d as Map<String, dynamic>),
        ], reason: 'drafts');
        expect(result.unread, (expected['unread'] as List).cast<String>(), reason: 'unread');
      });
    }
  });
}
