/// What just happened, as the person feels it (the web's `FeedbackEvent`, apps/web/app/feedback).
enum FeedbackEvent {
  /// A movement, or a whole batch, was saved.
  saved,

  /// A pending movement was marked paid.
  paid,

  /// A movement was deleted (a swipe).
  deleted,

  /// Deshacer took a save or a delete back.
  undo,

  /// A swiped row crossed the line where letting go runs its action (or came back under it).
  thresholdCrossed,

  /// A pager settled on the other page. The app has no pager yet (home is one list), so nothing
  /// fires it; it is here so the first pager has its feel ready.
  pageChanged,

  /// A key of the add sheet's keypad.
  keyPressed,
}

/// One step of the Android 11 haptic composition: a `PRIMITIVE_CLICK` or `PRIMITIVE_TICK` at a
/// [scale] (0 to 1) after [delayMs] of quiet.
class HapticPrimitive {
  const HapticPrimitive(this.name, this.scale, {this.delayMs = 0});

  /// `click` or `tick`: the only two primitives Android 11 (API 30) has.
  final String name;
  final double scale;
  final int delayMs;

  Map<String, Object> toJson() => {'name': name, 'scale': scale, 'delay': delayMs};
}

/// How an event feels: [waveform] is the web's pattern in ms (vibrate, pause, vibrate...), which
/// phones without composition primitives play; [primitives] is the same feel as a composition for
/// Android 11 and up (HapticsChannel.kt picks, by asking the motor what it supports).
class HapticPattern {
  const HapticPattern(this.waveform, this.primitives);

  final List<int> waveform;
  final List<HapticPrimitive> primitives;

  Map<String, Object> toJson() => {
    'waveform': waveform,
    'primitives': [for (final step in primitives) step.toJson()],
  };
}

/// The web's vibration patterns, one for one, with a composition of the same shape. Gestures are
/// one short tick each, light enough to repeat while a finger moves.
const hapticPatterns = <FeedbackEvent, HapticPattern>{
  FeedbackEvent.saved: HapticPattern(
    [12, 40, 18],
    [HapticPrimitive('tick', 0.6), HapticPrimitive('click', 1, delayMs: 40)],
  ),
  FeedbackEvent.paid: HapticPattern(
    [10, 30, 10, 30, 24],
    [
      HapticPrimitive('tick', 0.5),
      HapticPrimitive('tick', 0.7, delayMs: 30),
      HapticPrimitive('click', 1, delayMs: 30),
    ],
  ),
  FeedbackEvent.deleted: HapticPattern(
    [14, 30, 8],
    [HapticPrimitive('click', 0.8), HapticPrimitive('tick', 0.5, delayMs: 30)],
  ),
  FeedbackEvent.undo: HapticPattern([8], [HapticPrimitive('tick', 0.5)]),
  FeedbackEvent.thresholdCrossed: HapticPattern([10], [HapticPrimitive('tick', 0.7)]),
  FeedbackEvent.pageChanged: HapticPattern([15], [HapticPrimitive('tick', 1)]),
  FeedbackEvent.keyPressed: HapticPattern([8], [HapticPrimitive('tick', 0.5)]),
};

/// The web's sound files (assets/sounds, with the licence note in its README).
enum FeedbackSound {
  expenseSaved('assets/sounds/expense-saved.mp3'),
  paid('assets/sounds/paid.mp3'),
  undo('assets/sounds/undo.mp3');

  const FeedbackSound(this.asset);

  final String asset;
}

/// The sound of an event. Gestures (a threshold, a page, a delete, a key) only vibrate: a sound on
/// every swipe or key would wear thin fast (the web's rule).
const feedbackSounds = <FeedbackEvent, FeedbackSound>{
  FeedbackEvent.saved: FeedbackSound.expenseSaved,
  FeedbackEvent.paid: FeedbackSound.paid,
  FeedbackEvent.undo: FeedbackSound.undo,
};
