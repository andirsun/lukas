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
