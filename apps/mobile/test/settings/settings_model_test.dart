// The ported tests of apps/web/app/features/settings/settings-model.test.ts: the account deletion's
// email, the export's file name and the zones.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/parser/dates.dart';
import 'package:lukitas/profile/timezone.dart';
import 'package:lukitas/settings/settings_model.dart';

void main() {
  linkZonesTest();
  icuSpellingsTest();
  group('emailMatches', () {
    test('accepts the exact email, ignoring case and surrounding spaces', () {
      expect(emailMatches('ana@example.com', 'ana@example.com'), isTrue);
      expect(emailMatches('  ANA@Example.com ', 'ana@example.com'), isTrue);
      expect(emailMatches('ana@example.com', 'Ana@Example.COM'), isTrue);
    });

    test('refuses anything else', () {
      expect(emailMatches('', 'ana@example.com'), isFalse);
      expect(emailMatches('ana@example.co', 'ana@example.com'), isFalse);
      expect(emailMatches('ana @example.com', 'ana@example.com'), isFalse);
      expect(emailMatches('ana@example.com.', 'ana@example.com'), isFalse);
    });

    test('an account with no email is never matched, not even by nothing', () {
      expect(emailMatches('', ''), isFalse);
      expect(emailMatches('  ', '  '), isFalse);
    });
  });

  group('filenameFrom', () {
    test('reads the quoted or bare filename of a content-disposition', () {
      expect(
        filenameFrom('attachment; filename="lukas-export-2026-10-22.csv"', 'x'),
        'lukas-export-2026-10-22.csv',
      );
      expect(filenameFrom('attachment; filename=lukas.json', 'x'), 'lukas.json');
    });

    test('falls back when there is none, or it carries a path', () {
      expect(filenameFrom(null, 'lukas-export.json'), 'lukas-export.json');
      expect(filenameFrom('attachment', 'lukas-export.json'), 'lukas-export.json');
      expect(
        filenameFrom('attachment; filename="../x.csv"', 'lukas-export.csv'),
        'lukas-export.csv',
      );
    });

    test('also falls back for a name that starts with a dot or has a backslash', () {
      expect(filenameFrom('attachment; filename=".bashrc"', 'a.json'), 'a.json');
      expect(filenameFrom(r'attachment; filename="..\x.csv"', 'a.csv'), 'a.csv');
    });
  });
  group('zones', () {
    const zones = [
      'America/Argentina/Buenos_Aires',
      'America/Bogota',
      'America/New_York',
      'Europe/Madrid',
      'Europe/Lisbon',
      'UTC',
    ];

    test('names a zone by its city and region', () {
      expect(zoneCity('America/Argentina/Buenos_Aires'), 'Buenos Aires');
      expect(zoneRegion('America/Argentina/Buenos_Aires'), 'America · Argentina');
      expect(zoneCity('UTC'), 'UTC');
      expect(zoneRegion('UTC'), '');
    });

    test('finds zones by any part of their name, without accents, case or underscores', () {
      final bogota = searchZones(zones, 'bogotá', 10);
      expect(bogota.matches, ['America/Bogota']);
      expect(bogota.more, 0);
      expect(searchZones(zones, 'NEW YORK', 10).matches, ['America/New_York']);
      expect(searchZones(zones, 'buenos_aires', 10).matches, ['America/Argentina/Buenos_Aires']);
      expect(searchZones(zones, 'europe', 10).matches, ['Europe/Madrid', 'Europe/Lisbon']);
    });

    test('puts zones whose city starts with the query first, and caps the list', () {
      expect(searchZones(zones, 'a', 10).matches.take(1), ['America/Argentina/Buenos_Aires']);
      final capped = searchZones(zones, '', 2);
      expect(capped.matches, ['America/Argentina/Buenos_Aires', 'America/Bogota']);
      expect(capped.more, 4);
      expect(searchZones(zones, 'lis', 10).matches, ['Europe/Lisbon']);
    });

    test('writes the zone\'s offset from UTC at a given moment', () {
      final october = DateTime.utc(2026, 10, 22, 12);
      expect(zoneOffset('America/Bogota', 'es', october), 'GMT-5');
      expect(zoneOffset('Europe/Madrid', 'en', october), 'GMT+2');
      expect(zoneOffset('UTC', 'es', october), matches(RegExp(r'^GMT(\+0)?$')));
      expect(zoneOffset('Not/AZone', 'es', october), '');
      // Half hours keep their minutes, as Intl's shortOffset writes them.
      expect(zoneOffset('Asia/Kolkata', 'en', october), 'GMT+5:30');
    });
  });

  group('finding zones by country', () {
    final zones = pickableTimeZones();
    final index = zoneSearchIndex(zones);
    List<String> find(String query) => searchZones(zones, query, 50, index).matches;

    test('matches the country\'s name in Spanish or English, without accents', () {
      expect(find('Colombia'), contains('America/Bogota'));
      expect(find('perú'), contains('America/Lima'));
      expect(find('peru'), contains('America/Lima'));
      expect(find('Chile'), contains('America/Santiago'));
    });

    test('knows the countries Intl names otherwise', () {
      expect(find('España'), contains('Europe/Madrid'));
      expect(find('spain'), contains('Europe/Madrid'));
      for (final query in ['Estados Unidos', 'USA']) {
        expect(
          find(query),
          containsAll([
            'America/New_York',
            'America/Chicago',
            'America/Denver',
            'America/Los_Angeles',
          ]),
        );
      }
      expect(find('mexico'), contains('America/Mexico_City'));
    });

    test('still finds by city first, and is built once per list', () {
      expect(find('bogo'), ['America/Bogota']);
      expect(identical(zoneSearchIndex(zones), index), isTrue);
    });
  });

  group('the zones the picker lists', () {
    test(
      'are the tz database\'s zones with a country, as Intl lists them (no Etc/*, no links)',
      () {
        final zones = pickableTimeZones();
        expect(zones, contains('America/Bogota'));
        expect(zones, contains('Europe/Madrid'));
        expect(zones.where((zone) => zone.startsWith('Etc/')), isEmpty);
        expect(zones, isNot(contains('US/Eastern')));
        expect(zones, isNot(contains('UTC')));
        expect(zones.length, greaterThan(380));
        expect(zones, orderedEquals([...zones]..sort()));
        // Every one is a zone the app can tell the time in.
        final known = supportedTimeZones().toSet();
        expect(zones.where((zone) => !known.contains(zone)), isEmpty);
      },
    );
  });
}

