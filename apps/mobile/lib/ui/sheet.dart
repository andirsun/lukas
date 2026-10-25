// The web's Sheet (apps/web/app/ui/Sheet.tsx) and the CSS it uses: app.css `.lk-sheet`, `.lk-grab`,
// `--scrim`, and the pinned-footer rules of the "Feel pass" section (`.lk-sheet.has-footer`,
// `.lk-sheet-pinned`, `.lk-sheet-body`, `.lk-sheet-footer`).
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'lk_theme.dart';
import 'press_button.dart';
import 'swipe_rules.dart';
import 'toast.dart';

/// A bottom sheet over a dimmed backdrop: a modal dialog named by its title (the web's `Sheet`).
/// It replaces the Material bottom sheet everywhere in the app.
///
/// - Escape, the close button, the backdrop and dragging it down from anywhere all close it (the
///   same path as "Cerrar").
/// - The drag follows the finger (resisting upward); let go past a quarter of its height, or
///   flicked down, it closes, otherwise it springs back. Taps stay taps, sideways swipes stay
///   sideways, an inner area scrolled away from its top scrolls back first, and a key a drag
///   starts on never types.
/// - It slides over `--sheet` (260 ms) with the web's deceleration; under the system's "remove
///   animations" it only fades.
/// - While open it hosts the toasts ([ToastSlot]).
///
/// A sheet that asks something only its own buttons may answer is not [dismissible]: no backdrop,
/// no drag, no Escape and no "Cerrar" close it, and the system's back button does what the caller
/// says ([show]'s `backResult`).
abstract final class LkSheet {
  /// Opens a sheet and returns what it is popped with.
  ///
  /// A sheet whose parts share state (the add sheet's amount, keypad and Guardar) puts that state
  /// in [wrap]: it gets the whole sheet (its header, parts and backdrop) and returns it inside
  /// whatever holds the state, so every part under it can read it. [titleOf] then names the sheet
  /// from there (the add sheet's title follows the kind), in the header and for assistive
  /// technology; [title] is what it says without one.
  ///
  /// [children] sit under the title, [pinned] and [footer] make the add sheet's layout: with a
  /// [footer] the sheet may take all but a strip of the screen, [pinned] stays under the header,
  /// the [children] scroll between them, and the footer is always in view. Without one the whole
  /// sheet scrolls; then [stuck] (the web's `.lk-sheet-footer` in a sheet that scrolls as a whole:
  /// a budget's Guardar) stays at the bottom of the sheet while the rest scrolls above it.
  ///
  /// While [locked] is true the sheet cannot be closed by the person at all (no backdrop, drag, Escape,
  /// "Cerrar" or back button), and is again when it turns false: a sheet that is busy with something
  /// that must not be walked away from (the web's `close()` ignoring `busy`). What is in the sheet
  /// and the caller can still pop the route.
  ///
  /// With [dismissible] false only what is in the sheet closes it (the caller pops the route): the
  /// backdrop, the drag, Escape and the header's "Cerrar" are gone. The system's back button then
  /// closes it with [backResult]'s value, or does nothing without one. A pop that does not come
  /// from the person (a link closing every sheet) still closes it, with a null result.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    List<Widget> pinned = const [],
    List<Widget>? footer,
    List<Widget>? stuck,
    StuckGaps stuckGaps = StuckGaps.budget,
    bool useRootNavigator = true,
    bool dismissible = true,
    ValueListenable<bool>? locked,
    T Function()? backResult,
    String Function(BuildContext context)? titleOf,
    Widget Function(Widget sheet)? wrap,
  }) {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    return navigator.push(
      _LkSheetRoute<T>(
        title: title,
        titleOf: titleOf,
        wrap: wrap,
        children: children,
        pinned: pinned,
        footer: footer,
        stuck: stuck,
        stuckGaps: stuckGaps,
        dismissible: dismissible,
        locked: locked,
        backResult: backResult,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      ),
    );
  }
}

