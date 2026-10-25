// The settings screen's rules that need no widget: confirming an account deletion by email, the name
// of an exported file, and finding and naming time zones. A port of
// apps/web/app/features/settings/settings-model.ts.
import 'package:timezone/timezone.dart' as tz;

import '../profile/timezone.dart';
import 'zone_countries.dart';

/// Whether what was typed is the account's email: case-insensitive, surrounding spaces trimmed. An
/// account with no email is matched by nothing.
bool emailMatches(String typed, String email) {
  final wanted = email.trim().toLowerCase();
  return wanted.isNotEmpty && typed.trim().toLowerCase() == wanted;
}

final _filename = RegExp(r'filename\s*=\s*(?:"([^"]*)"|([^;\s]+))', caseSensitive: false);

/// The file name a `content-disposition` header gives (`attachment; filename="x.csv"`), or
/// [fallback] when it gives none or one with a path in it.
String filenameFrom(String? disposition, String fallback) {
  final match = _filename.firstMatch(disposition ?? '');
  final name = (match?.group(1) ?? match?.group(2) ?? '').trim();
  final bad = name.isEmpty || name.contains('/') || name.contains(r'\') || name.startsWith('.');
  return bad ? fallback : name;
}

String _words(String part) => part.replaceAll('_', ' ');

/// A zone's city: `America/Argentina/Buenos_Aires` -> `Buenos Aires`; `UTC` stays `UTC`.
String zoneCity(String zone) => _words(zone.split('/').last);

/// A zone's region: `America/Argentina/Buenos_Aires` -> `America · Argentina`; none for `UTC`.
String zoneRegion(String zone) {
  final parts = zone.split('/');
  return parts.take(parts.length - 1).map(_words).join(' · ');
}

// The accents Spanish and English names carry (NFD plus "remove the marks" in the web's version).
const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y', 'ş': 's', 'š': 's', 'ž': 'z', 'ł': 'l', 'ğ': 'g',
  'ı': 'i', 'ć': 'c', 'č': 'c', 'ś': 's', 'ź': 'z', 'ż': 'z', 'ń': 'n', 'ř': 'r', 'ě': 'e',
  'ň': 'n', 'ď': 'd', 'ť': 't', 'ů': 'u', 'ă': 'a', 'ș': 's', 'ț': 't', 'ő': 'o', 'ű': 'u',
  'ę': 'e', 'ą': 'a', 'ė': 'e', 'ų': 'u', 'į': 'i', 'đ': 'd', 'ß': 'ss', 'æ': 'ae', 'œ': 'oe',
  //
};

final _separators = RegExp(r'[_/]+');
final _spaces = RegExp(r'\s+');

/// Lowercase, without accents, with `_` and `/` as spaces: "Bogotá" finds "America/Bogota".
String _normalize(String text) {
  final lower = text.toLowerCase();
  final plain = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    plain.write(_accents[char] ?? char);
  }
  return plain.toString().replaceAll(_separators, ' ').replaceAll(_spaces, ' ').trim();
}

/// Countries whose zones are better found by the names people type, in Spanish and English: the
/// web adds these where `Intl` names a zone otherwise (Spain's is "Central European Time", the
/// United States' "Eastern Time"...). The table of countries has them too; they are kept as the
/// web has them (spellings such as EEUU and USA).
const zoneAliases = <String, List<String>>{
  'Europe/Madrid': ['España', 'Spain'],
  'America/New_York': ['Estados Unidos', 'EEUU', 'EE UU', 'USA', 'United States'],
  'America/Chicago': ['Estados Unidos', 'EEUU', 'EE UU', 'USA', 'United States'],
  'America/Denver': ['Estados Unidos', 'EEUU', 'EE UU', 'USA', 'United States'],
  'America/Los_Angeles': ['Estados Unidos', 'EEUU', 'EE UU', 'USA', 'United States'],
  'America/Mexico_City': ['México', 'Mexico'],
};

/// Spellings people type for a country, beside its names: the United States by its initials.
const _countryAliases = <String, List<String>>{
  'US': ['EEUU', 'EE UU', 'USA'],
};

/// What a search matches each zone against: its id, its country's names and its aliases.
typedef ZoneSearchIndex = Map<String, String>;

final _indexes = Expando<ZoneSearchIndex>('zone search index');

/// The search text of every zone: the id, the country's name in Spanish and English (so "Colombia",
/// "Perú" or "Chile" find their zones) and the aliases above, normalized. Built once per list of
/// zones and kept.
ZoneSearchIndex zoneSearchIndex(List<String> zones) {
  final cached = _indexes[zones];
  if (cached != null) return cached;
  final index = <String, String>{
    for (final zone in zones)
      zone: _normalize(
        [zone, ..._countryText(zoneCountries[zone]), ...?zoneAliases[zone]].join(' '),
      ),
  };
  _indexes[zones] = index;
  return index;
}

List<String> _countryText(String? country) {
  if (country == null) return const [];
  final names = countryNames[country];
  return [
    if (names != null) ...[names.$1, names.$2],
    ...?_countryAliases[country],
  ];
}

/// The zones matching [query] (any part of the name, or of the zone's text in [index]; zones whose
/// city starts with it first, then the rest in their given order), at most [limit] of them, and how
/// many more matched.
({List<String> matches, int more}) searchZones(
  List<String> zones,
  String query,
  int limit, [
  ZoneSearchIndex? index,
]) {
  final wanted = _normalize(query);
  final found = [
    for (final zone in zones)
      if ((index?[zone] ?? _normalize(zone)).contains(wanted)) zone,
  ];
  bool cityStarts(String zone) => _normalize(zoneCity(zone)).startsWith(wanted);
  final cityFirst = [...found.where(cityStarts), ...found.where((zone) => !cityStarts(zone))];
  return (
    matches: cityFirst.take(limit).toList(),
    more: cityFirst.length > limit ? cityFirst.length - limit : 0,
  );
}

/// The zone's offset from UTC at [at] (`GMT-5`, `GMT+2`, `GMT+5:30`, `GMT`), or '' for a zone the
/// app does not know: what `Intl`'s `shortOffset` writes in Spanish and English.
String zoneOffset(String zone, String locale, [DateTime? at]) {
  supportedTimeZones();
  final tz.Location location;
  try {
    location = tz.getLocation(zone);
  } on Object {
    return '';
  }
  final offset = tz.TZDateTime.from(at ?? DateTime.now(), location).timeZoneOffset;
  final minutes = offset.inMinutes;
  if (minutes == 0) return 'GMT';
  final sign = minutes < 0 ? '-' : '+';
  final hours = minutes.abs() ~/ 60;
  final rest = minutes.abs() % 60;
  return rest == 0 ? 'GMT$sign$hours' : 'GMT$sign$hours:${rest.toString().padLeft(2, '0')}';
}

/// A zone in the web's spelling (ICU's, which the API stores): a phone reports IANA's current one
/// (`America/Argentina/Buenos_Aires`), the profile and the list have `America/Buenos_Aires`. A zone
/// that spells the same in both, or is not known, comes back as it is.
String canonicalZone(String zone) => icuSpellings[zone] ?? zone;

/// The zones the picker lists, in order: the 418 the web lists (`Intl.supportedValuesOf("timeZone")`,
/// by ICU's ids: no `Etc/*`, no old links, no `UTC`), that the app can also tell the time in.
List<String> pickableTimeZones() {
  final known = supportedTimeZones().toSet();
  return [
    for (final zone in zoneCountries.keys)
      if (known.contains(zone)) zone,
  ]..sort();
}
