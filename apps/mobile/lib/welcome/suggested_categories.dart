// The welcome's suggested categories: a port of
// apps/web/app/features/onboarding/suggested-categories.ts.
import '../api/gen/lukitas_api.dart';
import '../categories/normalize_name.dart';

export '../categories/normalize_name.dart' show normalizeName;

class SuggestedCategory {
  const SuggestedCategory({
    required this.key,
    required this.glyph,
    required this.tint,
    required this.kind,
    required this.names,
  });

  /// Stable id of the suggestion (not stored anywhere).
  final String key;

  /// Emoji: saved as the category's `icon`.
  final String glyph;

  /// Mid-tone colour, mixed into the tile's surface so it reads in night and day: saved as `color`.
  final String tint;
  final CategoryKindEnum kind;

  /// The category's name in each language; the person's language decides which one is created.
  final Map<String, String> names;
}

/// The welcome's suggestions (spec section 2.4). The names match the Budge import's usual
/// categories.
const suggestedCategories = [
  SuggestedCategory(
    key: 'groceries',
    glyph: '🛒',
    tint: '#ff9f1c',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Supermercado', 'en': 'Groceries', 'it': 'Supermercato', 'pt': 'Supermercado'},
  ),
  SuggestedCategory(
    key: 'eating_out',
    glyph: '🍽️',
    tint: '#ff5c7a',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Restaurante', 'en': 'Eating out', 'it': 'Ristorante', 'pt': 'Restaurante'},
  ),
  SuggestedCategory(
    key: 'home',
    glyph: '🏠',
    tint: '#6d6bff',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Casa', 'en': 'Home', 'it': 'Casa', 'pt': 'Casa'},
  ),
  SuggestedCategory(
    key: 'transport',
    glyph: '🚗',
    tint: '#3fa7ff',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Transporte', 'en': 'Transport', 'it': 'Trasporti', 'pt': 'Transportes'},
  ),
  SuggestedCategory(
    key: 'fun',
    glyph: '⭐',
    tint: '#a66bff',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Ocio', 'en': 'Fun', 'it': 'Tempo libero', 'pt': 'Lazer'},
  ),
  SuggestedCategory(
    key: 'subscriptions',
    glyph: '☂️',
    tint: '#ff8fd8',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Suscripciones', 'en': 'Subscriptions', 'it': 'Abbonamenti', 'pt': 'Subscrições'},
  ),
  SuggestedCategory(
    key: 'health',
    glyph: '❤️',
    tint: '#ffb547',
    kind: CategoryKindEnum.expense,
    names: {'es': 'Vida', 'en': 'Health', 'it': 'Salute', 'pt': 'Saúde'},
  ),
  SuggestedCategory(
    key: 'salary',
    glyph: '💰',
    tint: '#2fd388',
    kind: CategoryKindEnum.income,
    names: {'es': 'Salario', 'en': 'Salary', 'it': 'Stipendio', 'pt': 'Salário'},
  ),
];

/// The suggestion a category name stands for, in any language ("Salário" -> salary).
SuggestedCategory? suggestionFor(String name) {
  final key = normalizeName(name);
  for (final suggestion in suggestedCategories) {
    if (suggestion.names.values.any((n) => normalizeName(n) == key)) return suggestion;
  }
  return null;
}
