import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';

/// About (spec section 6.1.6): what Lukitas is, and the licences of everything in it. The licence
/// page is Flutter's own, fed by the packages' LICENSE files (collected at build) and the extras
/// of `registerExtraLicenses`: the voice models, the speech engine, the Android libraries and the
/// sounds.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(LukitasTokens.space5),
              children: [
                Text(l10n.aboutLead, style: theme.textTheme.bodyLarge),
                const SizedBox(height: LukitasTokens.space3),
                Text(l10n.aboutVoice, style: muted),
                const SizedBox(height: LukitasTokens.space5),
                OutlinedButton(
                  key: const Key('about.licenses'),
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                    applicationLegalese: 'AGPL-3.0',
                  ),
                  child: Text(l10n.aboutLicenses),
                ),
                const SizedBox(height: LukitasTokens.space2),
                Text(l10n.aboutLicensesHint, style: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
