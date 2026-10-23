import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../parser/amounts.dart' show Dec, maxAmountUnits, readAmountText;
import '../parser/parse.dart';

/// One movement in the preview, as the person may still change it.
@immutable
class CaptureCard {
  const CaptureCard({
    required this.id,
    required this.amount,
    required this.kind,
    required this.name,
    required this.categoryId,
    required this.date,
  });

  /// Stays the same through edits (widget keys).
  final int id;

  /// Positive cents; null while a fragment completed by hand has no amount yet.
  final int? amount;
  final Kind kind;

  /// As heard (lowercase), or as typed.
  final String name;
  final String? categoryId;

  /// `YYYY-MM-DD`.
  final String date;

  bool get complete => (amount ?? 0) > 0 && categoryId != null;

  CaptureCard copyWith({
    int? Function()? amount,
    Kind? kind,
    String? name,
    String? Function()? categoryId,
    String? date,
  }) => CaptureCard(
    id: id,
    amount: amount == null ? this.amount : amount(),
    kind: kind ?? this.kind,
    name: name ?? this.name,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    date: date ?? this.date,
  );
}

/// The preview of a sentence (spec section 6.1.4): one editable, removable card per draft, and the
/// fragments the parser could not read, which can each become a card completed by hand.
class CapturePreview extends ChangeNotifier {
  CapturePreview({required this.today});

  /// Today in the profile's time zone: the date of a card made from a fragment.
  final String today;

  var _cards = <CaptureCard>[];
  var _unread = <String>[];
  var _sentence = '';
  var _nextId = 0;

  List<CaptureCard> get cards => List.unmodifiable(_cards);
  List<String> get unread => List.unmodifiable(_unread);

  /// The sentence the cards come from, as heard or typed.
  String get sentence => _sentence;

  /// GUARDAR can be pressed: at least one card, and every card has an amount and a category.
  bool get ready => _cards.isNotEmpty && _cards.every((c) => c.complete);

  /// The cards' amounts added up, in cents.
  int get total => _cards.fold(0, (sum, c) => sum + (c.amount ?? 0));

  void _changed() => notifyListeners();

  /// Shows what [sentence] was read as, replacing what was there.
  void read(String sentence, ParseResult result) {
    _sentence = sentence;
    _cards = [
      for (final d in result.drafts)
        CaptureCard(
          id: _nextId++,
          amount: d.amount,
          kind: d.kind,
          name: d.name,
          categoryId: d.categoryId,
          date: d.date,
        ),
    ];
    _unread = [...result.unread];
    _changed();
  }

  /// Turns the unread fragment at [index] into a card, named after it, to complete by hand.
  void complete(int index) {
    if (index < 0 || index >= _unread.length) return;
    final fragment = _unread.removeAt(index);
    _cards = [
      ..._cards,
      CaptureCard(
        id: _nextId++,
        amount: null,
        kind: Kind.expense,
        name: fragment.toLowerCase(),
        categoryId: null,
        date: today,
      ),
    ];
    _changed();
  }

  void remove(int id) {
    _cards = [
      for (final c in _cards)
        if (c.id != id) c,
    ];
    _changed();
  }

  /// Changes the card [id]. A new [kind] drops its category, which belonged to the other kind,
  /// unless a [categoryId] comes with it.
  void update(int id, {int? amount, Kind? kind, String? name, String? categoryId, String? date}) {
    _cards = [
      for (final c in _cards)
        if (c.id != id)
          c
        else
          c.copyWith(
            amount: amount == null ? null : () => amount,
            kind: kind,
            name: name,
            categoryId: categoryId != null
                ? () => categoryId
                : (kind != null && kind != c.kind ? () => null : null),
            date: date,
          ),
    ];
    _changed();
  }

  /// The cards as drafts to save (only when [ready]): a name starts with a capital letter, and an
  /// empty one is the category's name, as in the add sheet.
  List<Draft> drafts({required String Function(String categoryId) categoryName}) => [
    for (final c in _cards)
      Draft(
        amount: c.amount!,
        kind: c.kind,
        name: savedName(c.name, categoryName(c.categoryId!)),
        categoryId: c.categoryId,
        date: c.date,
      ),
  ];
}

/// [name] trimmed with a capital first letter, or [fallback] when it is empty.
String savedName(String name, String fallback) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

/// What a batch of [drafts] would send, as one string: the same drafts give the same string, so a
/// save attempt's Idempotency-Key is kept for exactly the same request body (Reintentar, or a
/// change that changes nothing), and a new one is made for any other.
String batchFingerprint(List<Draft> drafts) => jsonEncode([
  for (final d in drafts) [d.amount, d.kind.name, d.name, d.categoryId, d.date],
]);

/// An amount typed by hand on a card, in cents, read by the sentence parser's own number rule
/// (packages/core/quick-capture/README.md), the same in every locale: a dot or comma before exactly
/// three digits groups thousands (`12.345`, `1,234.50`), and before one or two digits it is the
/// decimal, whichever mark it is (`12.5` and `12,5` are both 12,50). COP is whole pesos. Never a
/// double. Anything else, zero, or above the parser's cap is 0: no amount yet.
int parseCardAmount(String text, {required String currency, required String locale}) {
  final trimmed = text.trim();
  // Digits and separators only: the field takes nothing else, and words are the sentence's job.
  if (!RegExp(r'^\d[\d.,]*$').hasMatch(trimmed)) return 0;
  final value = readAmountText(trimmed, locale == 'en' ? 'en' : 'es');
  if (value == null || value.compareTo(Dec.zero) <= 0) return 0;
  if (value.compareTo(Dec(maxAmountUnits)) > 0) return 0;
  if (currency == 'COP' && !value.isInteger) return 0;
  return value.cents;
}

/// [cents] as a card's amount field shows it, ready to be changed: no grouping, the locale's
/// decimal mark, cents only when there are some (and never in COP).
String cardAmountText(int? cents, {required String currency, required String locale}) {
  if (cents == null || cents <= 0) return '';
  final whole = '${cents ~/ 100}';
  final rest = cents % 100;
  if (currency == 'COP' || rest == 0) return whole;
  return '$whole${locale == 'en' ? '.' : ','}${rest.toString().padLeft(2, '0')}';
}
