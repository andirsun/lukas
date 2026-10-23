import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add/add_sheet.dart';
import '../api/session.dart';
import '../capture/capture_sheet.dart';
import '../home/home_controller.dart';
import '../router.dart';

/// What a `lukitas://` link asks for (spec section 7.1): the widget's ＋ (`lukitas://add`, the add
/// sheet with the keypad ready) and its 🎤, also the Quick Settings tile's (`lukitas://capture`,
/// quick capture listening). `lukitas://due` is the "Hoy vence…" notice's (spec section 7.2): home,
/// where the payments due today are listed first. `lukitas://progress` is the guest warning's:
/// "Guarda tu progreso", over home.
enum LaunchAction { add, capture, due, progress }

/// The action [link] asks for, or null for any other link.
LaunchAction? launchActionOf(String? link) {
  final uri = Uri.tryParse(link ?? '');
  if (uri == null || uri.scheme != 'lukitas') return null;
  if (uri.path.isNotEmpty && uri.path != '/') return null;
  return switch (uri.host) {
    'add' => LaunchAction.add,
    'capture' => LaunchAction.capture,
    'due' => LaunchAction.due,
    'progress' => LaunchAction.progress,
    _ => null,
  };
}

/// Where `lukitas://` links come from: Android (MainActivity.kt) keeps them away from the router
/// and hands them over here. Tests replace it.
abstract interface class LaunchLinkSource {
  /// The link the app was started with (a cold start from the widget or the tile), once; null when
  /// there was none or it was already taken.
  Future<String?> takeInitial();

  /// Links that arrive while the app runs (the widget tapped with the app in the background).
  Stream<String> get links;
}

/// [LaunchLinkSource] over the `lukitas/launch` channel. Android keeps the latest link until it is
/// taken; it says `linkArrived` when one comes in while the app runs, and the link is then taken.
/// A link that comes before Dart listens is taken at the start instead, so none is lost.
class ChannelLaunchLinkSource implements LaunchLinkSource {
  ChannelLaunchLinkSource() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'linkArrived') return;
      final link = await _take();
      if (link != null) _links.add(link);
    });
  }

  static const _channel = MethodChannel('lukitas/launch');
  final _links = StreamController<String>.broadcast();

  Future<String?> _take() async {
    try {
      return await _channel.invokeMethod<String>('take');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> takeInitial() => _take();

  @override
  Stream<String> get links => _links.stream;
}

final launchLinkSourceProvider = Provider<LaunchLinkSource>((ref) => ChannelLaunchLinkSource());

/// Opens what a `lukitas://` link asks for, at a cold start too: it waits for the stored session to
/// be read, then, signed in, goes to home (closing whatever sheet or screen was open) and opens
/// the add sheet or quick capture listening there. Signed out it does nothing: the router already
/// shows the entry screen. Nor does it while an add sheet holds the person's input: that is kept.
class LaunchLinks {
  LaunchLinks(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _subscription;

  void _start() {
    final source = _ref.read(launchLinkSourceProvider);
    _subscription = source.links.listen((link) => unawaited(open(link)));
    unawaited(source.takeInitial().then((link) => link == null ? null : open(link)));
  }

  /// Opens what [link] asks for; does nothing for any other link.
  Future<void> open(String link) async {
    final action = launchActionOf(link);
    if (action == null) return;
    await _ref.read(sessionProvider.notifier).ready;
    if (_ref.read(sessionProvider).status != SessionStatus.signedIn) return;
    // An add or edit sheet with the person's input in it is never thrown away for a link: the
    // link is dropped, and the sheet stays as it was (the app only comes to the front).
    if (_ref.read(sheetsWithInputProvider).any) return;
    final router = _ref.read(routerProvider);
    router.go('/');
    // Home must be the page under the sheet before it opens: a sheet opened over the loading screen
    // would go with it. The router takes a frame or two to get there.
    for (var frame = 0; frame < 30 && router.state.uri.path != '/'; frame++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    await WidgetsBinding.instance.endOfFrame;
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    // A sheet or dialog already open with nothing typed in it (an earlier link, the person's own
    // tap) gives way.
    Navigator.of(context).popUntil((route) => route.isFirst);
    switch (action) {
      case LaunchAction.add:
        unawaited(openAddSheet(context));
      case LaunchAction.capture:
        unawaited(openCapture(context, listen: true));
      case LaunchAction.due:
        // Home is the destination: today's payments sit at the top of its list. A home that was
        // already loaded is brought up to date, so the payment that fell due overnight is there.
        if (_ref.exists(homeProvider)) unawaited(_ref.read(homeProvider.notifier).refresh());
      case LaunchAction.progress:
        // Only a guest has a progress to save; an account that has since claimed an email is on
        // home already.
        if (_ref.read(sessionProvider).isGuest) unawaited(router.push('/progress'));
    }
  }
}

/// Started by the app at once (app.dart), so a link the app was started with is not missed.
final launchLinksProvider = Provider<LaunchLinks>((ref) {
  final links = LaunchLinks(ref).._start();
  ref.onDispose(() => unawaited(links._subscription?.cancel()));
  return links;
});
