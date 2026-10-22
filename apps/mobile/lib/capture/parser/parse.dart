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
/// back whole in [ParseResult.unread], as heard.
ParseResult parseSentence(String text, ParseContext ctx) {
  final items = readItems(text, ctx.locale);
  final leadingDate = _leadingDate(items, ctx.today);
  final drafts = <Draft>[];
  final unread = <String>[];
  for (final movement in splitMovements(items)) {
    final draft = _draft(movement, ctx, leadingDate);
    if (draft != null) {
      drafts.add(draft);
    } else if (movement.items.isNotEmpty) {
      unread.add(text.substring(movement.items.first.start, movement.items.last.end));
    }
  }
  return ParseResult(drafts: drafts, unread: unread);
}

/// A date word at the very start (after articles and function words) covers every movement
/// that has no date of its own.
String? _leadingDate(List<Item> items, String today) {
  for (final item in items) {
    if (item.type == ItemType.dropped) continue;
    if (item.type == ItemType.date) return dateOf(fold(item.text), today);
    return null;
  }
  return null;
}

Draft? _draft(Movement movement, ParseContext ctx, String? leadingDate) {
  final amounts = movement.amounts.toList();
  // No amount, or two that are not one number and have no name between them.
  if (amounts.length != 1) return null;
  final amount = amounts.single.amount!;
  // Lukas and palos count only in COP; elsewhere the movement stays unread.
  if (amount.slang && ctx.currency != 'COP') return null;
  final cents = amount.cents;
  if (cents == null) return null;

  var kind = Kind.expense;
  String? date;
  for (final item in movement.items) {
    if (item.type == ItemType.verb) {
      kind = item.income ? Kind.income : Kind.expense;
      break;
    }
  }
  for (final item in movement.items) {
    if (item.type == ItemType.date) {
      date = dateOf(fold(item.text), ctx.today);
      break;
    }
  }
  final name = _name(movement);
  return Draft(
    amount: cents,
    kind: kind,
    name: name,
    categoryId: matchCategory(name, ctx.usual, ctx.categories),
    date: date ?? leadingDate ?? ctx.today,
  );
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
