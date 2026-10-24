// What the web's category form and sheets decide, apart from how they look
// (apps/web/app/features/categories/CategoryForm.tsx and use-category-sheets.tsx).
import '../api/gen/lukitas_api.dart';
import '../home/category_look.dart';

/// What the category sheet holds and saves: the web's `NewCategory`.
class NewCategory {
  const NewCategory({
    required this.name,
    required this.glyph,
    required this.tint,
    required this.kind,
  });

  /// The form of a category that is not made yet: no name, the first emoji and tint, spending
  /// (the web's `DEFAULT`).
  factory NewCategory.blank() => NewCategory(
    name: '',
    glyph: categoryGlyphs.first,
    tint: categoryTintHex(categoryTintNames.first),
    kind: CategoryKindEnum.expense,
  );

  /// The form of an existing category, as the web's `useCategorySheets` fills it: its name, its
  /// look (importer names become an emoji and a hex), and its kind.
  factory NewCategory.of(Category category) => NewCategory(
    name: category.name,
    glyph: categoryLook(icon: category.icon, color: category.color).glyph,
    tint: categoryTintValue(icon: category.icon, color: category.color),
    kind: category.kind,
  );

  final String name;

  /// An emoji, saved as the category's `icon`.
  final String glyph;

  /// A hex colour, saved as `color`.
  final String tint;
  final CategoryKindEnum kind;

  NewCategory copyWith({String? name, String? glyph, String? tint, CategoryKindEnum? kind}) =>
      NewCategory(
        name: name ?? this.name,
        glyph: glyph ?? this.glyph,
        tint: tint ?? this.tint,
        kind: kind ?? this.kind,
      );
}

/// The longest name a category has (the web's input `maxLength`).
const categoryNameMaxLength = 40;

/// The emoji to offer: the category's own first (even when it is none of the common ones), then the
/// common ones, each once.
List<String> glyphChoices(String current) => {current, ...categoryGlyphs}.toList();

/// The rules archiving a category stops: its own, not ended before [today] (`YYYY-MM-DD`): the
/// API's rule, which `PATCH /v1/categories/{id}` applies when it archives.
int activeRecurrencesIn(Iterable<Recurrence> rules, String categoryId, String today) => rules
    .where(
      (rule) =>
          rule.categoryId == categoryId &&
          (rule.endDate == null || rule.endDate!.compareTo(today) >= 0),
    )
    .length;
