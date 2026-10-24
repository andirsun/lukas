// The categories step's chips: a port of apps/web/app/features/onboarding/category-chips.ts.
import '../api/gen/lukitas_api.dart';
import '../home/category_look.dart';
import 'suggested_categories.dart';

enum ChipSource { category, suggestion }

/// A chip in the categories step: one of the person's categories, or a suggestion not made yet.
class CategoryChipModel {
  const CategoryChipModel({
    required this.id,
    required this.source,
    required this.name,
    required this.glyph,
    required this.tint,
    required this.kind,
    this.suggestionKey,
  });

  /// The category's id, or `s:<key>` for a suggestion.
  final String id;
  final ChipSource source;
  final String name;
  final String glyph;

  /// A hex colour (an importer's colour name is turned into its hex).
  final String tint;
  final CategoryKindEnum kind;

  /// For a suggestion: its key.
  final String? suggestionKey;
}

String suggestionChipId(String key) => 's:$key';

/// The categories step's chips, in order: the person's active categories first (after an import,
/// the file's), then the suggestions none of them covers yet. Names are compared without case or
/// accents, in either language, so an imported "supermercado" or "Groceries" covers "Supermercado"
/// and no duplicate shows. Archived categories don't count: their suggestion can come back.
List<CategoryChipModel> categoryChips(Iterable<Category> categories, String locale) {
  final active = categories.where((c) => !c.archived).toList();
  final own = [
    for (final c in active)
      CategoryChipModel(
        id: c.id,
        source: ChipSource.category,
        name: c.name,
        kind: c.kind,
        glyph: categoryLook(icon: c.icon, color: c.color).glyph,
        tint: categoryTintValue(icon: c.icon, color: c.color),
      ),
  ];
  final names = {for (final c in active) normalizeName(c.name)};
  final covered = {
    for (final c in active)
      if (suggestionFor(c.name) case final s?) s.key,
  };
  final suggested = [
    for (final s in suggestedCategories)
      if (!covered.contains(s.key) && !names.contains(normalizeName(s.names[locale] ?? '')))
        CategoryChipModel(
          id: suggestionChipId(s.key),
          source: ChipSource.suggestion,
          name: s.names[locale] ?? s.names['es']!,
          glyph: s.glyph,
          tint: s.tint,
          kind: s.kind,
          suggestionKey: s.key,
        ),
  ];
  return [...own, ...suggested];
}
