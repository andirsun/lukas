// The web's PressLink (apps/web/app/ui/PressLink.tsx): a link that looks and presses like
// PressButton (app.css `.lk-btn`), with no underline.
import 'package:flutter/widgets.dart';

import '../theme/text_styles.dart';
import 'press_button.dart';

/// A link that looks and presses like [PressButton]: for actions that go somewhere, such as
/// "Empieza ahora". Same solid edge, focus ring and 44px minimum. Where it goes is [onPressed]'s
/// business (the app's router); to assistive technology it is a link.
class PressLink extends StatelessWidget {
  const PressLink({
    super.key,
    required this.child,
    required this.onPressed,
    this.tone = PressTone.primary,
    this.size = PressSize.md,
    this.focusNode,
    this.autofocus = false,
  }) : assert(tone != PressTone.ghost, 'The web has no ghost link: use PressButton');

  /// A link whose label is [label], in upper case as the web shows it.
  PressLink.text(
    String label, {
    super.key,
    required this.onPressed,
    this.tone = PressTone.primary,
    this.size = PressSize.md,
    this.focusNode,
    this.autofocus = false,
  }) : child = Text(LkText.upperCase(label)),
       assert(tone != PressTone.ghost, 'The web has no ghost link: use PressButton');

  final Widget child;
  final VoidCallback? onPressed;

  /// `primary` or `secondary` (the web's `variant`).
  final PressTone tone;

  final PressSize size;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => PressButton(
    onPressed: onPressed,
    tone: tone,
    size: size,
    focusNode: focusNode,
    autofocus: autofocus,
    link: true,
    child: child,
  );
}
