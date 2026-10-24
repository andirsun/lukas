// The frame of a welcome step: the web's StepFrame (apps/web/app/features/onboarding/StepFrame.tsx)
// and the CSS it uses (app.css `.lk-screen`, `.lk-logo`).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../home/home_header.dart' show LkWordmark;
import '../home/lukitas_face.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/app_shell.dart';
import '../ui/css_text.dart';
import '../ui/lk_theme.dart';
import '../ui/offset_underline.dart';
import '../ui/press_button.dart';
import '../ui/svg_path.dart';
import '../ui/theme_toggle.dart';
import 'steps.dart';

/// A button of the footer: its label, and what it does (null: waiting).
class StepAction {
  const StepAction({required this.label, this.onPressed, this.key});

  final String label;
  final VoidCallback? onPressed;
  final Key? key;
}

/// Lukitas' size beside a step's title: friendly, never crowding it (`MASCOT_PX`).
const _mascotSize = 72.0;

/// `max-w-[480px]` of the header and the main column.
const _maxWidth = 480.0;

/// The frame of an onboarding step: the wordmark and the day/night switch, the progress ("Paso 2 de
/// 4", not on the welcome), Lukitas beside the title, the content, and Back / SALTAR / SIGUIENTE at
/// the bottom (they stay in reach while the content scrolls).
class StepFrame extends StatelessWidget {
  const StepFrame({
    super.key,
    required this.step,
    required this.title,
    this.lead,
    this.mood = LukitasMood.happy,
    this.onBack,
    this.backDisabled = false,
    this.skip,
    this.next,
    this.summary,
    this.controller,
    required this.children,
  });

  final StepId step;
  final String title;
  final String? lead;
  final LukitasMood mood;

  /// Back: none on the first step.
  final VoidCallback? onBack;

  /// Back waits too (while an import is being read or confirmed).
  final bool backDisabled;

  /// SALTAR.
  final StepAction? skip;

  /// SIGUIENTE, or the step's own main action ("Importar 22 movimientos").
  final StepAction? next;

  /// Shown above the buttons, so it stays in view while the content scrolls (a running total).
  final Widget? summary;

  final ScrollController? controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final inset = MediaQuery.paddingOf(context);
    // Storybook's own 16px around the screen, in a parity picture; zero in the app.
    final frame = ShellFrame.maybeOf(context)?.padding ?? EdgeInsets.zero;
    final current = setupSteps.indexOf(step) + 1;
    final counted = current > 0;
    final hasFooter = next != null || skip != null || summary != null;

