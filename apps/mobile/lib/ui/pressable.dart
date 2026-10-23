import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;

import '../theme/tokens.g.dart';
import 'pixel_snap.dart';

/// What a [Pressable] tells the widget it builds.
@immutable
class PressState {
  const PressState({required this.pressed, required this.focusVisible, required this.enabled});

  /// A finger (or the pointer) is down on it: the web's `:active` and `.is-pressed`.
  final bool pressed;

  /// It has keyboard focus and the person is using a keyboard: the web's `:focus-visible`.
  final bool focusVisible;

  /// It can be pressed (it has an `onPressed`).
  final bool enabled;
}

/// The behaviour every pressable thing of the web's UI shares (apps/web/app/styles/app.css:
/// `.lk-btn`, `.lk-step`, `.lk-seg button`, `.lk-chip-button`, `.lk-badge`):
///
/// - [onPressed] on a tap, and on Enter or Space when it has keyboard focus; without it the thing
///   is disabled: not focusable and not pressable.
/// - [PressState.pressed] from the moment a finger lands, and for at least the web's `--press`
///   (80 ms) so a quick tap still shows it sinking.
/// - [PressState.focusVisible] only while the person uses a keyboard (the web's `:focus-visible`):
///   on a phone a tap never draws a focus ring, a keyboard or switch access does.
/// - Semantics: a button (or a link), enabled or not, named by its content or by [label].
///
/// How it looks is the builder's job; [PressSurface] is what most of them build.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.label,
    this.link = false,
    this.selected,
    this.liveRegion = false,
    this.role,
    this.onFocusChange,
    this.hint,
    this.keepChildSemantics = false,
  });

  final Widget Function(BuildContext context, PressState state) builder;

  /// Called on a tap or an activation key; null disables the pressable.
  final VoidCallback? onPressed;

  final FocusNode? focusNode;
  final bool autofocus;

  /// The accessible name, when the content's text is not it (the web's `aria-label`).
  final String? label;

  /// A link (it goes somewhere), not a button.
  final bool link;

  /// A toggle's state (the web's `aria-pressed` / `aria-selected`); null for a plain button.
  final bool? selected;

  /// Announces changes of its name politely (the web's `aria-live="polite"`).
  final bool liveRegion;

  /// The ARIA-like role, for a control that is not just a button (a tab).
  final SemanticsRole? role;

  /// Called when the focus enters or leaves.
  final ValueChanged<bool>? onFocusChange;

  /// What the control does beyond its name (the web's `aria-describedby`).
  final String? hint;

  /// With a [label]: the content's own semantics stay as separate nodes under the control instead
  /// of being dropped, for a card that holds a button of its own (a row with a pending badge, as
  /// the web's row-hit button lies under the badge). The content must then leave out what [label]
  /// already says.
  final bool keepChildSemantics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;
  var _focusVisible = false;
  Timer? _release;
  DateTime? _downAt;
  var _hasFocus = false;
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  bool get _enabled => widget.onPressed != null;

  void _down() {
    _release?.cancel();
    _downAt = DateTime.now();
    if (!_pressed) setState(() => _pressed = true);
  }

  /// Lets go, but not before the press has been shown for `--press`: a quick tap still sinks.
  void _up() {
    final shownFor = _downAt == null ? Duration.zero : DateTime.now().difference(_downAt!);
    final left = LukitasTokens.durationPress - shownFor;
    _release?.cancel();
    if (left <= Duration.zero) {
      _letGo();
    } else {
      _release = Timer(left, _letGo);
    }
  }

  void _letGo() {
    if (mounted && _pressed) setState(() => _pressed = false);
  }

  @override
  void initState() {
    super.initState();
    _node.canRequestFocus = _enabled;
    _node.addListener(_nodeChanged);
  }

  /// A control that holds another (a row with a badge) is focused while the one inside has the
  /// focus, but only the one that has it rings, as `:focus-visible` does.
  void _nodeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(Pressable old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownNode)?.removeListener(_nodeChanged);
      _node.addListener(_nodeChanged);
    }
    if (!_enabled && _pressed) _letGo();
    // A disabled control cannot take the focus (a node of our own or the caller's: `Focus` only
    // applies its `canRequestFocus` to a node it makes itself).
    _node.canRequestFocus = _enabled;
  }

  @override
  void dispose() {
    _release?.cancel();
    _node.removeListener(_nodeChanged);
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = PressState(
      pressed: _pressed && _enabled,
      focusVisible: _focusVisible && _enabled && _node.hasPrimaryFocus,
      enabled: _enabled,
    );
    final named = widget.label != null;
    final detector = FocusableActionDetector(
      enabled: _enabled,
      focusNode: _node,
      autofocus: widget.autofocus,
      mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onShowFocusHighlight: (shown) => setState(() => _focusVisible = shown),
      onFocusChange: (focused) {
        setState(() => _hasFocus = focused);
        widget.onFocusChange?.call(focused);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _down() : null,
        onTapUp: _enabled ? (_) => _up() : null,
        onTapCancel: _enabled ? _up : null,
        onTap: widget.onPressed,
        child: widget.builder(context, state),
      ),
    );
    final semantics = Semantics(
      button: !widget.link,
      link: widget.link,
      enabled: _enabled,
      // `Focus` says so for a control whose content names it; a label drops the content (and
      // with it `Focus`'s own semantics), so then it is said here.
      focusable: named ? _enabled : null,
      focused: named ? _hasFocus : null,
      onFocus: named && _enabled ? _node.requestFocus : null,
      label: widget.label,
      hint: widget.hint,
      selected: widget.selected,
      liveRegion: widget.liveRegion,
      role: widget.role,
      onTap: widget.onPressed,
      // A label is the control's whole name (the web's `aria-label`); without one its content is.
      excludeSemantics: named && !widget.keepChildSemantics,
      container: widget.keepChildSemantics,
      child: detector,
    );
    return named ? semantics : MergeSemantics(child: semantics);
  }
}

