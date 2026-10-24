// The web's Toast (apps/web/app/ui/Toast.tsx) and the CSS it uses: app.css `.lk-toast`,
// `.lk-toast-actions`, `.lk-toast-progress`, and the toast rules of the "Feel pass" section.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../feedback/celebration.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'lk_theme.dart';
import 'pressable.dart';
import 'swipe_rules.dart';

/// A toast's action: a verb in sentence case (`Deshacer`, `Ponerle nombre`).
class ToastAction {
  const ToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// `error` is outlined in `over` (and announced assertively on the web).
enum ToastTone { info, error }

/// What a toast says and offers (the web's `ToastOptions`).
class ToastOptions {
  const ToastOptions({
    required this.message,
    this.actions = const [],
    this.tone = ToastTone.info,
    this.persistent = false,
  });

  /// A toast whose message is plain text.
  ToastOptions.text(
    String message, {
    this.actions = const [],
    this.tone = ToastTone.info,
    this.persistent = false,
  }) : message = Text(message);

  /// What changed, with the amount: `Supermercado · −6,08 €`.
  final Widget message;
  final List<ToastAction> actions;
  final ToastTone tone;

  /// Stays until an action is taken, it is swiped away or another toast replaces it: no countdown.
  /// For an error whose action keeps something that would otherwise be lost (Reintentar).
  final bool persistent;
}

/// A message, as a screen says it (the web's `toast.show({ message })`), with up to two actions: an
/// [extraLabel] ("Ponerle nombre") and, after it, the [actionLabel] ("Deshacer").
extension ToastSay on ToastController {
  void say(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    String? extraLabel,
    VoidCallback? onExtra,
    bool error = false,
  }) => show(
    ToastOptions.text(
      message,
      tone: error ? ToastTone.error : ToastTone.info,
      actions: [
        if (extraLabel != null && onExtra != null)
          ToastAction(label: extraLabel, onPressed: onExtra),
        if (actionLabel != null && onAction != null)
          ToastAction(label: actionLabel, onPressed: onAction),
      ],
    ),
  );
}

/// How long a toast without actions stays, unless a finger or focus is on it.
const _toastLife = Duration(seconds: 5);

/// Where a swiped toast goes: sideways ±360 px, or 120 px down.
typedef _Leave = Offset;

/// Shows the toasts, one at a time (the web's `ToastProvider`): a new one replaces the current one
/// (so only the latest action can be undone). A toast with an action stays 8 seconds (`--undo`),
/// one without 5; a thin bar shows the time left. The countdown stops while a finger, the pointer
/// or focus is on the toast, and resumes where it was. A toast also leaves when an action is taken
/// or when it is swiped down or sideways.
///
/// Put one above the app's Navigator (`MaterialApp.builder`) so sheets can host the toasts while
/// they are open ([LkSheet] does: outside a modal sheet a toast would be unreachable for assistive
/// technology). Show one with `ToastHost.of(context).show(...)`.
class ToastHost extends StatefulWidget {
  const ToastHost({
    super.key,
    required this.child,
    this.dismissAfter,
    this.lift = 0,
    this.animateBar = true,
  });

  final Widget child;

  /// Whether the time bar runs. For tests only: a running bar asks for a frame all the way to the
  /// toast's end, so a test that waits for the frames to stop (`pumpAndSettle`) waits the whole
  /// life of the toast out. Without it the toast leaves on its timer alone, as a snackbar did.
  final bool animateBar;

  /// Replaces how long every toast stays. For tests only (the web's `dismissAfterMs`); the bar
  /// keeps showing the real time.
  final Duration? dismissAfter;

  /// How far the toasts sit above the bottom (the web's `--toast-lift`: 92 on phones, above the
  /// bottom bar).
  final double lift;

  /// The host above [context]; fails without one.
  static ToastController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'ToastHost.of needs a ToastHost above it');
    return controller!;
  }

  static ToastController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ToastScope>()?.controller;

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> with TickerProviderStateMixin {
  late final ToastController _controller = ToastController._(this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller._reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller._dismissAfter = widget.dismissAfter;
    _controller._animateBar = widget.animateBar;
    return _ToastScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              // Inside an open sheet only while there is a toast; otherwise at the bottom.
              if (_controller._sheets > 0 || _controller.toast == null) {
                return const SizedBox.shrink();
              }
              final safe = MediaQuery.viewPaddingOf(context).bottom;
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    LukitasTokens.space4,
                    0,
                    LukitasTokens.space4,
                    (safe > LukitasTokens.space4 ? safe : LukitasTokens.space4) +
                        widget.lift +
                        _controller._lift,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: const ToastLayer(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.controller, required super.child});

  final ToastController controller;

  @override
  bool updateShouldNotify(_ToastScope old) => old.controller != controller;
}

