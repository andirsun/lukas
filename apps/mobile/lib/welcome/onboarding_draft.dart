// What the person chose during the welcome that isn't on the server yet (or can't be told from it):
// a port of apps/web/app/features/onboarding/onboarding-draft.ts. The web keeps it for the browser
// session so a reload doesn't lose it; the app keeps it on the phone, so a welcome the app was
// killed in the middle of is where it was left. It is cleared when the welcome ends.
import 'dart:convert';

import '../profile/currency.dart';
import '../settings/settings_store.dart';

class OnboardingDraft {
  const OnboardingDraft({
    this.currency,
    this.selected,
    this.categoriesDone = false,
    this.hiddenSuggestions = const [],
  });

  /// A currency they chose (saved or not): from then on the step shows it, not the region's.
  final String? currency;

  /// Suggestion chip ids and own category ids that are chosen; null: not chosen yet.
  final List<String>? selected;

  /// They left the categories step (SIGUIENTE or SALTAR).
  final bool categoriesDone;

  /// Suggestions (keys) they removed from the step ("Eliminar" on one not made yet).
  final List<String> hiddenSuggestions;

  OnboardingDraft copyWith({
    String? currency,
    List<String>? selected,
    bool? categoriesDone,
    List<String>? hiddenSuggestions,
  }) => OnboardingDraft(
    currency: currency ?? this.currency,
    selected: selected ?? this.selected,
    categoriesDone: categoriesDone ?? this.categoriesDone,
    hiddenSuggestions: hiddenSuggestions ?? this.hiddenSuggestions,
  );

  Map<String, Object?> toJson() => {
    'currency': ?currency,
    'selected': ?selected,
    if (categoriesDone) 'categoriesDone': true,
    if (hiddenSuggestions.isNotEmpty) 'hiddenSuggestions': hiddenSuggestions,
  };

  /// A draft from what was kept; whatever is not of the right type is left out.
  static OnboardingDraft fromJson(Object? json) {
    if (json is! Map) return const OnboardingDraft();
    List<String>? strings(Object? value) =>
        value is List && value.every((e) => e is String) ? value.cast<String>() : null;
    final currency = json['currency'];
    return OnboardingDraft(
      currency: currency is String && isSupportedCurrency(currency) ? currency : null,
      selected: strings(json['selected']),
      categoriesDone: json['categoriesDone'] == true,
      hiddenSuggestions: strings(json['hiddenSuggestions']) ?? const [],
    );
  }
}

/// Where the draft of each person is kept on the phone.
class OnboardingDraftStore {
  const OnboardingDraftStore(this._store);

  final SettingsStore _store;

  static String _key(String userId) => 'onboarding.draft.$userId';

  Future<OnboardingDraft> load(String userId) async {
    try {
      final raw = await _store.read(_key(userId));
      return raw == null ? const OnboardingDraft() : OnboardingDraft.fromJson(jsonDecode(raw));
    } on Object {
      // No storage, or text that is not a draft: the welcome simply doesn't remember.
      return const OnboardingDraft();
    }
  }

  Future<void> save(String userId, OnboardingDraft draft) async {
    try {
      await _store.write(_key(userId), jsonEncode(draft.toJson()));
    } on Object {
      // See [load].
    }
  }

  Future<void> clear(String userId) async {
    try {
      await _store.delete(_key(userId));
    } on Object {
      // See [load].
    }
  }
}