    final progress = counted
        ? <Widget>[
            Semantics(
              container: true,
              child: CssLines(
                style: LkText.note,
                child: Text(
                  l10n.welcomeProgress(current, setupSteps.length),
                  key: const Key('welcome.progress'),
                  style: LkText.note.copyWith(color: colors.inkMuted),
                ),
              ),
            ),
            // `mt-(--space-2) flex gap-(--space-1)`: one bar per setup step. The progress line is 22.5px
            // tall, so the bars start on a half pixel; Chrome draws a box on the pixel grid, rounding
            // that up (the web's picture has them at 115px, not 114.5), and the title under them does
            // not move. The half pixel is added here and taken from the gap below.
            const SizedBox(height: LukitasTokens.space2 + 0.5),
            ExcludeSemantics(
              child: Row(
                spacing: LukitasTokens.space1,
                children: [
                  for (var i = 0; i < setupSteps.length; i++)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i < current ? colors.brandGlow : colors.stroke,
                          borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
                        ),
                        child: const SizedBox(height: 6),
                      ),
                    ),
                ],
              ),
            ),
          ]
        : const <Widget>[];

    return PageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(frame.left, frame.top + inset.top, frame.right, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Centered(
                      child: const Padding(
                        // `px-(--space-4) py-(--space-3)`.
                        padding: EdgeInsets.symmetric(
                          horizontal: LukitasTokens.space4,
                          vertical: LukitasTokens.space3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [LkWordmark(), ThemeToggle()],
                        ),
                      ),
                    ),
                    _Centered(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: LukitasTokens.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...progress,
                            SizedBox(
                              height: counted ? LukitasTokens.space4 - 0.5 : LukitasTokens.space4,
                            ),
                            _TitleRow(title: title, mood: mood),
                            if (lead != null) ...[
                              // 0.5px more than `mt-3`: where Chrome's rounding puts the lead.
                              const SizedBox(height: LukitasTokens.space3 + 0.5),
                              Text(
                                lead!,
                                key: const Key('welcome.lead'),
                                style: LkText.copy.copyWith(color: colors.inkMuted),
                              ),
                            ],
                            SizedBox(
                              height: lead != null
                                  ? LukitasTokens.space4 - 0.5 + (counted ? 0 : 0)
                                  : LukitasTokens.space4,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: LukitasTokens.space4,
                              children: children,
                            ),
                            const SizedBox(height: LukitasTokens.space4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasFooter)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: frame.left),
                child: _Centered(
                  child: ColoredBox(
                    color: colors.bg,
                    child: Padding(
                      // `px-(--space-4) pt-(--space-3) pb-[max(var(--space-4), env(safe-area-inset-bottom))]`.
                      padding: EdgeInsets.fromLTRB(
                        LukitasTokens.space4,
                        LukitasTokens.space3,
                        LukitasTokens.space4,
                        math.max(LukitasTokens.space4, inset.bottom),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: LukitasTokens.space3,
                        children: [
                          ?summary,
                          Row(
                            spacing: LukitasTokens.space2,
                            children: [
                              if (onBack != null)
                                PressButton(
                                  key: const Key('welcome.back'),
                                  tone: PressTone.ghost,
                                  semanticLabel: l10n.welcomeBack,
                                  onPressed: backDisabled ? null : onBack,
                                  child: const _BackIcon(),
                                ),
                              if (skip != null)
                                PressButton(
                                  key: skip!.key ?? const Key('welcome.skip'),
                                  tone: PressTone.ghost,
                                  semanticLabel: skip!.label,
                                  onPressed: skip!.onPressed,
                                  child: OffsetUnderline(LkText.upperCase(skip!.label)),
                                ),
                              if (next != null)
                                Expanded(
                                  child: PressButton.text(
                                    next!.label,
                                    key: next!.key ?? const Key('welcome.next'),
                                    onPressed: next!.onPressed,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `mx-auto w-full max-w-[480px]`.
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: child,
    ),
  );
}

/// `<div className="mt-4 flex items-center gap-3">`: Lukitas and the title (a heading).
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, required this.mood});

  final String title;
  final LukitasMood mood;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    return Row(
      spacing: LukitasTokens.space3,
      children: [
        // The web's `<span className="shrink-0">` holds the face as an inline box: 7px of line (the
        // baseline's descent) under it make the row 79px tall.
        SizedBox(
          width: _mascotSize,
          height: 79,
          child: Align(
            alignment: Alignment.topLeft,
            child: LukitasFace(
              mood: mood,
              size: _mascotSize,
              label: mood == LukitasMood.worried ? l10n.mascotWorried : l10n.mascotHappy,
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: const Key('welcome.title'),
              style: LkText.pageTitle.copyWith(color: colors.ink, fontSize: 26, height: 1.25),
            ),
          ),
        ),
      ],
    );
  }
}

/// An error under the control it is about, read out when it appears (`StepError`).
class StepError extends StatelessWidget {
  const StepError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = LkText.note.copyWith(color: context.lkColors.over);
    return Semantics(
      liveRegion: true,
      container: true,
      child: CssLines(
        style: style,
        child: Text(text, key: const Key('welcome.error'), style: style),
      ),
    );
  }
}

final _backPath = [parseSvgPath('M15 5l-7 7 7 7')];

/// `<path d="M15 5l-7 7 7 7" />` in a 24px box, 22px, stroke 2.5.
class _BackIcon extends StatelessWidget {
  const _BackIcon();

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return ExcludeSemantics(
      child: CustomPaint(size: const Size.square(22), painter: _BackPainter(color)),
    );
  }
}

class _BackPainter extends CustomPainter {
  const _BackPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;
    for (final path in _backPath) {
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_BackPainter old) => old.color != color;
}
