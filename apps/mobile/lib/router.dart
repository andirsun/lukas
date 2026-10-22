import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api/session.dart';
import 'entry/email_screen.dart';
import 'entry/entry_screen.dart';
import 'entry/verify_link_screen.dart';
import 'home/home_screen.dart';

/// Where the session sends a [location], or null to stay:
/// - the magic link (`/auth/verify`) always opens: it decides for itself, guests included;
/// - while the stored session is read, a blank screen;
/// - signed out, only the entry screens;
/// - signed in, never the first-run screen, and the email screen only for a guest (to save their
///   progress, or to sign in as another account after a warning).
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
      if (path == '/entry/email' && !session.isGuest) return '/';
      return null;
  }
}

/// The app's routes. Screens join here as they are built.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  final router = GoRouter(
    refreshListenable: session,
    redirect: (context, state) => sessionRedirect(session.value, state.uri),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