/// What the sheet around a widget is, for the widgets that look different in each: the amount of
/// a sheet with a pinned footer has a tighter line (`.lk-sheet.has-footer .lk-sheet-amount`).
class LkSheetScope extends InheritedWidget {
  const LkSheetScope({super.key, required this.hasFooter, required super.child});

  /// The sheet has a pinned footer (the add sheet's keypad and Guardar).
  final bool hasFooter;

  /// The sheet above [context], or null outside one.
  static LkSheetScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LkSheetScope>();

  @override
  bool updateShouldNotify(LkSheetScope old) => old.hasFooter != hasFooter;
}

/// Phones up to 844 px tall (`@media (max-height: 859.98px)`) get the tighter footer and keys.
const compactFooterBelow = 860.0;

/// The two gaps around a stuck footer, which follow the web form the footer is in: the form's own
/// gap (the room between its last row and the footer) and how far the footer's bottom edge sits
/// above the sheet's bottom, under its own padding.
class StuckGaps {
  const StuckGaps({required this.form, required this.bottom});

  final double form;
  final double bottom;

  /// The budget sheet's form, `gap-(--space-2)`.
  static const budget = StuckGaps(form: _formGap, bottom: _stuckBottomGap);

  /// The recurring form, `gap-(--space-3)`: its footer sits flush on the sheet's padding
  /// (calibrated against its picture).
  static const recurring = StuckGaps(form: LukitasTokens.space3, bottom: 0);
}

/// How far a stuck footer's bottom edge sits above the sheet's bottom, under the footer's own
/// padding: the sheet's padding (`space-4`) less the form's gap that the web's toast slot adds under
/// the footer (calibrated against the budget sheet's picture). Not more with a system inset: the
/// footer's own padding already clears it.
const _stuckBottomGap = LukitasTokens.space4 - LukitasTokens.space2;

/// The gap the web's form (`gap-(--space-2)`) leaves between its last row and the stuck footer.
const _formGap = LukitasTokens.space2;

/// What the scrolling part of a sheet with a stuck footer is clipped to: its own box, and 3px more
/// below. The web's footer (`position: sticky`, `z-index: 1`) used to be pushed up by the sheet's
/// padding, so it sat flush on the keypad's last row and hid that row's solid edge: the keys looked
/// cut (the web's CSS is fixed now, and leaves the form's 8px gap, [_formGap]). Here the edge is
/// still drawn over the footer's line should the content ever end flush against it, 3px being the
/// edge's height (`.lk-key`'s `box-shadow: 0 3px 0`); the keys' boxes themselves are wholly above
/// the footer.
class _KeyEdgeClip extends CustomClipper<Rect> {
  const _KeyEdgeClip();

  static const edge = 3.0;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height + edge);

  @override
  bool shouldReclip(_KeyEdgeClip oldClipper) => false;
}

/// The sheet's slide: iOS-like deceleration (Sheet.tsx `SHEET_EASE`).
const _sheetEase = Cubic(0.32, 0.72, 0, 1);

class _LkSheetRoute<T> extends PopupRoute<T> {
  _LkSheetRoute({
    required this.title,
    required this.titleOf,
    required this.wrap,
    required this.children,
    required this.pinned,
    required this.footer,
    required this.stuck,
    required this.stuckGaps,
    required this.dismissible,
    required this.locked,
    required this.backResult,
    required this.themes,
    required this.barrierLabel,
  });

  final String title;
  final String Function(BuildContext context)? titleOf;
  final Widget Function(Widget sheet)? wrap;
  final List<Widget> children;
  final List<Widget> pinned;
  final List<Widget>? footer;
  final List<Widget>? stuck;
  final StuckGaps stuckGaps;
  final bool dismissible;
  final ValueListenable<bool>? locked;
  final T Function()? backResult;
  final CapturedThemes themes;

  @override
  Duration get transitionDuration => LukitasTokens.durationSheet;

  @override
  Duration get reverseTransitionDuration => LukitasTokens.durationSheet;

