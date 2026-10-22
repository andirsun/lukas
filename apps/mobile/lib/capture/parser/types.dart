// The parser's input and output (spec section 5.1). Pure Dart: no Flutter import anywhere under
// lib/capture/parser, so the parser runs in plain tests and can move to a shared package.

/// Whether a movement takes money out or brings it in.
enum Kind { expense, income }

/// One of the person's categories.
class Category {
  const Category({required this.id, required this.name, required this.kind});

  final String id;
  final String name;
  final Kind kind;
}

/// A name and its usual category, as `GET /v1/transactions/suggestions` returns them.
class Usual {
  const Usual({required this.name, required this.categoryId});

  final String name;
  final String categoryId;
}

/// What the parser knows besides the sentence.
class ParseContext {
  const ParseContext({
    required this.locale,
    required this.currency,
    required this.today,
    required this.timeZone,
    this.categories = const [],
    this.usual = const [],
  });

  /// `es` or `en`.
  final String locale;

  /// The account currency, ISO 4217 (`COP`, `EUR`, `USD`).
  final String currency;

  /// Today in [timeZone], `YYYY-MM-DD` (see `todayIn` in dates.dart). The parser never reads the
  /// clock.
  final String today;

  /// The profile's IANA time zone, where [today] was computed.
  final String timeZone;

  final List<Category> categories;
  final List<Usual> usual;
}

/// One movement read from the sentence, to show in the preview before anything is saved.
class Draft {
  const Draft({
    required this.amount,
    required this.kind,
    required this.name,
    required this.categoryId,
    required this.date,
  });

  /// Integer cents (x100 in every currency).
  final int amount;
  final Kind kind;

  /// Lowercase, in the spoken spelling; may be empty.
  final String name;
  final String? categoryId;

  /// `YYYY-MM-DD`.
  final String date;

  @override
  bool operator ==(Object other) =>
      other is Draft &&
      other.amount == amount &&
      other.kind == kind &&
      other.name == name &&
      other.categoryId == categoryId &&
      other.date == date;

  @override
  int get hashCode => Object.hash(amount, kind, name, categoryId, date);

  @override
  String toString() =>
      'Draft(amount: $amount, kind: ${kind.name}, name: "$name", categoryId: $categoryId, '
      'date: $date)';
}

/// The drafts, plus the fragments that could not be read (never dropped silently).
class ParseResult {
  const ParseResult({required this.drafts, required this.unread});

  final List<Draft> drafts;

  /// Fragments as heard: original case and spelling, without the connector that separated them.
  final List<String> unread;
}
