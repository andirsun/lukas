import 'package:flutter/widgets.dart';

import '../ui/css_text.dart';

/// A line of the web's `text-[15px]` (Tailwind's 1.5 line height, 22.5px a line): as tall as CSS
/// makes it, not rounded up to 23px a line as Flutter would, so a card of such lines ends where the
/// web's does.
class NoteText extends StatelessWidget {
  const NoteText(this.text, this.style, {super.key});

  final String text;

  /// The style, with its colour (`LkText.note`).
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CssLines(
    style: style,
    child: Text(text, style: style),
  );
}
