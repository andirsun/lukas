// The pieces the insights cards share: the web's `parts.tsx` (apps/web/app/features/insights/) and
// the CSS it leans on (app.css `.lk-hero`, `.lk-tile`, `.lk-insight-body`).
import 'package:flutter/material.dart';

import '../home/category_look.dart';
import '../home/home_widgets.dart' show HeroCard;
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import '../ui/css_text.dart';
import '../ui/lk_theme.dart';
import 'insights_model.dart';

/// Whether the person asked the phone to remove animations: the charts and cards then show their
/// final state (the web's `useReducedMotionPreference`).
bool reducedMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// A period mid-sentence: `en octubre`, `de agosto a octubre` (`usePeriodPhrase`).
String periodPhrase(AppLocalizations l10n, Period period, String current) {
  final locale = l10n.localeName;
  return period.from == period.to
      ? l10n.insightsPeriodOne(monthLabel(period.to, current, locale))
      : l10n.insightsPeriodRange(
          monthLabel(period.from, current, locale),
          monthLabel(period.to, current, locale),
        );
}

/// The first letter in upper case, for a phrase that starts a line: `De agosto a octubre`
/// (`capitalize`).
String capitalize(String text, String locale) =>
    text.isEmpty ? text : text.substring(0, 1).toUpperCase() + text.substring(1);

/// A tile's ground: the tint mixed into the sunken surface, so it reads in both themes
/// (`tileGround`, `color-mix(in srgb, tint 45%, var(--surface-sunken))`).
Color tileGround(LukitasColors colors, Color tint) => Color.lerp(colors.surfaceSunken, tint, 0.45)!;

/// The colour to draw a category's tint with as a mark (a donut sector, a share bar) in the
/// current theme: its theme token, which the day theme darkens to keep 3:1 on the card. A colour
/// that is not one of the pickable tints is drawn as it is (`useMarkColor`).
Color markColor(LukitasColors colors, Color tint) => switch (tintName(tint)) {
  'orange' => colors.tintOrange,
  'red' => colors.tintRed,
  'purple' => colors.tintPurple,
  'indigo' => colors.tintIndigo,
  'blue' => colors.tintBlue,
  'pink' => colors.tintPink,
  'amber' => colors.tintAmber,
  'yellow' => colors.tintYellow,
  'green' => colors.tintGreen,
  'teal' => colors.tintTeal,
  'sky' => colors.tintSky,
  'gray' => colors.tintGray,
  _ => tint,
};

/// Plays [builder] with an animation value from 0 to 1 once, after [delay], over [duration] with
/// ease-out, when it first shows; at 1 at once when the phone removes animations. It is the
/// web's `motion` entrance: `initial`, then `animate` with `transition`.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.duration,
    this.delay = Duration.zero,
    required this.builder,
  });

  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reducedMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.delay + widget.duration).inMicroseconds;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final elapsed = _controller.value * total - widget.delay.inMicroseconds;
        final t = Curves.easeOut.transform((elapsed / widget.duration.inMicroseconds).clamp(0, 1));
        return widget.builder(context, t);
      },
    );
  }
}

/// One section of the screen: a card (`.lk-hero`) named by its heading. It rises into place over
/// `--sheet`, a beat after the one before it ([order]); with "remove animations" it is there.
/// While [busy] (older figures on screen while new ones load) its title and figures dim
/// (`.lk-insight-body`), and the [controls] do not.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.order,
    this.busy = false,
    this.controls,
    required this.children,
  });

  final String title;
  final String? subtitle;

  /// Its place on the screen, for the staggered entrance.
  final int order;

  /// Showing an older answer while the new one loads.
  final bool busy;

  /// What changes the figures (toggles): never dimmed while they load.
  final Widget? controls;

  /// The card's body, one child per row of its column (12px apart).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return Entrance(
      duration: LukitasTokens.durationSheet,
      delay: Duration(milliseconds: (order * 70)),
      builder: (context, t) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: HeroCard(
            padding: const EdgeInsets.fromLTRB(
              LukitasTokens.space4,
              LukitasTokens.space3,
              LukitasTokens.space4,
              LukitasTokens.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: LukitasTokens.space3,
              children: [
                InsightBody(
                  busy: busy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: LukitasTokens.space1,
                    children: [
                      Semantics(
                        header: true,
                        child: CssLines(
                          style: _titleStyle,
                          child: Text(title, style: _titleStyle.copyWith(color: colors.ink)),
                        ),
                      ),
                      if (subtitle != null)
                        CssLines(
                          style: _subtitleStyle,
                          child: Text(
                            subtitle!,
                            style: _subtitleStyle.copyWith(color: colors.inkMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                ?controls,
                InsightBody(
                  busy: busy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: LukitasTokens.space3,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card's title: parts.tsx `font-display text-[20px] font-bold leading-tight`.
const _titleStyle = TextStyle(
  fontFamily: 'Fredoka',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  height: 1.25,
  leadingDistribution: TextLeadingDistribution.even,
);

/// A card's subtitle: parts.tsx `text-[13px] font-bold`, on the page's 1.5 line height.
const _subtitleStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.5,
  leadingDistribution: TextLeadingDistribution.even,
);

/// A section showing older figures while new ones load: the figures dim to 45 % over `--sheet`
/// (app.css `.lk-insight-body`), so nobody reads them as the answer to what was just picked.
class InsightBody extends StatelessWidget {
  const InsightBody({super.key, required this.busy, required this.child});

  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: busy ? 0.45 : 1,
    duration: reducedMotion(context) ? Duration.zero : LukitasTokens.durationSheet,
    curve: Curves.easeOut,
    child: child,
  );
}

/// A placeholder of the right height while a section's figures load (`Loading`).
class InsightLoading extends StatelessWidget {
  const InsightLoading({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.lkColors.surfaceSunken,
        borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
      ),
    ),
  );
}
