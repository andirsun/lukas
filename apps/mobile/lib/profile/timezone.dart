// The time zone a new profile gets: the web's apps/web/app/features/onboarding/timezone.ts. Settings
// reuses [supportedTimeZones].
//
// The database is `latest_all`, not `latest`: `latest` leaves out the zones that are links in the tz
// database (Europe/Amsterdam is Brussels', Asia/Kuala_Lumpur is Singapore's...), and the clock
// would read UTC for a person who picked one of them, which the web's list offers.
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// What a new profile's time zone is until it is set (the API's default).
const defaultTimeZone = 'UTC';

/// The time zone to save on the profile, or null to leave it: only while the stored one is still the
/// default, and only a zone the runtime knows, so a person who chose one in settings keeps it.
/// Without it every "today" and month boundary would be UTC's: 5 hours off in Bogotá.
String? timeZoneToSave(String stored, String? device, Iterable<String> supported) {
  if (stored != defaultTimeZone || device == null || device.isEmpty || device == stored) {
    return null;
  }
  return supported.contains(device) ? device : null;
}

var _ready = false;

/// The zones the app's bundled IANA database knows (the web's `Intl.supportedValuesOf("timeZone")`).
List<String> supportedTimeZones() {
  if (!_ready) {
    tzdata.initializeTimeZones();
    _ready = true;
  }
  // The database keeps UTC apart (`tz.UTC`), where `Intl` lists it with the rest.
  return {...tz.timeZoneDatabase.locations.keys, defaultTimeZone}.toList()..sort();
}
