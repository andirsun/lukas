import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';

/// The app shell's first screen. A placeholder until the home screen is built.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LukitasTokens.space4),
          child: Center(
            child: Text(l10n.appName, style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
      ),
    );
  }
}
