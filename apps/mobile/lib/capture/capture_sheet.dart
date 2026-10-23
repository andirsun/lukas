import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add/add_repository.dart';
import '../add/add_sheet.dart' show canRetrySave;
import '../add/idempotency_key.dart';
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../feedback/feedback.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../home/saved_feedback.dart';
import '../home/home_widgets.dart' show QuietSpinner;
import '../home/toast.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'capture_note.dart';
import 'capture_repository.dart';
import 'engine/speech_engine.dart';
import 'mic_level.dart';
import 'models_download.dart';
import 'parser/parse.dart' as p;
import 'preview/capture_cards.dart';
import 'preview/capture_preview.dart';

/// Told about every batch saved, with its rows, once the month's figures include the whole batch.
/// By default the batch feels like any save: by kind and by the limit state after the batch (see
/// [savedFeedbackFor]), and Lukitas celebrates on home unless a category is near or over its limit,
/// like for a single save. The celebration line and Deshacer are the toast's. Tests replace it to
/// see what was saved.
final batchSavedFeedbackProvider = Provider<void Function(List<Transaction> saved)>(
  (ref) => (saved) {
    final data = ref.exists(homeProvider) ? ref.read(homeProvider).data : null;
    final event = savedFeedbackFor(data, saved);
    ref.read(feedbackProvider)(event);
    if (celebrates(event)) ref.read(celebrationProvider.notifier).celebrate();
  },
);

/// Opens quick capture (spec section 6.1.4): 🎤 listens with "¿En qué gastaste?" (or, with
/// [listen] false, the typing field is ready), the preview shows one editable, removable card per
/// movement plus what could not be read, and "GUARDAR N" saves them all at once.
///
/// It needs only the app's providers (the home figures it reads the categories, currency and time
/// zone from, the API, the speech engine), no home screen state: the ＋'s neighbour on home calls
/// it, and so will the widget's deep link (Task 15). A save closes the sheet, updates home through
/// its controller and shows one celebration with the total and one Deshacer.
Future<void> openCapture(BuildContext context, {bool listen = true}) {
  final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
  final duration = MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : LukitasTokens.durationSheet;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LukitasTokens.radiusXl)),
    ),
    sheetAnimationStyle: AnimationStyle(duration: duration, reverseDuration: duration),
    builder: (context) => CaptureSheet(listen: listen),
  );
}

enum _Stage { starting, offer, downloading, listening, typing, preview }