/// A zone the picker lists must be one "today" can be read in: the old links (Amsterdam is
/// Brussels' link in the tz database) were missing from the app's bundled database, and `todayIn`
/// would have fallen back to UTC for a person who picked it.
void linkZonesTest() {
  group('every zone the picker lists is one the clock reads', () {
    test('Amsterdam, Oslo, Kuala Lumpur and Accra, which are links, keep their own time', () {
      // 22:30 UTC on the 21st is already the 22nd in Amsterdam (UTC+2) and Kuala Lumpur (UTC+8).
      final late = DateTime.utc(2026, 10, 21, 22, 30);
      expect(todayIn('Europe/Amsterdam', late), '2026-10-22');
      expect(todayIn('Europe/Oslo', late), '2026-10-22');
      expect(todayIn('Asia/Kuala_Lumpur', late), '2026-10-22');
      expect(todayIn('Africa/Accra', late), '2026-10-21');
    });

    test('and so is every one of them', () {
      final unknown = [
        for (final zone in pickableTimeZones())
          if (!supportedTimeZones().contains(zone)) zone,
      ];
      expect(unknown, isEmpty);
      expect(pickableTimeZones(), contains('Europe/Amsterdam'));
    });
  });
}

/// The ids the web offers are ICU's spellings (`Intl.supportedValuesOf("timeZone")`), and the server
/// stores a new profile's zone in ICU's spelling too (`canonicalTimeZone` in apps/api/src/auth.ts);
/// a phone reports the current IANA one. The two meet in [canonicalZone].
const _icuSpellings = {
  'America/Argentina/Buenos_Aires': 'America/Buenos_Aires',
  'America/Argentina/Catamarca': 'America/Catamarca',
  'America/Argentina/Cordoba': 'America/Cordoba',
  'America/Argentina/Jujuy': 'America/Jujuy',
  'America/Argentina/Mendoza': 'America/Mendoza',
  'America/Atikokan': 'America/Coral_Harbour',
  'America/Indiana/Indianapolis': 'America/Indianapolis',
  'America/Kentucky/Louisville': 'America/Louisville',
  'America/Nuuk': 'America/Godthab',
  'Africa/Asmara': 'Africa/Asmera',
  'Asia/Ho_Chi_Minh': 'Asia/Saigon',
  'Asia/Kathmandu': 'Asia/Katmandu',
  'Asia/Kolkata': 'Asia/Calcutta',
  'Asia/Yangon': 'Asia/Rangoon',
  'Atlantic/Faroe': 'Atlantic/Faeroe',
  'Europe/Kyiv': 'Europe/Kiev',
  'Pacific/Chuuk': 'Pacific/Truk',
  'Pacific/Kanton': 'Pacific/Enderbury',
  'Pacific/Pohnpei': 'Pacific/Ponape',
};

void icuSpellingsTest() {
  group('the zone ids are the web\'s', () {
    test('418 of them, in ICU\'s spelling, as Intl.supportedValuesOf lists them', () {
      final zones = pickableTimeZones();
      expect(zones, hasLength(418));
      for (final entry in _icuSpellings.entries) {
        expect(zones, contains(entry.value), reason: 'the web lists ${entry.value}');
        expect(zones, isNot(contains(entry.key)), reason: '${entry.key} is IANA\'s spelling');
      }
    });

    test('every one is a zone the clock reads (all are in the bundled database)', () {
      final known = supportedTimeZones().toSet();
      expect(pickableTimeZones().where((zone) => !known.contains(zone)), isEmpty);
    });

    test('a phone\'s IANA spelling is turned into the web\'s, and the web\'s stays', () {
      for (final entry in _icuSpellings.entries) {
        expect(canonicalZone(entry.key), entry.value);
        expect(canonicalZone(entry.value), entry.value);
      }
      expect(canonicalZone('America/Bogota'), 'America/Bogota');
      expect(canonicalZone('UTC'), 'UTC');
      expect(canonicalZone('Not/AZone'), 'Not/AZone');
    });

    test('an Argentine zone is found by its country, in either spelling of the id', () {
      final zones = pickableTimeZones();
      final index = zoneSearchIndex(zones);
      expect(searchZones(zones, 'argentina', 50, index).matches, contains('America/Buenos_Aires'));
    });
  });
}