/// What a [ToastHost] shows and does: [show] a toast, [dismiss] it.
class ToastController extends ChangeNotifier {
  ToastController._(TickerProvider vsync)
    : _enter = AnimationController(vsync: vsync, duration: LukitasTokens.durationSheet),
      _bar = AnimationController(vsync: vsync),
      _snap = AnimationController(vsync: vsync, duration: LukitasTokens.durationSheet) {
    _enter.addListener(notifyListeners);
    _snap.addListener(_snapped);
  }

  final AnimationController _enter;
  final AnimationController _bar;
  final AnimationController _snap;

  /// The toast on screen, or on its way out.
  ToastOptions? toast;
  ToastOptions? _next;
  _Leave? _leave;
  Timer? _timer;
  Duration? _dismissAfter;
  bool _reduceMotion = false;
  bool _paused = false;
  bool _animateBar = true;
  int _sheets = 0;
  double _lift = 0;

  /// How far the toast is dragged from where it rests.
  Offset _drag = Offset.zero;
  Offset _snapFrom = Offset.zero;
  Offset _dragTotal = Offset.zero;

  Duration _life(ToastOptions options) =>
      options.actions.isEmpty ? _toastLife : LukitasTokens.durationUndo;

  /// Shows [options] now, or as soon as the toast on screen has left (the web's `mode="wait"`).
  void show(ToastOptions options) {
    _next = options;
    if (toast == null) {
      _swap();
    } else {
      _beginExit(null);
    }
  }

  /// Puts the toast away (as taking an action does).
  void dismiss() {
    _next = null;
    if (toast != null) _beginExit(null);
  }

  void _swap() {
    final options = _next;
    _next = null;
    if (options == null) return;
    toast = options;
    _leave = null;
    _drag = Offset.zero;
    _paused = false;
    _timer?.cancel();
    _enter.forward(from: 0);
    if (!options.persistent) {
      _bar
        ..duration = _life(options)
        ..value = 0;
      if (_animateBar) _bar.forward();
      _schedule(options);
    }
    notifyListeners();
  }

  void _schedule(ToastOptions options) {
    _timer?.cancel();
    final natural = _life(options);
    final life = _dismissAfter ?? natural;
    // What is left of [life] after what the bar has already run of [natural] (the same thing
    // unless a test replaced the life).
    final left = life - Duration(milliseconds: (natural.inMilliseconds * _bar.value).round());
    _timer = Timer(left.isNegative ? Duration.zero : left, dismiss);
  }

  void _beginExit(_Leave? leave) {
    _timer?.cancel();
    _bar.stop();
    _leave = leave;
    _snap.stop();
    final done = _enter.reverse();
    notifyListeners();
    done.whenComplete(() {
      // Another toast may have started meanwhile (a show during the exit).
      if (_enter.status != AnimationStatus.dismissed) return;
      toast = null;
      _drag = Offset.zero;
      if (_next != null) {
        _swap();
      } else {
        notifyListeners();
      }
    });
  }

  /// A finger, the pointer or focus is on the toast: its countdown stops.
  void _pause() {
    final options = toast;
    if (options == null || options.persistent || _paused) return;
    _paused = true;
    _timer?.cancel();
    _bar.stop();
  }

  void _resume() {
    final options = toast;
    if (options == null || options.persistent || !_paused) return;
    _paused = false;
    if (_animateBar) _bar.forward();
    _schedule(options);
  }

  // -- the drag ------------------------------------------------------------------------------

  /// `dragElastic={{ top: 0.1, bottom: 0.8, left: 0.8, right: 0.8 }}` with constraints of zero.
  void _dragUpdate(Offset total) {
    _snap.stop();
    _drag = Offset(total.dx * 0.8, total.dy < 0 ? total.dy * 0.1 : total.dy * 0.8);
    notifyListeners();
  }

  void _dragEnd(Offset total, Offset velocity) {
    const far = SwipeFeel.toastDismiss;
    const fast = SwipeFeel.flickVelocity;
    final down = _drag.dy > far || velocity.dy > fast;
    final side = (_drag.dx.abs() > far || velocity.dx.abs() > fast)
        ? (_drag.dx != 0 ? _drag.dx.sign : velocity.dx.sign)
        : 0.0;
    if (!down && side == 0) {
      _snapFrom = _drag;
      _snap.forward(from: 0);
      return;
    }
    _beginExit(side != 0 ? Offset(side * 360, 0) : const Offset(0, 120));
  }

  void _snapped() {
    _drag = Offset.lerp(_snapFrom, Offset.zero, Curves.easeOut.transform(_snap.value))!;
    notifyListeners();
  }

  /// A modal sheet is open and hosts the toasts in itself (see [ToastSlot]); returns what to call
  /// when it closes.
  VoidCallback attachSheet() {
    _sheets++;
    _notifyAfterBuild();
    var attached = true;
    return () {
      if (!attached) return;
      attached = false;
      _sheets--;
      _notifyAfterBuild();
    };
  }

