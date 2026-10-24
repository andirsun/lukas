import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/welcome/onboarding_draft.dart';

import '../settings/fakes.dart';

/// The web's draft (apps/web/app/features/onboarding/onboarding-draft.ts) kept on the phone, so a
/// welcome the app was killed in the middle of is where it was left.
void main() {
  late FakeSettingsStore settings;
  late OnboardingDraftStore store;

  setUp(() {
    settings = FakeSettingsStore();
    store = OnboardingDraftStore(settings);
  });

  test('is empty until something is chosen', () async {
    final draft = await store.load('u-1');
    expect(draft.currency, isNull);
    expect(draft.selected, isNull);
    expect(draft.categoriesDone, isFalse);
    expect(draft.hiddenSuggestions, isEmpty);
  });

  test('keeps what was chosen, per person', () async {
    await store.save(
      'u-1',
      const OnboardingDraft(
        currency: 'EUR',
        selected: ['s:groceries', 'cat-1'],
        categoriesDone: true,
        hiddenSuggestions: ['health'],
      ),
    );
    final back = await OnboardingDraftStore(settings).load('u-1');
    expect(back.currency, 'EUR');
    expect(back.selected, ['s:groceries', 'cat-1']);
    expect(back.categoriesDone, isTrue);
    expect(back.hiddenSuggestions, ['health']);
    expect((await store.load('u-2')).currency, isNull);
  });

  test('a change keeps the rest of the draft, changing only what it names', () {
    const draft = OnboardingDraft(currency: 'COP', selected: ['a']);
    final merged = draft.copyWith(categoriesDone: true, selected: ['b']);
    expect(merged.currency, 'COP');
    expect(merged.selected, ['b']);
    expect(merged.categoriesDone, isTrue);
  });

  test('clearing forgets it', () async {
    await store.save('u-1', const OnboardingDraft(currency: 'EUR'));
    await store.clear('u-1');
    expect((await store.load('u-1')).currency, isNull);
    expect(settings.values.keys.where((k) => k.contains('u-1')), isEmpty);
  });

  test('anything unreadable is an empty draft', () async {
    for (final raw in ['not json', '[1,2]', '"text"', '{"currency":5,"selected":"x"}', '{}']) {
      settings.values['onboarding.draft.u-1'] = raw;
      final draft = await store.load('u-1');
      expect(draft.currency, isNull, reason: raw);
      expect(draft.selected, isNull, reason: raw);
    }
  });

  test('an unsupported currency in the draft is dropped', () async {
    settings.values['onboarding.draft.u-1'] = '{"currency":"JPY"}';
    expect((await store.load('u-1')).currency, isNull);
  });

  test('a store that cannot be read or written leaves the draft in memory only', () async {
    final broken = OnboardingDraftStore(_Broken());
    expect((await broken.load('u-1')).currency, isNull);
    await broken.save('u-1', const OnboardingDraft(currency: 'EUR'));
    await broken.clear('u-1');
  });
}

class _Broken extends FakeSettingsStore {
  @override
  Future<String?> read(String key) => throw StateError('no storage');

  @override
  Future<void> write(String key, String value) => throw StateError('no storage');

  @override
  Future<void> delete(String key) => throw StateError('no storage');
}