  // The sheet draws its own backdrop: the web's fades with easeInOut, and a tap on it closes.
  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    _SheetPage(
      route: this,
      animation: animation,
      title: title,
      titleOf: titleOf,
      wrap: wrap,
      pinned: pinned,
      footer: footer,
      stuck: stuck,
      stuckGaps: stuckGaps,
      dismissible: dismissible,
      locked: locked,
      backResult: backResult == null ? null : () => backResult!(),
      children: children,
    ),
  );
}

class _SheetPage extends StatefulWidget {
  const _SheetPage({
    required this.route,
    required this.animation,
    required this.title,
    required this.titleOf,
    required this.wrap,
    required this.children,
    required this.pinned,
    required this.footer,
    required this.stuck,
    required this.stuckGaps,
    required this.dismissible,
    required this.locked,
    required this.backResult,
  });

  final Route<dynamic> route;
  final Animation<double> animation;
  final String title;
  final String Function(BuildContext context)? titleOf;
  final Widget Function(Widget sheet)? wrap;
  final List<Widget> children;
  final List<Widget> pinned;
  final List<Widget>? footer;
  final List<Widget>? stuck;
  final StuckGaps stuckGaps;
  final bool dismissible;
  final ValueListenable<bool>? locked;
  final Object? Function()? backResult;

  @override
  State<_SheetPage> createState() => _SheetPageState();
}

class _SheetPageState extends State<_SheetPage> with SingleTickerProviderStateMixin {
  /// How far the sheet is dragged down from where it rests, in px. Unbounded: a spring drives it
  /// back.
  late final AnimationController _dragY = AnimationController.unbounded(vsync: this);
  final _scroll = ScrollController();
  final _panelKey = GlobalKey();

  bool _reduceMotion = false;
  bool _dragging = false;
  bool _armed = false;
  bool _scrolled = false;
  double _from = 0;
  double _height = 1;

  /// Whether the person may close the sheet now: it is [_SheetPage.dismissible] and not locked.
  bool get _dismissible => widget.dismissible && !(widget.locked?.value ?? false);

