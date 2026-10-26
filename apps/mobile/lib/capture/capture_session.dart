import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add/add_repository.dart';
import '../add/add_sheet.dart' show SheetsWithInput, sheetsWithInputProvider;
import '../add/idempotency_key.dart';
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../home/saved_feedback.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../ui/toast.dart';
import 'capture_language.dart';
import 'capture_note.dart';
import 'capture_repository.dart';
import 'capture_save.dart';
import 'engine/speech_engine.dart';
import 'models_download.dart';
import 'parser/parse.dart' as p;
import 'preview/capture_preview.dart';

/// What a 🎤 link can ask of the capture sheet that is open.
abstract interface class CaptureLinkTarget {
  /// The person tapped 🎤 (the widget's, the tile's) with this sheet open: brings it to listening
  /// when it can, without stacking a second sheet and without losing what it holds.
  void listenFromLink();
}

/// The capture sheet open now. A plain registry, not state: read when a 🎤 link arrives
/// (lib/launch/launch_links.dart), never watched.
class OpenCaptureSheets {
  final _open = <CaptureLinkTarget>[];

  void add(CaptureLinkTarget sheet) => _open.add(sheet);

  void remove(CaptureLinkTarget sheet) => _open.remove(sheet);

  /// Hands the 🎤 link to the open capture sheet; false when none is open.
  bool listenFromLink() {
    if (_open.isEmpty) return false;
    _open.last.listenFromLink();
    return true;
  }
}

final openCaptureSheetsProvider = Provider<OpenCaptureSheets>((ref) => OpenCaptureSheets());

enum CaptureStage { starting, offer, downloading, listening, typing, preview }

/// Why the typing field shows instead of listening: one sentence over it.
enum CaptureWhy { micDenied, noEngine, noVoiceYet, listenFailed, nothingHeard, nothingRead }

/// What the capture sheet's parts (the listening, the typing field, the voice download, the preview
/// and the footer under them) share while it is open: the stage, the engine, the preview and the
/// save. [CaptureSession.of] gives a part this state and rebuilds it when anything in it changes.
/// The sheet itself is [LkSheet] (lib/ui/sheet.dart): this wraps it (`LkSheet.show(wrap: ...)`),
/// so it lives and dies with the sheet's route.
///
/// Built by `openCapture`. [listen] false opens on the typing field.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key, this.listen = true, required this.child});

  final bool listen;
  final Widget child;

  @override
  ConsumerState<CaptureSheet> createState() => CaptureSheetState();
}