/// [child] with the web's focus ring around it while [radius] is set: 3px of [color], [offset] px
/// out from [child]'s edge (`outline: 3px solid var(--focus); outline-offset: 2px`). An outline
/// follows the corners of the box it surrounds, pushed out by its distance and width.
class RingBox extends StatelessWidget {
  const RingBox({
    super.key,
    required this.radius,
    required this.color,
    required this.child,
    this.offset = 2,
  });

  /// The corners of [child]'s box; null draws no ring.
  final BorderRadius? radius;
  final Color color;

  /// How far the ring sits from the edge: 2px for focus, 1px for a chip's selected outline.
  final double offset;

  final Widget child;

  static const width = 3.0;

  @override
  Widget build(BuildContext context) {
    final radius = this.radius;
    final out = offset + width;
    Radius grow(Radius r) => Radius.circular(r.x + out);
    // The same tree with the ring and without it: [child] keeps its place (and its state, a pending
    // badge's, say) when the ring comes and goes.
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        if (radius != null)
          Positioned(
            left: -out,
            top: -out,
            right: -out,
            bottom: -out,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: grow(radius.topLeft),
                    topRight: grow(radius.topRight),
                    bottomLeft: grow(radius.bottomLeft),
                    bottomRight: grow(radius.bottomRight),
                  ),
                  border: Border.all(color: color, width: width),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A surface that sinks into its edge while pressed (the web's `transition: transform 80ms ease,
/// box-shadow 80ms ease` with `translateY` and a 1px edge on `:active`): [decoration] and
/// [pressDy] change with the press and animate over `--press`, or at once with the system's
/// "remove animations" (the web's `prefers-reduced-motion`). It is at least 44 × 44 (`min-h-11
/// min-w-11`), with [child] centred in it.
///
/// While [ringRadius] is set it draws the web's focus ring around it: 3px in the theme's `focus`
/// colour, 2px out from the edge (`outline: 3px solid var(--focus); outline-offset: 2px`), moving
/// with the surface.
class PressSurface extends StatelessWidget {
  const PressSurface({
    super.key,
    required this.decoration,
    required this.child,
    this.pressDy = 0,
    this.padding = EdgeInsets.zero,
    this.minSize = 44,
    this.ringRadius,
    this.ringColor,
    this.ringOffset = 2,
    this.outsideShadow = const [],
  });

  /// A shadow drawn only outside the box (see [OutsideShadow]), for a see-through surface.
  final List<BoxShadow> outsideShadow;

  /// How it looks now (its colour, border, radius and edge shadow).
  final BoxDecoration decoration;

  /// How far it sits below its resting place (0 resting; 3 or 5 pressed).
  final double pressDy;

  final EdgeInsetsGeometry padding;

  /// The smallest width and height: the web's 44px targets. Zero for none.
  final double minSize;

  final Widget child;

  /// The radius of the surface's corners, when the focus ring shows.
  final BorderRadius? ringRadius;

  /// The ring's colour (the theme's `focus`).
  final Color? ringColor;

  /// How far the ring sits from the edge (2px; a chip's selected outline sits 1px out).
  final double ringOffset;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : LukitasTokens.durationPress;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.ease,
      transform: Matrix4.translationValues(0, pressDy, 0),
      child: RingBox(
        radius: ringRadius,
        color: ringColor ?? const Color(0x00000000),
        offset: ringOffset,
        child: OutsideShadow(
          shadows: outsideShadow,
          radius: (decoration.borderRadius ?? BorderRadius.zero).resolve(TextDirection.ltr),
          child: TweenAnimationBuilder<Decoration>(
            tween: DecorationTween(end: decoration),
            duration: duration,
            curve: Curves.ease,
            builder: (context, animated, child) => SnappedDecoratedBox(
              decoration: animated,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
                // A border takes room inside the box, as a container adds it.
                child: Padding(padding: padding.add(animated.padding), child: child),
              ),
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

/// A box shadow as CSS draws it: only outside the box. Flutter paints a shadow under the whole box,
/// so a see-through box (the pending badge's) would show it through. [child] is the box.
class OutsideShadow extends StatelessWidget {
  const OutsideShadow({
    super.key,
    required this.shadows,
    required this.radius,
    required this.child,
  });

  final List<BoxShadow> shadows;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.passthrough,
    children: [
      if (shadows.isNotEmpty)
        Positioned.fill(
          child: ClipPath(
            clipper: _OutsideClipper(radius),
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
            ),
          ),
        ),
      child,
    ],
  );
}

class _OutsideClipper extends CustomClipper<Path> {
  const _OutsideClipper(this.radius);

  final BorderRadius radius;

  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect((Offset.zero & size).inflate(200)),
    Path()..addRRect(radius.toRRect(Offset.zero & size)),
  );

  @override
  bool shouldReclip(_OutsideClipper old) => old.radius != radius;
}
