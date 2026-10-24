import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback/stored_flag.dart';

/// Whether the explanatory note under the listening prompt ("Te escucho aquí mismo: lo que dices no
/// sale de tu teléfono.") still shows: on for a first use, off for good once the person has saved
/// their first capture. It also tells the app whether this person has used the voice before, which
/// is when the speech model is loaded in advance (prewarm.dart). Kept on the phone like the
/// settings (`flutter_secure_storage`), so a restart remembers it; not read yet counts as not shown
/// (`active` is false until it has been read), so someone who has captured never sees it flash.
class CaptureNote extends StoredFlag {
  @override
  FlagStore get store => ref.read(flagStoreProvider('setting.capture.note'));

  @override
  bool get initial => true;
}

final captureNoteProvider = NotifierProvider<CaptureNote, bool>(CaptureNote.new);
