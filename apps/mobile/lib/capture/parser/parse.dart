// The on-device sentence parser (spec section 5): a transcript or typed sentence in, draft
// movements and unread fragments out. Every rule is pinned by the shared cases in
// packages/core/quick-capture (README.md and cases.json), which test/capture runs.
//
// Rules only, with no model: the voice spike chose that. A fallback small model for the unread
// fragments is described in docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md, but it
// is not built.
import 'dates.dart';
import 'match.dart';
import 'split.dart';
import 'types.dart';
import 'words.dart';

export 'types.dart';

/// Reads [text] into drafts. Nothing is dropped silently: a movement that cannot be read comes
/// back whole in [ParseResult.unread], as heard. It never throws.
ParseResult parseSentence(String text, ParseContext ctx) {
  final drafts = <Draft>[];
  final unread = <String>[];
  // The context carries over: a verb sets the kind, and a date word the date, of its movement
  // and of every later one, until another verb or date word.
  var kind = Kind.expense;
  var date = ctx.today;
  for (final movement in splitMovements(readItems(text, ctx.locale))) {
    if (movement.items.isEmpty) continue;
    final verb = movement.items.where((i) => i.type == ItemType.verb).firstOrNull;
    if (verb != null) kind = verb.income ? Kind.income : Kind.expense;
    final dateWord = movement.items.where((i) => i.type == ItemType.date).firstOrNull;
    if (dateWord != null) date = dateOf(fold(dateWord.text), ctx.today);

    final cents = _cents(movement, ctx);
    if (cents == null) {
      unread.add(text.substring(movement.items.first.start, movement.items.last.end));
      continue;
    }
    final name = _name(movement);
    drafts.add(
      Draft(
        amount: cents,
        kind: kind,
        name: name,
        categoryId: matchCategory(name, kind, ctx.usual, ctx.categories),
        date: date,
      ),
    );
  }
  return ParseResult(drafts: drafts, unread: unread);
}

/// The movement's amount in cents, or null when it has none it can use.
int? _cents(Movement movement, ParseContext ctx) {
  final amounts = movement.amounts.toList();
  // No amount, or two that are not one number and have no name between them.
  if (amounts.length != 1) return null;
  final amount = amounts.single.amount!;
  // Lukas and palos count only in COP; elsewhere the movement stays unread.
  if (amount.slang && ctx.currency != 'COP') return null;
  // COP is whole pesos: a fractional peso (`9,50`, `9.50`, `nueve con cincuenta`) is unread. A
  // decimal before a scale word comes out whole (`4,3 palos`).
  if (ctx.currency == 'COP' && !amount.value.isInteger) return null;
  // Null when ambiguous (`4,300 palos`, `12,5000`), zero, or above 999 999 999.
  return amount.cents;
}

/// The words left after the verb, the amount, the date, the function words and the articles,
/// in order, lowercase. A connector that did not split stays (`pan y leche`), except at either
/// end.
String _name(Movement movement) {
  final words = [
    for (final item in movement.items)
      if (item.type == ItemType.name || (item.type == ItemType.connector && !item.isComma)) item,
  ];
  while (words.isNotEmpty && words.first.type == ItemType.connector) {
    words.removeAt(0);
  }
  while (words.isNotEmpty && words.last.type == ItemType.connector) {
    words.removeLast();
  }
  return words.map((i) => i.text).join(' ');
}
