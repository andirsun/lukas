import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home_controller.dart';

/// Where the bottom bar's tabs lead, the same from every screen (the web's `BottomBar`, whose
/// Inicio is `/app` and whose Análisis is `/app/insights`).
///
/// [to] is `home` or `insights`; [current] is the section the screen marks (a tap on it does
/// nothing).
/// - Inicio is home on the current month, from wherever: whatever is on top of home goes, and home
///   follows the current month again, as the web's Inicio opens a fresh Home.
/// - Análisis opens on [month], the one the screen shows, or else the one home is on.
void navigateFromShell(
  BuildContext context,
  WidgetRef ref,
  String to, {
  required String current,
  String? month,
}) {
  if (to == current) return;
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  final home = ref.read(homeProvider);
  switch (to) {
    case 'home':
      unawaited(ref.read(homeProvider.notifier).showCurrentMonth());
      router.go('/');
    case 'insights':
      final shown = month ?? home.month ?? home.data?.month;
      unawaited(router.push<void>(shown == null ? '/insights' : '/insights?month=$shown'));
  }
}