  /// The app's bottom bar is on screen: the toasts sit [by] higher, above it (the web's
  /// `--toast-lift`, set while `.lk-app-shell` is on the page); returns what to call when it goes.
  VoidCallback liftBy(double by) {
    _lift += by;
    _notifyAfterBuild();
    var lifted = true;
    return () {
      if (!lifted) return;
      lifted = false;
      _lift -= by;
      _notifyAfterBuild();
    };
  }

  var _disposed = false;

  /// A sheet comes and goes while the tree is building or being torn down: the layers hear of it
  /// after the frame.
  void _notifyAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _enter.dispose();
    _bar.dispose();
    _snap.dispose();
    super.dispose();
  }
}

/// Where the host draws its toast (at the bottom of the screen, or inside an open sheet): the
/// toast on screen, entering, leaving or at rest. Empty without one.
class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ToastHost.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller._bar]),
      builder: (context, _) {
        final options = controller.toast;
        if (options == null) return const SizedBox.shrink();
        final t = Curves.easeInOut.transform(controller._enter.value);
        // Entering and leaving the way it was thrown (a fade only, under reduced motion).
        final away = controller._leave;
        final rest = controller._reduceMotion ? Offset.zero : const Offset(0, 16);
        final gone = away != null && !controller._reduceMotion ? away : rest;
        final offset = Offset.lerp(gone, controller._drag, t)!;
        // Lukitas celebrates clear of the toasts: their layout box, not where a slide puts them.
        return CelebrationAvoid(
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: offset,
                child: _ToastBox(controller: controller, options: options),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A toast's place inside a modal sheet (the web's toast slot of `Sheet`): while the sheet is open
/// the toast shows here.
class ToastSlot extends StatefulWidget {
  const ToastSlot({super.key});

  @override
  State<ToastSlot> createState() => _ToastSlotState();
}

class _ToastSlotState extends State<ToastSlot> {
  VoidCallback? _detach;
  ToastController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ToastHost.maybeOf(context);
    if (controller == _controller) return;
    _detach?.call();
    _controller = controller;
    _detach = controller?.attachSheet();
  }

  @override
  void dispose() {
    _detach?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.toast == null
          ? const SizedBox.shrink()
          : const Padding(
              padding: EdgeInsets.only(top: LukitasTokens.space2),
              child: ToastLayer(),
            ),
    );
  }
}

class _ToastBox extends StatelessWidget {
  const _ToastBox({required this.controller, required this.options});

  final ToastController controller;
  final ToastOptions options;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final error = options.tone == ToastTone.error;
    final radius = LkSurface.radius(LkRadius.lg);
    // `.lk-toast { overflow: hidden }` clips the bar inside the rounded corners (and inside the
    // border of an error toast); the edge shadow stays outside.
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        children: [
          Expanded(
            child: DefaultTextStyle.merge(
              style: LkText.toast.copyWith(color: colors.ink, decoration: TextDecoration.none),
              child: options.message,
            ),
          ),
          if (options.actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                for (final action in options.actions)
                  _ToastActionButton(
                    action: action,
                    onPressed: () {
                      // Dismiss first: an action may show a follow-up toast, which must win.
                      controller.dismiss();
                      action.onPressed();
                    },
                  ),
              ],
            ),
        ],
      ),
    );
    final box = Stack(
      children: [
        content,
        if (!options.persistent)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 3,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: FractionallySizedBox(
                  widthFactor: (1 - controller._bar.value).clamp(0.0, 1.0),
                  child: ColoredBox(color: error ? colors.over : colors.brand),
                ),
              ),
            ),
          ),
      ],
    );
    return MouseRegion(
      onEnter: (_) => controller._pause(),
      onExit: (_) => controller._resume(),
      child: Listener(
        onPointerDown: (_) => controller._pause(),
        onPointerUp: (event) {
          if (event.kind != PointerDeviceKind.mouse) controller._resume();
        },
        onPointerCancel: (_) => controller._resume(),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (focused) => focused ? controller._pause() : controller._resume(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => controller._dragTotal = Offset.zero,
            onPanUpdate: (details) {
              controller._dragTotal += details.delta;
              controller._dragUpdate(controller._dragTotal);
            },
            onPanEnd: (details) =>
                controller._dragEnd(controller._dragTotal, details.velocity.pixelsPerSecond),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: colors.surface,
                boxShadow: LkSurface.edgeShadow(lk, LkEdge.md),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: error ? Border.all(color: colors.over, width: 2) : null,
                  ),
                  child: error ? Padding(padding: const EdgeInsets.all(2), child: box) : box,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastActionButton extends StatelessWidget {
  const _ToastActionButton({required this.action, required this.onPressed});

  final ToastAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return Pressable(
      onPressed: onPressed,
      builder: (context, state) => RingBox(
        radius: state.focusVisible ? BorderRadius.zero : null,
        color: colors.focus,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : LukitasTokens.durationPress,
          curve: Curves.ease,
          transform: Matrix4.translationValues(0, state.pressed ? 2 : 0, 0),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          child: Text(
            action.label,
            style: LkText.toastAction.copyWith(
              color: colors.focus,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
