// Reading a sentence into items (amounts, verbs, dates, connectors, names) and splitting them
// into movements (packages/core/quick-capture/README.md, "Splitting").
import 'amounts.dart';
import 'dates.dart';
import 'words.dart';

enum ItemType { amount, verb, date, connector, dropped, name }

/// One piece of the sentence: an amount (possibly several tokens), a verb (possibly two words),
/// or a single word or comma.
class Item {
  Item(this.type, this.start, this.end, this.text, {this.amount, this.income = false});

  final ItemType type;

  /// Offsets in the sentence.
  final int start;
  final int end;

  /// For a word: lowercase, accents kept. For a comma: `,`.
  final String text;

  final AmountMatch? amount;

  /// For a verb: whether it brings money in.
  final bool income;

  bool get isComma => text == ',';

  @override
  String toString() => '${type.name}($text)';
}

/// The items of [text], in order.
List<Item> readItems(String text, String locale) {
  final tokens = tokenize(text, locale);
  final items = <Item>[];
  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t.isComma) {
      items.add(Item(ItemType.connector, t.start, t.end, ','));
      i++;
      continue;
    }
    final amount = readAmount(tokens, i, locale);
    if (amount != null) {
      final last = tokens[amount.end - 1];
      items.add(
        Item(ItemType.amount, t.start, last.end, text.substring(t.start, last.end), amount: amount),
      );
      i = amount.end;
      continue;
    }
    final verb = _verbAt(tokens, i, locale);
    if (verb != null) {
      final (length, income) = verb;
      final last = tokens[i + length - 1];
      items.add(
        Item(
          ItemType.verb,
          t.start,
          last.end,
          text.substring(t.start, last.end).toLowerCase(),
          income: income,
        ),
      );
      i += length;
      continue;
    }
    final date = dateAt(tokens, i, locale);
    if (date != null) {
      final (length, key) = date;
      items.add(Item(ItemType.date, t.start, tokens[i + length - 1].end, key));
      i += length;
      continue;
    }
    final type = connectorsFor(locale).contains(t.norm)
        ? ItemType.connector
        : droppedFor(locale).contains(t.norm)
        ? ItemType.dropped
        : ItemType.name;
    items.add(Item(type, t.start, t.end, t.lower));
    i++;
  }
  return items;
}

(int, bool)? _verbAt(List<Token> tokens, int i, String locale) {
  for (final (words, income) in verbsFor(locale)) {
    if (i + words.length > tokens.length) continue;
    var all = true;
    for (var k = 0; k < words.length; k++) {
      final t = tokens[i + k];
      if (t.isNumber || t.isComma || t.norm != words[k]) {
        all = false;
        break;
      }
    }
    if (all) return (words.length, income);
  }
  return null;
}

/// The items of one movement, without the connector that split it from the one before.
class Movement {
  Movement([List<Item>? items]) : items = items ?? [];

  final List<Item> items;

  Iterable<Item> get amounts => items.where((i) => i.type == ItemType.amount);
  bool get hasAmount => items.any((i) => i.type == ItemType.amount);
  bool get hasName => items.any((i) => i.type == ItemType.name);

  /// Whether a name comes before the first amount (`taxi doce mil`).
  bool get hasNameBeforeAmount {
    for (final i in items) {
      if (i.type == ItemType.amount) return false;
      if (i.type == ItemType.name) return true;
    }
    return false;
  }

  @override
  String toString() => items.join(' ');
}

/// Groups [items] into movements:
/// - a connector splits only when the movement so far has an amount and the text after the
///   connector (up to the next connector) has one;
/// - with no connector, an amount that follows a movement holding an amount and a name starts a
///   new movement. The words between the two amounts go to the earlier movement when it has no
///   name before its amount, else to the later one; from a verb or date word on, they always go
///   to the later one.
List<Movement> splitMovements(List<Item> items) {
  final movements = <Movement>[];
  var current = Movement();
  for (var idx = 0; idx < items.length; idx++) {
    final item = items[idx];
    if (item.type == ItemType.connector) {
      if (current.hasAmount && _amountAfter(items, idx)) {
        movements.add(current);
        current = Movement();
      } else {
        current.items.add(item);
      }
      continue;
    }
    if (item.type == ItemType.amount && current.hasAmount && current.hasName) {
      final lastAmount = current.items.lastIndexWhere((i) => i.type == ItemType.amount);
      var cut = lastAmount + 1;
      if (!current.hasNameBeforeAmount) {
        cut = current.items.length;
        for (var k = lastAmount + 1; k < current.items.length; k++) {
          final type = current.items[k].type;
          if (type == ItemType.verb || type == ItemType.date) {
            cut = k;
            break;
          }
        }
      }
      final middle = current.items.sublist(cut);
      current.items.removeRange(cut, current.items.length);
      movements.add(current);
      current = Movement([...middle]);
    }
    current.items.add(item);
  }
  if (current.items.isNotEmpty) movements.add(current);
  return movements;
}

/// Whether an amount comes after the connector at [idx], before the next connector.
bool _amountAfter(List<Item> items, int idx) {
  for (var k = idx + 1; k < items.length; k++) {
    if (items[k].type == ItemType.connector) return false;
    if (items[k].type == ItemType.amount) return true;
  }
  return false;
}