  void _lockChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _dragY.addListener(() => setState(() {}));
    _scroll.addListener(_onScroll);
    widget.locked?.addListener(_lockChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    widget.locked?.removeListener(_lockChanged);
    _dragY.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scroll.hasClients && _scroll.offset > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  void _close() {
    if (!_dismissible) return;
    if (widget.route.isCurrent) Navigator.of(context).pop();
  }

  // -- the drag ------------------------------------------------------------------------------

  void _springBack() {
    if (_dragY.value == 0) return;
    if (_reduceMotion) {
      _dragY.value = 0;
      return;
    }
    _dragY
        .animateWith(
          SpringSimulation(
            const SpringDescription(
              mass: 1,
              stiffness: SwipeFeel.sheetBackStiffness,
              damping: SwipeFeel.sheetBackDamping,
            ),
            _dragY.value,
            0,
            _dragY.velocity,
            tolerance: const Tolerance(distance: 0.5, velocity: 0.5),
          ),
        )
        .then<void>((_) => _dragY.value = 0, onError: (_) {});
  }

  /// Whether a touch may drag the sheet down: not while its scrolling area is scrolled away from
  /// its top (that area scrolls back first, as on iOS).
  bool _onStart() {
    if (_scroll.hasClients && _scroll.offset > 0) return false;
    _dragY.stop();
    _from = _dragY.value;
    _height = (_panelKey.currentContext?.size?.height ?? 1).clamp(1, double.infinity);
    _armed = false;
    setState(() => _dragging = true);
    return true;
  }

  /// Upward, where the content under the finger can scroll, it scrolls: the sheet stays.
  bool _onLock(double delta) {
    if (delta < 0 && _scroll.hasClients && _scroll.position.maxScrollExtent - _scroll.offset > 1) {
      return false;
    }
    return true;
  }

  void _onMove(double delta) {
    final offset = rubberBand(_from + delta, 0, double.infinity, SwipeFeel.rubberBand);
    if (!_reduceMotion) _dragY.value = offset;
    final past = offset >= _height * SwipeFeel.sheetCloseAt;
    if (past != _armed) {
      _armed = past;
      context.feedback(FeedbackEvent.thresholdCrossed);
    }
  }

  void _onRelease(double delta, double velocity, bool cancelled) {
    setState(() => _dragging = false);
    final offset = _from + delta;
    final closing =
        !cancelled &&
        (offset >= _height * SwipeFeel.sheetCloseAt ||
            (velocity >= SwipeFeel.flickVelocity && offset > 0));
    if (closing) {
      _close();
    } else {
      _springBack();
    }
  }

  void _onSettle() {
    if (_dragging) setState(() => _dragging = false);
    _springBack();
  }

  Map<Type, GestureRecognizerFactory> get _gestures => !_dismissible
      ? const {}
      : {
          SheetDragRecognizer: GestureRecognizerFactoryWithHandlers<SheetDragRecognizer>(
            SheetDragRecognizer.new,
            (recognizer) => recognizer
              ..onStart = _onStart
              ..onLock = _onLock
              ..onMove = _onMove
              ..onRelease = _onRelease
              ..onSettle = _onSettle,
          ),
        };

  // -- the layout ----------------------------------------------------------------------------

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.lk-grab`: 36 × 4, `stroke`, 4px under it.
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: colors.stroke,
              borderRadius: LkSurface.radius(LkRadius.pill),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: LukitasTokens.space2,
          children: [
            Flexible(
              child: Semantics(
                header: true,
                // Under whatever the sheet is wrapped in: its title may follow its state.
                child: Builder(
                  builder: (context) => BlinkLine(
                    style: LkText.title,
                    child: Text(
                      widget.titleOf?.call(context) ?? widget.title,
                      style: LkText.title.copyWith(color: colors.ink),
                    ),
                  ),
                ),
              ),
            ),
            if (_dismissible)
              PressButton.text(
                l10n.close,
                tone: PressTone.ghost,
                size: PressSize.sm,
                onPressed: _close,
              ),
          ],
        ),
      ],
    );
  }

  Widget _panel(BuildContext context) {
    final colors = context.lkColors;
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    final footer = widget.footer;
    final physics = _dragging ? const NeverScrollableScrollPhysics() : null;
    const side = LukitasTokens.space3;
    final toasts = const ToastSlot();

    final Widget content;
    if (footer == null) {
      // The whole sheet scrolls, `max-h-[90dvh] overflow-y-auto`. The toast's slot is the last
      // child of the flex column, so the gap above it counts even when it is empty.
      final stuck = widget.stuck;
      final bottom = safe > LukitasTokens.space4 ? safe : LukitasTokens.space4;
      final scroll = SingleChildScrollView(
        controller: _scroll,
        physics: physics,
        // With a stuck footer [_KeyEdgeClip] clips, a little under the scroll view's end.
        clipBehavior: stuck == null ? Clip.hardEdge : Clip.none,
        padding: EdgeInsets.fromLTRB(
          side,
          10,
          side,
          // With a stuck footer the form's gap is all that follows the content, then the footer.
          stuck == null ? bottom : widget.stuckGaps.form,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space2,
          children: [_header(context), ...widget.children, if (stuck == null) toasts],
        ),
      );
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screen.height * 0.9),
        child: stuck == null
            ? scroll
            // Laid out from the bottom up so the footer is first, and painted first: the scrolling
            // content paints over it, which lets the last key's solid edge (`0 3px 0`) show over the
            // footer's line instead of being cut at the scroll view's end (see [_KeyEdgeClip]).
            : Column(
                mainAxisSize: MainAxisSize.min,
                verticalDirection: VerticalDirection.up,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetFooter(
                    safeBottom: safe,
                    bottomGap: widget.stuckGaps.bottom,
                    children: stuck,
                  ),
                  Flexible(
                    child: ClipRect(
                      clipper: const _KeyEdgeClip(),
                      child: Stack(
                        children: [
                          scroll,
                          Positioned(left: side, right: side, bottom: 0, child: toasts),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    } else {
      // The header, what is pinned under it, a scrolling middle, then the footer, always in view.
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screen.height - LukitasTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space2,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(side, 10, side, 0), child: _header(context)),
            if (widget.pinned.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: side),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: LukitasTokens.space2,
                  children: widget.pinned,
                ),
              ),
            Flexible(child: _body(context, physics, toasts)),
            _SheetFooter(
              safeBottom: safe,
              compact: screen.height < compactFooterBelow,
              children: footer,
            ),
          ],
        ),
      );
    }

    // A `Material` gives the sheet's text the theme's style (a route has none above it).
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        key: _panelKey,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(LukitasTokens.radiusXl)),
        ),
        child: content,
      ),
    );
  }

  /// `.lk-sheet-body`: scrolls between the pinned part and the footer; scrolled away from its top it
  /// shows a divider and its content fades in under it.
  Widget _body(BuildContext context, ScrollPhysics? physics, Widget toasts) {
    final colors = context.lkColors;
    const side = LukitasTokens.space3;
    Widget scroll = SingleChildScrollView(
      controller: _scroll,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(side, 0, side, LukitasTokens.space1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    );
    if (_scrolled) {
      scroll = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, LukitasTokens.space4)),
        child: scroll,
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _scrolled ? colors.stroke : const Color(0x00000000), width: 2),
        ),
      ),
      child: Stack(
        children: [
          scroll,
          Positioned(left: side, right: side, bottom: 0, child: toasts),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final scrim = LkSurface.scrim(colors, Theme.of(context).brightness);
    final animation = widget.animation;
    final backdrop = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    // On the way out the parent runs from 1 to 0 and `reverseCurve` is applied to it as it is, so the
    // curve goes backwards: flipped, the sheet leaves fast and decelerates, as the web's exit does.
    final slide = CurvedAnimation(
      parent: animation,
      curve: _sheetEase,
      reverseCurve: _sheetEase.flipped,
    );
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    Widget panel = RawGestureDetector(
      gestures: _gestures,
      behavior: HitTestBehavior.translucent,
      child: _panel(context),
    );
    panel = _reduceMotion
        ? FadeTransition(opacity: slide, child: panel)
        : SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(slide),
            child: panel,
          );

    final page = LkSheetScope(
      hasFooter: widget.footer != null,
      child: Builder(
        builder: (context) => Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: widget.titleOf?.call(context) ?? widget.title,
          child: CallbackShortcuts(
            bindings: {if (_dismissible) const SingleActivator(LogicalKeyboardKey.escape): _close},
            child: Focus(
              autofocus: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: FadeTransition(
                      opacity: backdrop,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // Not dismissible: the backdrop still takes the tap, and does nothing.
                        onTap: _dismissible ? _close : () {},
                        child: ColoredBox(color: scrim),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: inset),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Transform.translate(offset: Offset(0, _dragY.value), child: panel),
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
    final wrapped = widget.wrap?.call(page) ?? page;
    if (widget.dismissible && widget.locked == null) return wrapped;
    // The system's back button: free while the person may close the sheet; otherwise the caller's
    // answer, or nothing, and nothing at all while it is locked. A pop from the app itself does not
    // come here.
    final locked = widget.locked?.value ?? false;
    return PopScope<Object?>(
      canPop: widget.dismissible && !locked,
      onPopInvokedWithResult: (didPop, _) {
        final answer = widget.backResult;
        if (!didPop && !locked && answer != null && widget.route.isCurrent) {
          Navigator.of(context).pop(answer());
        }
      },
      child: wrapped,
    );
  }
}

/// `.lk-sheet-footer` in a sheet with a pinned footer: full width under the scrolling body, a
/// 2px `stroke` line above it, the keypad's and the save button's place.
class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
    required this.children,
    required this.safeBottom,
    this.bottomGap = 0,
    this.compact = false,
  });

  final List<Widget> children;
  final double safeBottom;

  /// A phone up to 844 px tall: `.lk-sheet.has-footer .lk-sheet-footer { gap: var(--space-1);
  /// padding-top: var(--space-1) }`.
  final bool compact;

  /// Room under the footer's own padding (a stuck footer sits above the sheet's bottom padding).
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        LukitasTokens.space3,
        compact ? LukitasTokens.space1 : LukitasTokens.space2,
        LukitasTokens.space3,
        (safeBottom > LukitasTokens.space3 ? safeBottom : LukitasTokens.space3) + bottomGap,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.stroke, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: compact ? LukitasTokens.space1 : LukitasTokens.space2,
        children: children,
      ),
    );
  }
}

