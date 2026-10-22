import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../api/gen/lukitas_api.dart';
import '../money/format.dart';

/// The key the home snapshot is stored under (see [writeWidgetSnapshot]).
const widgetSnapshotKey = 'lukitas.widget.snapshot';

/// Where the snapshot is kept. The app stores it with `home_widget`, which writes Android's
/// SharedPreferences; tests replace it.
abstract interface class WidgetStore {
  Future<void> save(String key, String value);

  /// Forgets [key].
  Future<void> clear(String key);
}

/// Where the snapshot is kept (replaced in tests).
final widgetStoreProvider = Provider<WidgetStore>((ref) => const HomeWidgetStore());

/// [WidgetStore] over `home_widget` (BSD-3, AndroidX only: no Google Play Services).
///
/// It stores the value and nothing else. Asking Android to redraw the widget
/// (`HomeWidget.updateWidget`) needs the widget's receiver class, which Task 15 adds with the
/// Kotlin widget: that is where the call goes.
class HomeWidgetStore implements WidgetStore {
  const HomeWidgetStore();

  @override
  Future<void> save(String key, String value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<void> clear(String key) async {
    await HomeWidget.saveWidgetData<String>(key, null);
  }
}

/// Writes what the home-screen widget shows (spec section 7.1), so the Kotlin widget (Jetpack
/// Glance, Task 15) reads it without starting Flutter.
///
/// **Where.** One JSON string under the key [widgetSnapshotKey] (`lukitas.widget.snapshot`) in the
/// Android SharedPreferences file `HomeWidgetPreferences`, which is where `home_widget` keeps its
/// values:
///
/// ```kotlin
/// val json = context
///     .getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
///     .getString("lukitas.widget.snapshot", null)   // null: nothing written yet (signed out)
/// ```
///
/// **Shape**, version 1 (a reader ignores unknown fields and shows "Abre Lukitas para empezar"
/// for a `v` it does not know):
///
/// ```json
/// {
///   "v": 1,
///   "kind": "remaining",          // "remaining" (Te quedan) | "over" (Te pasaste) | "spent" (Gastado este mes, no budgets)
///   "amount": "$1.500.000",       // already formatted in the person's currency and language; never negative
///   "currency": "COP",
///   "month": "2026-10",           // the month of the figures
///   "progress": 0.25,             // spent / budget total, 0 to 1 (null when "spent")
///   "mood": "happy",              // Lukitas' face: "happy" | "worried" (a category is near or over its limit)
///   "updatedAt": "2026-10-22T15:30:00.000Z"   // UTC, when the app last got these figures
/// }
/// ```
///
/// The labels ("Te quedan", "Gastado este mes") are the widget's own resources, chosen by [kind];
/// the "••••" privacy setting replaces [amount] when it is drawn. A write that cannot happen
/// (no plugin, a storage error) is ignored: the widget just keeps its last figure.
Future<void> writeWidgetSnapshot(
  Summary summary, {
  required String currency,
  required String locale,
  WidgetStore store = const HomeWidgetStore(),
  DateTime? now,
}) async {
  final hasBudget = summary.budgetTotal > 0;
  final kind = !hasBudget
      ? 'spent'
      : summary.remaining < 0
      ? 'over'
      : 'remaining';
  final cents = hasBudget ? summary.remaining.abs() : summary.spent;
  final worried = summary.categories.any((c) => c.state != SummaryCategoriesInnerStateEnum.ok);
  final snapshot = <String, Object?>{
    'v': 1,
    'kind': kind,
    'amount': formatMoney(cents, currency, locale),
    'currency': currency,
    'month': summary.month,
    'progress': hasBudget ? (summary.spent / summary.budgetTotal).clamp(0.0, 1.0) : null,
    'mood': worried ? 'worried' : 'happy',
    'updatedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
  };
  try {
    await store.save(widgetSnapshotKey, jsonEncode(snapshot));
  } on MissingPluginException {
    // No plugin (tests, a desktop run): nothing to update.
  } on PlatformException {
    // The widget keeps its last figure.
  }
}

/// Forgets the snapshot, when the session ends: the widget must not keep showing a person's
/// figures after they sign out (a missing snapshot reads as "Abre Lukitas para empezar"). Like the
/// write, it is ignored when it cannot happen.
Future<void> clearWidgetSnapshot({WidgetStore store = const HomeWidgetStore()}) async {
  try {
    await store.clear(widgetSnapshotKey);
  } on MissingPluginException {
    // No plugin (tests, a desktop run): nothing to clear.
  } on PlatformException {
    // Nothing more to do.
  }
}
