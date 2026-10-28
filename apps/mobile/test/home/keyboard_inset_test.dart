import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fixtures.dart';
import 'home_harness.dart';

void main() {
  testWidgets('the list keeps the whole screen while the keyboard of the add sheet is up', (
    tester,
  ) async {
    final repo = FakeHomeRepository(
      budgetTotal: 100000000,
      items: [for (var i = 0; i < 6; i++) tx('t$i', '2026-10-22', -100000 - i, name: 'Compra $i')],
    );
    await pumpHome(tester, repo, size: const Size(390, 844));
    final before = tester.getSize(find.byType(CustomScrollView)).height;
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CustomScrollView)).height, before);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CustomScrollView)).height, before);
  });
}
