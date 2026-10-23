import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../add/add_sheet.dart';
import '../capture/capture_sheet.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../ui/lk_theme.dart';
import '../ui/manage_page.dart';
import '../ui/page_header.dart';
import '../ui/press_button.dart';
import 'licenses.dart';
import 'settings_parts.dart';

/// About (spec section 6.1.6): what Lukitas is, and the licences of everything in it, in the web's
/// settings style (a page header and a card). The licence page is Flutter's own, fed by the
/// packages' LICENSE files (collected at build) and the extras of `registerExtraLicenses`: the
/// voice models, the speech engine, the Android libraries and the sounds.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    return ManagePage(
      current: 'settings',
      onAdd: () => unawaited(openAddSheet(context)),
      onMic: () => unawaited(openCapture(context, listen: true)),
      onNavigate: (to) {
        final router = GoRouter.of(context);
        if (to == 'insights') {
          unawaited(router.push<void>('/insights'));
        } else {
          router.go('/');
        }
      },
      header: PageHeader(
        backLabel: l10n.aboutBack,
        backShort: l10n.aboutBackShort,
        onBack: () => _back(context),
      ),
      children: [
        Semantics(
          header: true,
          child: Text(l10n.aboutTitle, style: LkText.pageTitle.copyWith(color: colors.ink)),
        ),
        SettingsSection(
          title: l10n.settingsAbout,
          lead: l10n.aboutLead,
          children: [Text(l10n.aboutVoice, style: LkText.bodySm.copyWith(color: colors.inkMuted))],
        ),
        SettingsSection(
          title: l10n.aboutLicenses,
          lead: l10n.aboutLicensesHint,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: PressButton.text(
                l10n.aboutLicenses,
                key: const Key('about.licenses'),
                tone: PressTone.secondary,
                onPressed: () {
                  // The notices are written in the app's own language.
                  setLicenseLanguage(Localizations.localeOf(context));
                  showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                    applicationLegalese: l10n.aboutLegalese,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
