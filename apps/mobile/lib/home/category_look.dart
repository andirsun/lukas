import 'dart:ui';

/// How a category looks: an emoji and a tint. Categories made in the app store the emoji as `icon`
/// and a hex color as `color`. The Budge importer stores names instead (`cart`, `orange`); this
/// maps those, so both kinds look alike. A port of the web's `categoryLook`
/// (apps/web/app/ui/category-look.ts).
class CategoryLook {
  const CategoryLook(this.glyph, this.tint);

  final String glyph;
  final Color tint;
}

const _importerGlyphs = {
  'cart': '🛒',
  'cutlery': '🍽️',
  'star': '⭐',
  'house': '🏠',
  'car': '🚗',
  'umbrella': '☂️',
  'heart': '❤️',
  'document': '🧾',
  'salary': '💰',
  'chart': '📈',
  'plane': '✈️',
  'box': '📦',
  'tag': '🏷️',
};

/// Mid-tone tints: mixed into the sunken surface, they read in night and day.
const _importerTints = {
  'orange': Color(0xFFFF9F1C),
  'red': Color(0xFFFF5C7A),
  'purple': Color(0xFFA66BFF),
  'indigo': Color(0xFF6D6BFF),
  'blue': Color(0xFF3FA7FF),
  'pink': Color(0xFFFF8FD8),
  'amber': Color(0xFFFFB547),
  'yellow': Color(0xFFFFE66D),
  'green': Color(0xFF2FD388),
  'teal': Color(0xFF2EC4B6),
  'sky': Color(0xFF5AC8FA),
  'gray': Color(0xFF8E87B8),
};

final _hex = RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

Color? _parseHex(String color) {
  final match = _hex.firstMatch(color);
  if (match == null) return null;
  var digits = match.group(1)!;
  if (digits.length == 3) digits = digits.split('').map((c) => '$c$c').join();
  // #rrggbb or #rrggbbaa (CSS puts the alpha last).
  final rgb = int.parse(digits.substring(0, 6), radix: 16);
  final alpha = digits.length == 8 ? int.parse(digits.substring(6), radix: 16) : 0xFF;
  return Color((alpha << 24) | rgb);
}

CategoryLook categoryLook({required String icon, required String color}) => CategoryLook(
  _importerGlyphs[icon] ?? icon,
  _importerTints[color] ?? _parseHex(color) ?? _importerTints['gray']!,
);

/// The name of a pickable tint (`yellow`) from its colour, or null for any other colour: a port of
/// the web's `tintName`. Charts draw a named tint with its theme token (`LukitasColors.tintYellow`),
/// which the day theme darkens so a mark keeps 3:1 against the card.
String? tintName(Color tint) {
  for (final MapEntry(:key, :value) in _importerTints.entries) {
    if (value == tint) return key;
  }
  return null;
}

/// The value stored for a pickable tint (`#ffe66d` for `yellow`): the hex the web saves as `color`
/// (`CATEGORY_TINTS`).
String categoryTintHex(String name) {
  final rgb = _importerTints[name]!.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

/// A category's tint as the web's `categoryLook(...).tint` holds it, a string: the pickable tint's
/// hex for an importer's name, the stored hex as it is (`#2FD388` stays upper case, so it matches no
/// pickable tint, as on the web), and gray for anything else.
String categoryTintValue({required String icon, required String color}) {
  final named = _importerTints[color];
  if (named != null) return categoryTintHex(color);
  if (RegExp(r'^#[0-9a-fA-F]{3,8}$').hasMatch(color)) return color;
  return categoryTintHex('gray');
}

/// Emoji a person can pick for a category: the suggestions' and a few common ones
/// (`CATEGORY_GLYPHS`).
const categoryGlyphs = [
  '🏷️',
  '🛒',
  '🍽️',
  '🏠',
  '🚗',
  '⭐',
  '☂️',
  '❤️',
  '💰',
  '🐶',
  '🎓',
  '✈️',
  '🎁',
  '👕',
  '💊',
  '📱',
  '🏋️',
  '🍺',
  '🧾',
  '📈',
];

/// The tints a person can pick for a category, by name, in the order the web lists them
/// (`CATEGORY_TINTS`).
const categoryTintNames = [
  'orange',
  'red',
  'purple',
  'indigo',
  'blue',
  'sky',
  'pink',
  'amber',
  'yellow',
  'green',
  'teal',
  'gray',
];