/// One finger's drag down on the sheet (the web's `useAxisDrag` with `axis: "y"`). It decides the
/// axis once the finger has moved past the slop: vertical only when the move is more vertical than
/// sideways. Vertical, it wins the gesture (a tap on a key never also fires) unless [onLock] hands
/// the touch to the content's scroll; sideways, it steps aside.
class SheetDragRecognizer extends OneSequenceGestureRecognizer {
  SheetDragRecognizer({super.debugOwner, super.supportedDevices});

  /// A finger came down on the sheet. Stop any spring here and return false to ignore the touch.
  bool Function()? onStart;

  /// The gesture just turned vertical, [delta] px so far: it is a drag from now on, unless this
  /// returns false (then the content's scroll takes it).
  bool Function(double delta)? onLock;

  /// Every move: `delta` px from where the finger came down.
  ValueChanged<double>? onMove;

  /// The drag ended: the finger's speed in px/s (0 when cancelled).
  void Function(double delta, double velocity, bool cancelled)? onRelease;

  /// The touch ended without becoming a drag: whatever [onStart] stopped must rest now.
  VoidCallback? onSettle;

  int? _pointer;
  Offset _origin = Offset.zero;
  Offset _last = Offset.zero;
  VelocityTracker? _tracker;
  bool _locked = false;
  bool _accepted = false;

