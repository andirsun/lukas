// The web's welcome (apps/web/app/features/onboarding/Welcome.tsx) while its session is checked:
// the screen's background and nothing to read yet (`HydrateFallback`, `lk-screen min-h-dvh`).
// Until the steps are ported, this is all it holds.
import 'package:flutter/material.dart';

import '../ui/app_shell.dart';

/// `/welcome/:step?`: the optional onboarding. [step] is the step in the address, null for the
/// first.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.step});

  final String? step;

  @override
  Widget build(BuildContext context) {
    return const PageBackground(
      key: Key('welcome.page'),
      child: Scaffold(backgroundColor: Colors.transparent, body: SizedBox.expand()),
    );
  }
}
