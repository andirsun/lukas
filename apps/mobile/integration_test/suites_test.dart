// Every emulator suite that runs with the notification permission given, from one build of the app
// (scripts/run-integration-tests.sh): building and installing it once per file took longer than the
// tests themselves. Each file still runs on its own as before (`flutter test
// integration_test/budgets_test.dart ...`).
//
// A file used to start from a fresh install. Here each one starts from what a fresh install has: no
// session and nothing stored (everything the app keeps is in FlutterSecureStorage), and an address
// of its own for the API's per-address limit on sign-in codes, as each file had with its own build.
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lukitas/api/client.dart';

import 'add_test.dart' as add;
import 'budgets_test.dart' as budgets;
import 'capture_test.dart' as capture;
import 'categories_test.dart' as categories;
import 'delete_account_test.dart' as delete_account;
import 'entry_test.dart' as entry;
import 'export_test.dart' as export_data;
import 'feedback_test.dart' as feedback;
import 'import_test.dart' as import_budge;
import 'recurring_test.dart' as recurring;
import 'settings_test.dart' as settings;
import 'welcome_test.dart' as welcome;
import 'widget_test.dart' as widget;

final _random = Random();

/// An address in 198.18.0.0/15, the range for benchmarking (the web's e2e `clientIp`).
String _newClientIp() =>
    '198.${18 + _random.nextInt(2)}.${_random.nextInt(256)}.${1 + _random.nextInt(254)}';

void _suite(String name, void Function() tests) {
  group(name, () {
    setUpAll(() async {
      debugClientIp = _newClientIp();
      await const FlutterSecureStorage().deleteAll();
    });
    tests();
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  _suite('feedback', feedback.main);
  _suite('settings', settings.main);
  _suite('add', add.main);
  _suite('budgets', budgets.main);
  _suite('categories', categories.main);
  _suite('recurring', recurring.main);
  _suite('import', import_budge.main);
  _suite('export', export_data.main);
  _suite('delete account', delete_account.main);
  _suite('welcome', welcome.main);
  _suite('capture', capture.main);
  _suite('entry', entry.main);
  _suite('widget', widget.main);
}
