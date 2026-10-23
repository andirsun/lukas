import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback/feedback.dart';
import 'home/widget_sync.dart';
import 'launch/launch_links.dart';
import 'l10n/app_localizations.dart';
import 'notices/notice_sync.dart';
import 'router.dart';
import 'settings/preferences.dart';
import 'theme/theme.dart';

/// The app shell: theme (night by default), es and en copy, and routes.
class LukitasApp extends ConsumerWidget {
  const LukitasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loads the sounds and reads the sound setting at the start, so the first save is not late.
    ref.watch(feedbackProvider);
    // Copies the hide-amount and theme choices into the home-screen widget's snapshot as they change.
    ref.watch(widgetSyncProvider);
    // Opens the add sheet or quick capture for the widget's ＋ and 🎤 and the Quick Settings tile.
    ref.watch(launchLinksProvider);
    // Schedules the two local notices ("Hoy vence…" at 9:00, the guest warning) and asks the
    // notification permission, once, when one first becomes relevant.
    ref.watch(noticeSyncProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: dayTheme,
      darkTheme: nightTheme,
      // Night unless the person picked day, or the phone's own mode, in Settings.
      themeMode: ref.watch(themeModeProvider),
      // The phone's language unless the person picked Spanish or English in Settings.
      locale: ref.watch(localeOverrideProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Spanish unless the phone asks for a language the app has.
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (candidate) => candidate.languageCode == locale?.languageCode,
        orElse: () => const Locale('es'),
      ),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
