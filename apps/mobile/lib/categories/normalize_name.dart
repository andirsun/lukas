// How the API and the importer compare category names: the web's `normalizeName`
// (apps/web/app/features/onboarding/suggested-categories.ts).

/// The letters Unicode decomposes into a base letter and an accent (what `normalize("NFD")` and
/// dropping the combining marks does in the web), by their base letter. `ñ` is one of them: it
/// compares as `n`.
const _bases = {
  'a': 'àáâãäåāăą',
  'c': 'çćĉċč',
  'd': 'ď',
  'e': 'èéêëēĕėęě',
  'g': 'ĝğġģ',
  'h': 'ĥ',
  'i': 'ìíîïĩīĭį',
  'j': 'ĵ',
  'k': 'ķ',
  'l': 'ĺļľ',
  'n': 'ñńņň',
  'o': 'òóôõöōŏő',
  'r': 'ŕŗř',
  's': 'śŝşš',
  't': 'ţť',
  'u': 'ùúûüũūŭůűų',
  'w': 'ŵ',
  'y': 'ýÿŷ',
  'z': 'źżž',
};

final Map<int, String> _plain = {
  for (final entry in _bases.entries)
    for (final letter in entry.value.runes) letter: entry.key,
};

/// Lowercase, without accents: how the API and the importer compare category names.
String normalizeName(String name) {
  final out = StringBuffer();
  for (final rune in name.trim().toLowerCase().runes) {
    // Combining accents (a name that arrives decomposed) go too.
    if (rune >= 0x300 && rune <= 0x36F) continue;
    final plain = _plain[rune];
    out.write(plain ?? String.fromCharCode(rune));
  }
  return out.toString();
}