/// Why the typing field shows instead of listening: one sentence over it.
enum _Note { micDenied, noEngine, listenFailed, nothingHeard, nothingRead }

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key, this.listen = true});

  final bool listen;

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> with WidgetsBindingObserver {
  var _stage = _Stage.starting;
  _Note? _note;
  var _canListen = false;
  final _field = TextEditingController();
  final _fieldFocus = FocusNode();

  StreamSubscription<String>? _listening;
  var _heard = '';

  /// The engine has loaded its model and the microphone records: "¿En qué gastaste?" shows only
  /// then, so the start of a sentence is not lost. When the engine is [_warm] it shows from the tap:
  /// the microphone starts within a few milliseconds, and what is said while the recognizers attach
  /// is buffered (VoiceChannel.kt), so no "preparing" state is shown at all.
  var _ready = false;

  /// The engine's model was loaded when the sheet opened (or has been since): listening starts at
  /// once.
  var _warm = false;

  /// A transcript that came before home's figures did: read once they are here.
  String? _pending;

  CancelToken? _download;
  var _downloaded = 0;
  ModelDownloadFailure? _downloadFailure;

  CapturePreview? _preview;
  List<p.Usual> _usual = const [];
  int? _openCard;

  var _saving = false;
  HomeFailure? _failure;

  /// One Idempotency-Key per request body ([batchFingerprint]) for the sheet's life: Reintentar, a
  /// change that changes nothing, or a change and its undoing (A, B, then A again) all send the
  /// key that body was first sent with, so a lost answer can never become a second set of rows.
  final _keys = <String, String>{};

  /// Listening waits for the app to be in front again (opened, or the engine answered, while it
  /// was in the background): the microphone never opens unseen.
  var _listenWhenBack = false;

  SpeechEngine get _engine => ref.read(speechEngineProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_fetchUsual());
    // Whether the first-use note shows is known once the kept flag has been read.
    unawaited(ref.read(captureNoteProvider.notifier).ready.then((_) => _set(() {})));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_listening?.cancel());
    _download?.cancel();
    _preview?.dispose();
    _field.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _listenWhenBack) {
      _listenWhenBack = false;
      _listen();
      return;
    }
    // In the background the microphone is let go at once (Kotlin also stops on onStop); what was
    // heard stays in the typing field. Coming back does not listen by itself.
    if ((state == AppLifecycleState.hidden || state == AppLifecycleState.paused) &&
        _stage == _Stage.listening) {
      _type(null, text: _heard);
    }
  }

  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  String get _locale => AppLocalizations.of(context).localeName == 'en' ? 'en' : 'es';

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
    final locale = _locale;
    // Both at once: nothing waits for the other.
    final (canListen, warm) = await (
      _engine.available(),
      _engine.isWarm(locale: locale),
    ).wait;
    if (!mounted) return;
    _canListen = canListen;
    _warm = canListen && warm;
    if (!widget.listen) {
      _type(null);
    } else if (!canListen) {
      _type(_Note.noEngine);
    } else {
      _listen();
    }
  }

  // -- listening -----------------------------------------------------------------------------

  static bool get _inBackground => switch (WidgetsBinding.instance.lifecycleState) {
    AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => true,
    _ => false,
  };

  void _listen() {
    if (_inBackground) {
      _set(() {
        _stage = _Stage.starting;
        _listenWhenBack = true;
      });
      return;
    }
    unawaited(_listening?.cancel());
    _set(() {
      _stage = _Stage.listening;
      _note = null;
      _heard = '';
      _ready = _warm;
    });
    _listening = _engine
        .listen(locale: _locale)
        .listen(
          (text) => _set(() {
            _ready = true;
            // The model has loaded by now: the next listen needs no preparing either.
            _warm = true;
            _heard = text;
          }),
          onError: (Object error) {
            _listening = null;
            final kind = error is SpeechFailure ? error.kind : SpeechFailureKind.failed;
            switch (kind) {
              case SpeechFailureKind.noModel:
                _set(() {
                  _stage = _Stage.offer;
                  _downloadFailure = null;
                });
              case SpeechFailureKind.permissionDenied:
                _type(_Note.micDenied);
              case SpeechFailureKind.failed:
                _type(_Note.listenFailed);
            }
          },
          onDone: () {
            if (_listening == null || !mounted) return;
            _listening = null;
            final text = _heard.trim();
            if (text.isEmpty) {
              _type(_Note.nothingHeard);
            } else {
              _read(text);
            }
          },
          cancelOnError: true,
        );
  }

  void _stopListening() => unawaited(_engine.stop());

  /// The typing field, with [note] over it saying why it shows, if anything.
  void _type(_Note? note, {String? text}) {
    _listenWhenBack = false;
    final listening = _listening;
    _listening = null;
    if (listening != null) {
      unawaited(listening.cancel());
      unawaited(_engine.stop());
    }
    _set(() {
      _stage = _Stage.typing;
      _note = note;
      if (text != null) _field.text = text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _stage == _Stage.typing) _fieldFocus.requestFocus();
    });
  }

  // -- the model download --------------------------------------------------------------------

  Future<void> _downloadModel() async {
    final cancel = CancelToken();
    _set(() {
      _download = cancel;
      _downloaded = 0;
      _downloadFailure = null;
      _stage = _Stage.downloading;
    });
    try {
      await ref
          .read(modelStoreProvider)
          .download(
            _locale,
            cancel: cancel,
            onProgress: (received, _) => _set(() => _downloaded = received),
          );
    } on Object catch (error) {
      if (!mounted) return;
      final failure = error is ModelDownloadFailure ? error : const ModelDownloadFailure();
      _set(() {
        _download = null;
        _stage = _Stage.offer;
        _downloadFailure = failure.cancelled ? null : failure;
      });
      return;
    }
    if (!mounted) return;
    _download = null;
    _listen();
  }

  // -- the preview ---------------------------------------------------------------------------

  void _read(String sentence) {
    final data = ref.read(homeProvider).data;
    if (data == null) {
      _set(() {
        _pending = sentence;
        _stage = _Stage.preview;
      });
      return;
    }
    _pending = null;
    final today = data.todayAt(ref.read(clockProvider)());
    final result = p.parseSentence(
      sentence,
      p.ParseContext(
        locale: _locale,
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
      _type(_Note.nothingRead, text: sentence);
      return;
    }
    final preview = _preview ??= CapturePreview(today: today)..addListener(_onPreviewChanged);
    preview.read(sentence, result);
    _set(() {
      _stage = _Stage.preview;
      _note = null;
      _failure = null;
      _openCard = null;
    });
  }

  void _onPreviewChanged() => _set(() {});

  void _readTyped() {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _read(text);
  }

  // -- saving --------------------------------------------------------------------------------

  Future<void> _save(AppLocalizations l10n) async {
    final preview = _preview;
    final data = ref.read(homeProvider).data;
    if (_saving || preview == null || data == null || !preview.ready) return;
    final repo = ref.read(captureRepositoryProvider);
    // What outlives the sheet: the toast, Deshacer, the home update and the feedback hook.
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;

    final drafts = preview.drafts(categoryName: (id) => data.categories[id]?.name ?? '');
    final key = _keys.putIfAbsent(batchFingerprint(drafts), newIdempotencyKey);
    final total = preview.total;

    _set(() {
      _saving = true;
      _failure = null;
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
      _celebrate(
        container: container,
        messenger: messenger,
        colors: colors,
        l10n: l10n,
        saved: saved,
        total: formatMoney(total, data.currency, l10n.localeName),
      );
    } on HomeFailure catch (failure) {
      if (failure.unauthorized) {
        unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
        if (mounted) navigator.pop();
        return;
      }
      _set(() {
        _saving = false;
        _failure = failure;
      });
    } on Object {
      _set(() {
        _saving = false;
        _failure = const HomeFailure(500);
      });
    }
  }

  // -- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final home = ref.watch(homeProvider);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final pending = _pending;
    if (pending != null && home.data != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pending == pending) _read(pending);
      });
    }

    final Widget body = switch (_stage) {
      _Stage.starting => const Padding(
        padding: EdgeInsets.all(LukitasTokens.space5),
        child: Center(child: QuietSpinner(size: 28)),
      ),
      _Stage.offer => _offer(l10n, colors),
      _Stage.downloading => _downloading(l10n, colors),
      _Stage.listening => _listeningView(l10n, colors),
      _Stage.typing => _typing(l10n, colors),
      _Stage.preview =>
        home.data == null || _preview == null
            ? _unloaded(l10n, colors, home)
            : _previewView(l10n, colors, home.data!),
    };

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: l10n.captureTitle,
      child: Padding(
        key: const Key('capture.sheet'),
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(title: l10n.captureTitle, closeLabel: l10n.addClose),
              Flexible(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unloaded(AppLocalizations l10n, LukitasColors colors, HomeState home) {
    final failed = home.failure != null;
    return Padding(
      padding: const EdgeInsets.all(LukitasTokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!failed) const QuietSpinner(size: 28),
          const SizedBox(height: LukitasTokens.space3),
          Text(
            failed
                ? (home.failure!.offline ? l10n.errorNetwork : l10n.errorGeneric)
                : l10n.homeLoading,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
          ),
          if (failed) ...[
            const SizedBox(height: LukitasTokens.space3),
            FilledButton(
              onPressed: () => unawaited(ref.read(homeProvider.notifier).refresh()),
              child: Text(l10n.retry),
            ),
          ],
        ],
      ),
    );
  }

  Widget _padded(List<Widget> children) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      LukitasTokens.space4,
      LukitasTokens.space2,
      LukitasTokens.space4,
      LukitasTokens.space4,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _offer(AppLocalizations l10n, LukitasColors colors) {
    final model = ref.read(modelStoreProvider).modelFor(_locale);
    final megabytes = (model.bytes / 1e6).round();
    final failure = _downloadFailure;
    return _padded([
      Text(
        l10n.captureOfferTitle,
        style: TextStyle(color: colors.ink, fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: LukitasTokens.space2),
      Text(
        l10n.captureOfferBody(megabytes),
        style: TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w600),
      ),
      if (failure != null) ...[
        const SizedBox(height: LukitasTokens.space2),
        Semantics(
          liveRegion: true,
          child: Text(
            failure.noSpace
                ? l10n.captureDownloadNoSpace(((model.bytes + model.unzippedBytes) / 1e6).round())
                : failure.corrupt
                ? l10n.captureDownloadCorrupt
                : l10n.captureDownloadFailed,
            style: TextStyle(color: colors.over, fontWeight: FontWeight.w800),
          ),
        ),
      ],
      const SizedBox(height: LukitasTokens.space4),
      FilledButton(
        key: const Key('capture.offer.download'),
        onPressed: () => unawaited(_downloadModel()),
        child: Text(failure == null ? l10n.captureOfferDownload(megabytes) : l10n.retry),
      ),
      const SizedBox(height: LukitasTokens.space2),
      TextButton(
        key: const Key('capture.offer.decline'),
        onPressed: () => _type(null),
        child: Text(l10n.captureOfferDecline),
      ),
    ]);
  }

  Widget _downloading(AppLocalizations l10n, LukitasColors colors) {
    final total = ref.read(modelStoreProvider).modelFor(_locale).bytes;
    final fraction = total == 0 ? 0.0 : (_downloaded / total).clamp(0.0, 1.0);
    return _padded([
      Semantics(
        liveRegion: true,
        child: Text(
          l10n.captureDownloading((fraction * 100).floor()),
          style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: LukitasTokens.space3),
      LinearProgressIndicator(value: fraction, color: colors.brand),
      const SizedBox(height: LukitasTokens.space3),
      TextButton(
        key: const Key('capture.download.cancel'),
        onPressed: () => _download?.cancel(),
        child: Text(l10n.captureDownloadCancel),
      ),
    ]);
  }

  Widget _listeningView(AppLocalizations l10n, LukitasColors colors) => _padded([
    const SizedBox(height: LukitasTokens.space2),
    if (_ready) ...[
      Icon(Icons.mic, size: 40, color: colors.brand),
      // The input level, live: the person sees the microphone is in use.
      MicLevel(levels: _engine.levels),
    ] else
      const Center(child: QuietSpinner(size: 48)),
    const SizedBox(height: LukitasTokens.space2),
    Semantics(
      liveRegion: true,
      child: Text(
        _ready ? l10n.captureListeningPrompt : l10n.capturePreparing,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.ink, fontSize: 22, fontWeight: FontWeight.w800),
      ),
    ),
    const SizedBox(height: LukitasTokens.space1),
    // The explanation of where the voice goes, for the first use only.
    if (ref.read(captureNoteProvider.notifier).active)
      Text(
        l10n.captureListeningNote,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.inkMuted, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    const SizedBox(height: LukitasTokens.space4),
    Text(
      _heard,
      key: const Key('capture.heard'),
      textAlign: TextAlign.center,
      style: TextStyle(color: colors.ink, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: LukitasTokens.space4),
    FilledButton(
      key: const Key('capture.stop'),
      onPressed: _stopListening,
      child: Text(l10n.captureStop),
    ),
    const SizedBox(height: LukitasTokens.space2),
    TextButton(
      key: const Key('capture.type'),
      onPressed: () => _type(null, text: _heard),
      child: Text(l10n.captureTypeInstead),
    ),
  ]);

  String? _noteText(AppLocalizations l10n) => switch (_note) {
    _Note.micDenied => l10n.captureMicDenied,
    _Note.noEngine => l10n.captureNoEngine,
    _Note.listenFailed => l10n.captureListenFailed,
    _Note.nothingHeard => l10n.captureNothingHeard,
    _Note.nothingRead => l10n.captureNothingRead,
    null => null,
  };

  Widget _typing(AppLocalizations l10n, LukitasColors colors) {
    final note = _noteText(l10n);
    return _padded([
      if (note != null) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            note,
            key: const Key('capture.note'),
            style: TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: LukitasTokens.space3),
      ],
      TextField(
        key: const Key('capture.field'),
        controller: _field,
        focusNode: _fieldFocus,
        minLines: 1,
        maxLines: 3,
        maxLength: 500,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _readTyped(),
        style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: l10n.captureFieldLabel,
          hintText: l10n.captureFieldHint,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
            borderSide: BorderSide(color: colors.stroke, width: 2),
          ),
        ),
      ),
      const SizedBox(height: LukitasTokens.space3),
      Row(
        children: [
          if (_canListen) ...[
            OutlinedButton.icon(
              key: const Key('capture.listen'),
              onPressed: _listen,
              icon: const Icon(Icons.mic),
              label: Text(l10n.captureListen),
            ),
            const SizedBox(width: LukitasTokens.space2),
          ],
          Expanded(
            child: FilledButton(
              key: const Key('capture.read'),
              onPressed: _readTyped,
              child: Text(l10n.captureRead),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _previewView(AppLocalizations l10n, LukitasColors colors, HomeData data) {
    final preview = _preview!;
    final cards = preview.cards;
    final failure = _failure;
    final categories = [
      for (final c in data.categories.values)
        if (!c.archived) c,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: _padded([
            Row(
              children: [
                Expanded(
                  child: Text(
                    preview.sentence,
                    style: TextStyle(
                      color: colors.inkMuted,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('capture.change'),
                  onPressed: _saving ? null : () => _type(null, text: preview.sentence),
                  child: Text(l10n.captureChangeSentence),
                ),
              ],
            ),
            const SizedBox(height: LukitasTokens.space2),
            for (var i = 0; i < cards.length; i++) ...[
              CaptureCardView(
                key: ValueKey('card-${cards[i].id}'),
                index: i,
                card: cards[i],
                open: _openCard == cards[i].id,
                categories: categories,
                currency: data.currency,
                today: preview.today,
                enabled: !_saving,
                onToggle: () =>
                    _set(() => _openCard = _openCard == cards[i].id ? null : cards[i].id),
                onPick: () => _set(() => _openCard = cards[i].id),
                onRemove: () => preview.remove(cards[i].id),
                onChange: ({amount, kind, name, categoryId, date}) => preview.update(
                  cards[i].id,
                  amount: amount,
                  kind: kind,
                  name: name,
                  categoryId: categoryId,
                  date: date,
                ),
                onPicked: () => _set(() => _openCard = null),
              ),
              const SizedBox(height: LukitasTokens.space2),
            ],
            for (var i = 0; i < preview.unread.length; i++)
              Padding(
                key: Key('capture.unread.$i'),
                padding: const EdgeInsets.only(bottom: LukitasTokens.space2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.captureUnread(preview.unread[i]),
                        style: TextStyle(color: colors.near, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      key: Key('capture.unread.$i.complete'),
                      onPressed: _saving
                          ? null
                          : () {
                              preview.complete(i);
                              _set(() => _openCard = preview.cards.last.id);
                            },
                      child: Text(l10n.captureComplete),
                    ),
                  ],
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LukitasTokens.space4,
            LukitasTokens.space2,
            LukitasTokens.space4,
            LukitasTokens.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: LukitasTokens.space2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _failureMessage(l10n, failure),
                            style: TextStyle(
                              color: colors.over,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (canRetrySave(failure))
                        TextButton(
                          key: const Key('capture.retry'),
                          onPressed: () => unawaited(_save(l10n)),
                          style: TextButton.styleFrom(foregroundColor: colors.gold),
                          child: Text(l10n.retry),
                        ),
                    ],
                  ),
                ),
              FilledButton(
                key: const Key('capture.save'),
                onPressed: preview.ready && !_saving ? () => unawaited(_save(l10n)) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
                  ),
                ),
                child: _saving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const QuietSpinner(),
                          const SizedBox(width: LukitasTokens.space2),
                          Text(l10n.addSaving),
                        ],
                      )
                    : Text(l10n.captureSave(cards.length)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _failureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  if (failure.code == 'idempotency_in_progress') return l10n.addErrorBusy;
  if (failure.code == 'category_not_found') return l10n.addErrorCategory;
  if (failure.status == 422) return l10n.addErrorInvalid;
  return failure.status >= 500 ? l10n.errorInternal : l10n.errorGeneric;
}

/// The one celebration after a batch: how many and the total, with one Deshacer that takes them
/// all away. Everything it needs is passed in: the sheet is gone by the time anyone taps.
void _celebrate({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required LukitasColors colors,
  required AppLocalizations l10n,
  required List<Transaction> saved,
  required String total,
}) {
  final ids = [for (final t in saved) t.id];
  showToast(
    messenger,
    colors,
    l10n.captureSaved(saved.length, total),
    actionLabel: l10n.undo,
    onAction: () => unawaited(() async {
      try {
        await container.read(captureRepositoryProvider).undoBatch(ids);
      } on HomeFailure catch (failure) {
        showToast(
          messenger,
          colors,
          failure.offline ? l10n.errorNetwork : l10n.errorGeneric,
          error: true,
        );
        return;
      }
      unawaited(container.read(homeProvider.notifier).forget(ids));
      container.read(feedbackProvider)(FeedbackEvent.undo);
      showToast(messenger, colors, l10n.captureUndone(ids.length));
    }()),
  );
}

// -- pieces ----------------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.closeLabel});

  final String title;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.stroke,
            borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: LukitasTokens.space4, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(color: colors.ink, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              IconButton(
                key: const Key('capture.close'),
                tooltip: closeLabel,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
