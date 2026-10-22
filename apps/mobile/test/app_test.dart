import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/app.dart';
import 'package:lukitas/theme/tokens.g.dart';

import 'entry/fakes.dart';

void main() {
  testWidgets('a smoke widget test renders the app shell in night theme', (tester) async {
    // Signed out, on the real providers: the first-run screen.
    mockStorage();
    await tester.pumpWidget(const ProviderScope(child: LukitasApp()));
    await tester.pumpAndSettle();

    expect(find.text('Lukitas'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, LukitasTokens.night.bg);
    expect(theme.colorScheme.primary, LukitasTokens.night.brand);
  });
}
