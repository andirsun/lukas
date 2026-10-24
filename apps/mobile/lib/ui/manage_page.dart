// The frame of the web's screens under the app shell that are not home (apps/web/app/features/
// categories/CategoryDetail.tsx `ManageFrame`): a column up to 480px wide with 16px gutters, the
// page's header, and the page.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';
import 'app_shell.dart';
import 'page_header.dart';

/// A screen inside the app's shell (the bottom bar, the background) laid out as `ManageFrame` does:
/// [header] (a back link) first, 12px under 12px of top room, then [children], 16px apart, in a
/// `main`. The page scrolls as a whole and is a screen tall at least.
class ManagePage extends StatelessWidget {
  const ManagePage({
    super.key,
    required this.current,
    required this.onAdd,
    required this.onMic,
    required this.onNavigate,
    required this.header,
    required this.children,
    this.controller,
    this.mainGap = LukitasTokens.space4,
    this.mainBottom = LukitasTokens.space4,
  });

  /// The section the bottom bar marks (`home`, `insights`, or another one: none).
  final String current;
  final VoidCallback onAdd;
  final VoidCallback onMic;
  final ValueChanged<String> onNavigate;

  /// The back link.
  final PageHeader header;

  final List<Widget> children;

  final ScrollController? controller;

  /// The gap between [children] and the room under them: `<main className="flex flex-col gap-(--space-4)
  /// pb-(--space-4)">` on most pages, `gap-(--space-3)` and no padding on the recurring one.
  final double mainGap;
  final double mainBottom;

  /// `max-w-[480px]`.
  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      current: current,
      addKey: const Key('home.add'),
      micKey: const Key('home.capture'),
      onAdd: onAdd,
      onMic: onMic,
      onNavigate: onNavigate,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inset = math.max(
              LukitasTokens.space4,
              (constraints.maxWidth - _maxWidth) / 2 + LukitasTokens.space4,
            );
            final sides = ShellRoom.sides(context);
            return SizedBox(
              height: constraints.maxHeight,
              child: SingleChildScrollView(
                controller: controller,
                // The page is this scroll content: the shell paints its gradient over all of it.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShellRoom.leading(context),
                    Semantics(
                      container: true,
                      explicitChildNodes: true,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          inset + sides.left,
                          LukitasTokens.space3,
                          inset + sides.right,
                          ShellRoom.of(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: LukitasTokens.space3,
                          children: [
                            header,
                            // `<main className="flex flex-col gap-(--space-4) pb-(--space-4)">`
                            Padding(
                              padding: EdgeInsets.only(bottom: mainBottom),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: mainGap,
                                children: children,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
