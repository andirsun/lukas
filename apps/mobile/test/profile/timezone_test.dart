import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/profile/timezone.dart';

/// The web's `timeZoneToSave` tests (apps/web/app/features/onboarding/onboarding.test.ts), one for
/// one.
void main() {
  const supported = ['America/Bogota', 'Europe/Madrid', 'UTC'];

  group('timeZoneToSave', () {
    test("saves the device's zone while the profile still has the default", () {
      expect(timeZoneToSave('UTC', 'America/Bogota', supported), 'America/Bogota');
    });

    test('leaves a zone the person already has', () {
      expect(timeZoneToSave('Europe/Madrid', 'America/Bogota', supported), isNull);
    });

    test("ignores a zone the runtime doesn't know, a missing one, or UTC itself", () {
      expect(timeZoneToSave('UTC', 'Mars/Olympus', supported), isNull);
      expect(timeZoneToSave('UTC', null, supported), isNull);
      expect(timeZoneToSave('UTC', 'UTC', supported), isNull);
    });
  });

  test('knows the zones of the time zone database the app carries', () {
    final known = supportedTimeZones();
    expect(known.length, greaterThan(100));
    expect(known, containsAll(['America/Bogota', 'Europe/Madrid', 'UTC']));
  });
}