class CaptureSheetState extends ConsumerState<CaptureSheet>
    with WidgetsBindingObserver
    implements CaptureLinkTarget {
  /// The words, for the parts to read (set at every build).
  late AppLocalizations l10n;

  /// What home holds now: the categories, the currency and the time zone are in its figures.
  HomeState home = const HomeState();
  var _version = 0;

  var stage = CaptureStage.starting;
  CaptureWhy? why;
  var canListen = false;
  final field = TextEditingController();
  final fieldFocus = FocusNode();

  StreamSubscription<String>? _listening;
  var heard = '';

  /// The engine has loaded its model and the microphone records: "¿En qué gastaste?" shows only
  /// then, so the start of a sentence is not lost. When the engine is [_warm] it shows from the tap:
  /// the microphone starts within a few milliseconds, and what is said while the recognizers attach
  /// is buffered (VoiceChannel.kt), so no "preparing" state is shown at all.
  var ready = false;

  /// The engine's model was loaded when the sheet opened (or has been since): listening starts at
  /// once.
  var _warm = false;

  /// A transcript that came before home's figures did: read once they are here.
  String? _pending;

  CancelToken? _download;
  var downloaded = 0;
  ModelDownloadFailure? downloadFailure;

  CapturePreview? preview;
  List<p.Usual> _usual = const [];
  int? openCard;

  var saving = false;
  HomeFailure? failure;

  /// One Idempotency-Key per request body ([batchFingerprint]) for the sheet's life: Reintentar, a
  /// change that changes nothing, or a change and its undoing (A, B, then A again) all send the
  /// key that body was first sent with, so a lost answer can never become a second set of rows.
  final _keys = <String, String>{};

  /// Listening waits for the app to be in front again (opened, or the engine answered, while it
  /// was in the background): the microphone never opens unseen.
  var _listenWhenBack = false;

  /// What was in the typing field when listening started (a 🎤 link or "Hablar" over typed text):
  /// kept in the field meanwhile, and read together with what is said.
  var _kept = '';

  /// Read once here: dispose may not use ref.
  late final SheetsWithInput _withInput;
  late final OpenCaptureSheets _openSheets;

  SpeechEngine get engine => ref.read(speechEngineProvider);

  @override
  void initState() {
    super.initState();
    _withInput = ref.read(sheetsWithInputProvider);
    _openSheets = ref.read(openCaptureSheetsProvider)..add(this);
    field.addListener(_markInput);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_fetchUsual());
    // Whether the first-use note shows is known once the kept flag has been read.
    unawaited(ref.read(captureNoteProvider.notifier).ready.then((_) => _set(() {})));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    _openSheets.remove(this);
    _withInput.mark(this, hasInput: false);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_listening?.cancel());
    _download?.cancel();
    preview?.dispose();
    field.dispose();
    fieldFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _listenWhenBack) {
      _listenWhenBack = false;
      listen();
      return;
    }
    // In the background the microphone is let go at once (Kotlin also stops on onStop); what was
    // heard stays in the typing field. Coming back does not listen by itself.
    if ((state == AppLifecycleState.hidden || state == AppLifecycleState.paused) &&
        stage == CaptureStage.listening) {
      type(null, text: heard.trim().isEmpty ? null : _spoken(heard));
    }
  }

  /// Opens the card [id] to change it, closes the one that was open, or (null) closes it.
  void openCardOnly(int? id) => _set(() => openCard = id);

  Future<void> refreshHome() => ref.read(homeProvider.notifier).refresh();

  /// Whether the explanation of where the voice goes still shows (the first use only).
  bool get noteActive => ref.read(captureNoteProvider.notifier).active;

  /// The microphone's level, live, while listening.
  Stream<double> get levels => engine.levels;

  /// The voice model of the app's language: its size is shown before it is downloaded. Null when the
  /// language has none ([hasVoice]); never another language's.
  VoiceModel? get model => ref.read(modelStoreProvider).modelFor(locale);

  /// Whether the app's language has a voice model at all. Italian and Portuguese have none yet:
  /// the sheet then opens on the typing field, as it does when the phone cannot listen.
  bool get hasVoice => ref.read(modelStoreProvider).hasModel(locale);

  void cancelDownload() => _download?.cancel();

  void _set(VoidCallback change) {
    if (!mounted) return;
    setState(change);
    _markInput();
  }

  /// Whether the sheet holds something of the person's that a link must never throw away: text
  /// typed (or kept while listening), what was said and is waiting to be read, or cards to save.
  bool get _hasInput {
    final current = preview;
    return switch (stage) {
      CaptureStage.typing => field.text.trim().isNotEmpty,
      CaptureStage.starting || CaptureStage.listening => _kept.isNotEmpty,
      CaptureStage.preview =>
        _pending != null ||
            (current != null && (current.cards.isNotEmpty || current.unread.isNotEmpty)),
      CaptureStage.offer || CaptureStage.downloading => false,
    };
  }

  void _markInput() => _withInput.mark(this, hasInput: _hasInput);

  /// A 🎤 link with this sheet open: listening, from the typing field. Any other stage stays as it
  /// is: it is listening already, or has nothing to listen with (no model, no engine), or holds
  /// cards that a new sentence would replace.
  @override
  void listenFromLink() {
    if (stage == CaptureStage.typing && canListen) listen();
  }

  /// The app's language, which is also the voice's (one of [appLanguages]).
  String get locale => captureLanguage(AppLocalizations.of(context).localeName);

  /// The names already used and their usual categories: the parser's first choice of category.
  Future<void> _fetchUsual() async {
    try {
      final found = await ref.read(addRepositoryProvider).suggestions('');
      _usual = [for (final s in found) p.Usual(name: s.name, categoryId: s.categoryId)];
    } on Object {
      // Without them, categories are matched by name only.
    }
  }

  Future<void> _start() async {
    // Both at once: nothing waits for the other.
    final (available, warm) = await (engine.available(), engine.isWarm(locale: locale)).wait;
    if (!mounted) return;
    canListen = available && hasVoice;
    _warm = canListen && warm;
    if (!widget.listen) {
      type(null);
    } else if (!available) {
      type(CaptureWhy.noEngine);
    } else if (!hasVoice) {
      type(CaptureWhy.noVoiceYet);
    } else {
      listen();
    }
  }

  // -- listening -----------------------------------------------------------------------------

  static bool get _inBackground => switch (WidgetsBinding.instance.lifecycleState) {
    AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => true,
    _ => false,
  };

  void listen() {
    if (!hasVoice) {
      type(CaptureWhy.noVoiceYet);
      return;
    }
    if (_inBackground) {
      _set(() {
        stage = CaptureStage.starting;
        _listenWhenBack = true;
      });
      return;
    }
    unawaited(_listening?.cancel());
    _kept = field.text.trim();
    _set(() {
      stage = CaptureStage.listening;
      why = null;
      heard = '';
      ready = _warm;
    });
    _listening = engine
        .listen(locale: locale)
        .listen(
          (text) => _set(() {
            ready = true;
            // The model has loaded by now: the next listen needs no preparing either.
            _warm = true;
            heard = text;
          }),
          onError: (Object error) {
            _listening = null;
            final kind = error is SpeechFailure ? error.kind : SpeechFailureKind.failed;
            switch (kind) {
              case SpeechFailureKind.noModel when !hasVoice:
                // A language with no model has nothing to offer: typing, with the note why.
                type(CaptureWhy.noVoiceYet);
              case SpeechFailureKind.noModel:
                _set(() {
                  stage = CaptureStage.offer;
                  downloadFailure = null;
                });
              case SpeechFailureKind.permissionDenied:
                type(CaptureWhy.micDenied);
              case SpeechFailureKind.failed:
                type(CaptureWhy.listenFailed);
            }
          },
          onDone: () {
            if (_listening == null || !mounted) return;
            _listening = null;
            final text = heard.trim();
            if (text.isEmpty) {
              type(CaptureWhy.nothingHeard);
            } else {
              _read(_spoken(text));
            }
          },
          cancelOnError: true,
        );
  }

  void stopListening() => unawaited(engine.stop());

  /// What was said, after what was typed before listening started, if anything.
  String _spoken(String heard) => [_kept, heard.trim()].where((t) => t.isNotEmpty).join(' ');

  /// The typing field, with [note] over it saying why it shows, if anything.
  void type(CaptureWhy? note, {String? text}) {
    _listenWhenBack = false;
    _kept = '';
    final listening = _listening;
    _listening = null;
    if (listening != null) {
      unawaited(listening.cancel());
      unawaited(engine.stop());
    }
    _set(() {
      stage = CaptureStage.typing;
      why = note;
      if (text != null) field.text = text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && stage == CaptureStage.typing) fieldFocus.requestFocus();
    });
  }

  // -- the model download --------------------------------------------------------------------

  Future<void> downloadModel() async {
    final cancel = CancelToken();
    _set(() {
      _download = cancel;
      downloaded = 0;
      downloadFailure = null;
      stage = CaptureStage.downloading;
    });
    try {
      await ref
          .read(modelStoreProvider)
          .download(
            locale,
            cancel: cancel,
            onProgress: (received, _) => _set(() => downloaded = received),
          );
    } on Object catch (error) {
      if (!mounted) return;
      final problem = error is ModelDownloadFailure ? error : const ModelDownloadFailure();
      _set(() {
        _download = null;
        stage = CaptureStage.offer;
        downloadFailure = problem.cancelled ? null : problem;
      });
      return;
    }
    if (!mounted) return;
    _download = null;
    listen();
  }

  // -- the preview ---------------------------------------------------------------------------

  void _read(String sentence) {
    final data = ref.read(homeProvider).data;
    if (data == null) {
      _set(() {
        _pending = sentence;
        stage = CaptureStage.preview;
      });
      return;
    }
    _pending = null;
    final today = data.todayAt(ref.read(clockProvider)());
    final result = p.parseSentence(
      sentence,
      p.ParseContext(
        locale: parserLanguage(locale),
        currency: data.currency,
        today: today,
        timeZone: data.timezone,
        categories: [
          for (final c in data.categories.values)
            if (!c.archived)
              p.Category(
                id: c.id,
                name: c.name,
                kind: c.kind == CategoryKindEnum.income ? p.Kind.income : p.Kind.expense,
              ),
        ],
        usual: _usual,
      ),
    );
    if (result.drafts.isEmpty && result.unread.isEmpty) {
      type(CaptureWhy.nothingRead, text: sentence);
      return;
    }
    final current = preview ??= CapturePreview(today: today)..addListener(_onPreviewChanged);
    current.read(sentence, result);
    _set(() {
      stage = CaptureStage.preview;
      why = null;
      failure = null;
      openCard = null;
    });
  }

  void _onPreviewChanged() => _set(() {});

  void readTyped() {
    final text = field.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _read(text);
  }

  // -- saving --------------------------------------------------------------------------------

  Future<void> save() async {
    final batch = preview;
    final data = ref.read(homeProvider).data;
    if (saving || batch == null || data == null || !batch.ready) return;
    final repo = ref.read(captureRepositoryProvider);
    // What outlives the sheet: the toast, Deshacer, the home update and the feedback hook.
    final container = ProviderScope.containerOf(context);
    final toasts = ToastHost.of(context);
    final navigator = Navigator.of(context);

    final drafts = batch.drafts(categoryName: (id) => data.categories[id]?.name ?? '');
    final key = _keys.putIfAbsent(batchFingerprint(drafts), newIdempotencyKey);
    final total = batch.total;

    _set(() {
      saving = true;
      failure = null;
    });
    try {
      final saved = await repo.saveBatch(drafts, idempotencyKey: key);
      // The first successful capture: the note about listening on the phone is never shown again,
      // and the speech model is loaded in advance from now on (prewarm.dart).
      unawaited(container.read(captureNoteProvider.notifier).set(false));
      // Once the figures of the whole batch are in, it feels like a save (see the hook).
      unawaited(
        afterFigures(container.read(homeProvider.notifier).savedBatch(saved))
            .then((_) => container.read(batchSavedFeedbackProvider)(saved)),
      );
      if (mounted) navigator.pop();
      celebrateBatch(
        container: container,
        toasts: toasts,
        l10n: l10n,
        saved: saved,
        total: formatMoney(total, data.currency, l10n.localeName),
      );
    } on HomeFailure catch (error) {
      if (error.unauthorized) {
        unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
        if (mounted) navigator.pop();
        return;
      }
      _set(() {
        saving = false;
        failure = error;
      });
    } on Object {
      _set(() {
        saving = false;
        failure = const HomeFailure(500);
      });
    }
  }

  // -- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    home = ref.watch(homeProvider);
    final pending = _pending;
    if (pending != null && home.data != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pending == pending) _read(pending);
      });
    }
    return CaptureSession(
      key: const Key('capture.sheet'),
      state: this,
      version: ++_version,
      child: widget.child,
    );
  }
}

/// The capture sheet's state, for the parts under it ([CaptureSession.of] rebuilds them whenever
/// it changes).
class CaptureSession extends InheritedWidget {
  const CaptureSession({
    super.key,
    required this.state,
    required this.version,
    required super.child,
  });

  final CaptureSheetState state;
  final int version;

  static CaptureSheetState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CaptureSession>()!.state;

  @override
  bool updateShouldNotify(CaptureSession old) => old.version != version;
}
