// The frame of the web's sign-in screens (apps/web/app/features/sign-in/SignInScreen.tsx) and the
// small parts they are made of: the title, the lead, an error, the line between two ways in. The
// entry screens, the magic link, the passkey offer and "Guarda tu progreso" are all built from
// them.
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
import '../ui/theme_toggle.dart';

/// Lukitas' size on the sign-in screens: friendly, never crowding the form (`MASCOT_PX`).
const _mascotSize = 96.0;

/// How Lukitas is named for assistive technology, as the web's `mascot.*` messages (a mood).
String _mascotName(AppLocalizations l10n, LukitasMood mood) => switch (mood) {
  LukitasMood.worried => l10n.mascotWorried,
  _ => l10n.mascotHappy,
};

/// The frame of the entry screens: the page's background, the wordmark and the day/night switch on
/// top, then one column with Lukitas above [children] (`SignInScreen`). On a phone the column sits
/// on the background, so the code boxes get the whole width. The page is a screen tall at least
/// (`min-h-dvh`) and scrolls when its content, or the keyboard, needs more.
///
/// The column's children are 16px apart and centred; a child that should fill the width (a form, a
/// button) says so itself.
class SignInFrame extends StatelessWidget {
  const SignInFrame({
    super.key,
    required this.children,
    this.mood = LukitasMood.happy,
    this.controller,
  });

  final List<Widget> children;

  /// How Lukitas looks: happy, or worried when something failed.
  final LukitasMood mood;

  final ScrollController? controller;

  /// `max-w-[480px]` of the header and `max-w-[420px]` of the column.
  static const _headerWidth = 480.0;
  static const _columnWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inset = MediaQuery.paddingOf(context);
    // Storybook's own 16px around the screen, in a parity picture; zero in the app.
    final frame = ShellFrame.maybeOf(context)?.padding ?? EdgeInsets.zero;
    return PageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              frame.left,
              frame.top + inset.top,
              frame.right,
              frame.bottom + inset.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, constraints.maxHeight - inset.vertical),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _headerWidth),
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
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _columnWidth + 2 * 16),
                      child: Padding(
                        // `px-(--space-4) pb-(--space-6)`.
                        padding: const EdgeInsets.fromLTRB(
                          LukitasTokens.space4,
                          0,
                          LukitasTokens.space4,
                          LukitasTokens.space6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: LukitasTokens.space4,
                          children: [
                            LukitasFace(
                              mood: mood,
                              size: _mascotSize,
                              label: _mascotName(l10n, mood),
                            ),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen's title (`ScreenTitle`): display face, centred, a heading.
class EntryTitle extends StatelessWidget {
  const EntryTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        header: true,
        child: BlinkLine(
          style: LkText.screenTitle,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: LkText.screenTitle.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// The paragraph under the title (`<p className="text-center text-ink-muted">`). [strong] is a
/// part of [text] (an email address) the web writes in `ink` in a `<strong>`.
class EntryLead extends StatelessWidget {
  const EntryLead(this.text, {super.key, this.strong, this.ink = false});

  final String text;
  final String? strong;

  /// In the page's ink, for the one sentence that matters, instead of the muted colour.
  final bool ink;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final base = LkText.copy.copyWith(color: ink ? colors.ink : colors.inkMuted);
    final strong = this.strong;
    final at = strong == null ? -1 : text.indexOf(strong);
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        at < 0
            ? TextSpan(text: text, style: base)
            : TextSpan(
                style: base,
                children: [
                  TextSpan(text: text.substring(0, at)),
                  TextSpan(
                    text: strong,
                    style: TextStyle(fontWeight: FontWeight.w900, color: colors.ink),
                  ),
                  TextSpan(text: text.substring(at + strong!.length)),
                ],
              ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A note in the page's muted text, centred (`text-center text-[15px] text-ink-muted`).
class EntryNote extends StatelessWidget {
  const EntryNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final style = LkText.note.copyWith(color: colors.inkMuted);
    return SizedBox(
      width: double.infinity,
      child: CssLines(
        style: style,
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

/// An error under the control it is about (`FieldError`); read out when it appears.
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final style = LkText.note.copyWith(color: context.lkColors.over);
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: CssLines(
          style: style,
          child: Text(text, textAlign: textAlign, style: style),
        ),
      ),
    );
  }
}

/// A field's label (`text-sm text-ink-muted`).
class FieldCaption extends StatelessWidget {
  const FieldCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ExcludeSemantics(
      child: BlinkLine(
        style: LkText.labelSm,
        child: Text(text, style: LkText.labelSm.copyWith(color: context.lkColors.inkMuted)),
      ),
    ),
  );
}

/// "o con tu correo" between two ways in: a 2px `stroke` line, the words, a line
/// (`before:h-0.5 before:flex-1 before:bg-stroke after:...`, gap 12).
class OrDivider extends StatelessWidget {
  const OrDivider(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final line = Expanded(
      child: SizedBox(height: 2, child: ColoredBox(color: colors.stroke)),
    );
    return ExcludeSemantics(
      child: Row(
        spacing: LukitasTokens.space3,
        children: [
          line,
          Text(text, style: LkText.labelSm.copyWith(color: colors.inkMuted)),
          line,
        ],
      ),
    );
  }
}
