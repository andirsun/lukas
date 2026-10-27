import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_format.dart';

// A file of its own: nothing here loads the pt_PT date data first (a test file is one isolate), so
// this is the app's path, where only the Material localizations have loaded the bare `pt`.
void main() {
  test('dateTag loads European Portuguese on first use, so formatDay works without setup', () {
    expect(dateTag('pt'), 'pt_PT');
    expect(formatDay('2026-10-21', 'pt'), 'quarta 21');
    expect(formatMonthName('2026-03', 'pt'), 'Março');
  });
}
