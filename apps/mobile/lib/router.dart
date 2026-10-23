import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api/session.dart';
import 'entry/email_screen.dart';
import 'entry/entry_screen.dart';
import 'entry/verify_link_screen.dart';
import 'budgets/category_detail_screen.dart';
import 'home/home_screen.dart';
import 'insights/insights_screen.dart';
import 'progress/progress_screen.dart';
import 'settings/about_screen.dart';
import 'settings/home_actions.dart';
import 'settings/settings_screen.dart';

/// Where the session sends a [location], or null to stay:
/// - the magic link (`/auth/verify`) always opens: it decides for itself, guests included;
/// - while the stored session is read, a blank screen;
/// - signed out, only the entry screens;
/// - signed in, never the first-run screen, and the email screen and "Guarda tu progreso" only for
///   a guest (to save their progress, or to sign in as another account after a warning).
String? sessionRedirect(SessionState session, Uri location) {
  final path = location.path;
  if (path == '/auth/verify') return null;
  switch (session.status) {
    case SessionStatus.loading:
      return path == '/loading' ? null : '/loading';
    case SessionStatus.signedOut:
      return path == '/entry' || path == '/entry/email' ? null : '/entry';
    case SessionStatus.signedIn:
      if (path == '/loading' || path == '/entry') return '/';
      if ((path == '/entry/email' || path == '/progress') && !session.isGuest) return '/';
      return null;
  }
}

/// The app's routes. Screens join here as they are built.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  final router = GoRouter(
    refreshListenable: session,
    // A location no route has (an address Android hands over that is not one of the app's, such as
    // the `glance-action:/CALLBACK?...` a tap on the widget carried) is home, never "Page Not Found".
    onException: (context, state, router) => router.go('/'),
    redirect: (context, state) => sessionRedirect(session.value, state.uri),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(
          // The month to open on, when a link carries one (`/?month=2026-09`).
          initialMonth: state.uri.queryParameters['month'],
          menu: (context, close) => HomeMenuLinks(close: close),
        ),
      ),
      GoRoute(
        path: '/categories/:id',
        builder: (context, state) => CategoryDetailScreen(
          // A new category replaces the screen of an earlier one.
          key: ValueKey(state.pathParameters['id']),
          categoryId: state.pathParameters['id']!,
          // The month it opens on (`?month=2026-09`), home's when it comes from a budget row.
          initialMonth: state.uri.queryParameters['month'],
        ),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) =>
            // The month the period ends at (`?month=2026-09`), home's when it comes from there.
            InsightsScreen(initialMonth: state.uri.queryParameters['month']),
      ),
      GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [GoRoute(path: 'about', builder: (context, state) => const AboutScreen())],
      ),
      GoRoute(path: '/loading', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/entry', builder: (context, state) => const EntryScreen()),
      GoRoute(
        path: '/entry/email',
        builder: (context, state) => EmailScreen(
          initialEmail: state.uri.queryParameters['email'],
          claim: state.uri.queryParameters['claim'] == '1',
        ),
      ),
      GoRoute(
        path: '/auth/verify',
        builder: (context, state) => VerifyLinkScreen(
          // A new link replaces the screen of an earlier one.
          key: ValueKey(state.uri.query),
          email: state.uri.queryParameters['email'],
          code: state.uri.queryParameters['code'],
        ),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