  @override
  String get debugDescription => 'sheet drag';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    if (_pointer != null) return;
    _pointer = event.pointer;
    _origin = _last = event.position;
    _tracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    _locked = _accepted = false;
    if (!(onStart?.call() ?? true)) {
      _pointer = null;
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      _tracker?.addPosition(event.timeStamp, event.position);
      _last = event.position;
      final delta = event.position - _origin;
      if (!_locked) {
        switch (lockAxis(delta.dx, delta.dy, SwipeFeel.axisSlop)) {
          case null:
            return;
          case Axis2.x:
            _settle();
            resolve(GestureDisposition.rejected);
            stopTrackingPointer(event.pointer);
            return;
          case Axis2.y:
            if (!(onLock?.call(delta.dy) ?? true)) {
              _settle();
              resolve(GestureDisposition.rejected);
              stopTrackingPointer(event.pointer);
              return;
            }
            _locked = true;
            resolve(GestureDisposition.accepted);
        }
      }
      if (_accepted) onMove?.call(delta.dy);
    } else if (event is PointerUpEvent) {
      if (_accepted) {
        final dy = (_last - _origin).dy;
        final vy = _tracker?.getVelocity().pixelsPerSecond.dy ?? 0;
        _end();
        onRelease?.call(dy, vy, false);
      } else {
        _settle();
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      if (_accepted) {
        final dy = (_last - _origin).dy;
        _end();
        onRelease?.call(dy, 0, true);
      } else {
        _settle();
      }
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != _pointer) return;
    _accepted = true;
    onMove?.call((_last - _origin).dy);
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer != _pointer) return;
    // Another recognizer won before this became a drag.
    _settle();
    stopTrackingPointer(pointer);
  }

  void _end() {
    _pointer = null;
    _locked = _accepted = false;
  }

  void _settle() {
    if (_pointer == null) return;
    _pointer = null;
    _locked = _accepted = false;
    onSettle?.call();
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
