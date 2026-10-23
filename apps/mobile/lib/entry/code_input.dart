// The web's CodeInput (apps/web/app/features/sign-in/CodeInput.tsx) and the CSS it uses: app.css
// `.lk-code-box`.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/pixel_snap.dart';
import '../ui/pressable.dart';
import 'code_formatter.dart';
import 'sign_in_frame.dart' show FieldCaption;

/// The 6-digit sign-in code as six sunken boxes, one digit each, the next one to type ringed.
///
/// What is typed goes to one real text field behind the boxes ([controller], with [CodeFormatter]'s
/// rule: digits only, at most six, a whole code pasted or autofilled replaces what is there). The
/// boxes only show it, so the phone's one-time-code autofill, its keyboard's clipboard suggestion
/// and a long-press paste all work as in any field. [fieldKey] is the key of that field.
///
/// A box is at least 44px wide and at most 56px (`min-w-[44px] max-w-[56px]`), the six sharing the
/// width with 4px between them (8px from a phone 360px wide).
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.label,
    this.invalid = false,
    this.readOnly = false,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Key fieldKey;

  /// "Código de 6 dígitos".
  final String label;

  /// A wrong code: the boxes are edged in `over`.
  final bool invalid;

  /// Typing is ignored (the code is being checked); the boxes stay where they are.
  final bool readOnly;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  var _length = 0;

  /// The last change brought several digits at once (a paste, the phone's autofill) rather than one
  /// typed. The web's box keeps a typed digit selected where the focus moved to it, and a pasted
  /// code not.
  var _pasted = false;

  void _changed() {
    final length = widget.controller.text.length;
    if (length - _length >= 2) {
      _pasted = true;
    } else if (length != _length) {
      _pasted = false;
    }
    _length = length;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _length = widget.controller.text.length;
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(CodeInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  EditableTextState? _editableState() {
    EditableTextState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final digits = widget.controller.text;
    final focused = widget.focusNode.hasFocus;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    // `min-[360px]:gap-(--space-2)`: a width of the viewport.
    final gap = MediaQuery.sizeOf(context).width >= 360
        ? LukitasTokens.space2
        : LukitasTokens.space1;
    final brightness = Theme.of(context).brightness;
    final edge = widget.invalid ? colors.over : LkSurface.fieldEdge(colors, brightness);
    final active = math.min(digits.length, codeLength - 1);

    final group = LayoutBuilder(
      builder: (context, constraints) {
        final width = ((constraints.maxWidth - gap * (codeLength - 1)) / codeLength).clamp(
          44.0,
          56.0,
        );
        // Chrome puts each box's edges on whole device pixels; the digit stays where the fraction
        // puts it.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.readOnly
              ? null
              : () {
                  widget.focusNode.requestFocus();
                  _editableState()?.requestKeyboard();
                },
          child: SizedBox(
            height: _boxHeight,
            child: Stack(
              children: [
                // The field the keyboard types into: as wide as the boxes, drawn nowhere.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    alwaysIncludeSemantics: true,
                    child: Semantics(
                      label: widget.label,
                      textField: true,
                      child: EditableText(
                        key: widget.fieldKey,
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        style: LkText.codeBox.copyWith(color: colors.ink),
                        cursorColor: const Color(0x00000000),
                        backgroundCursorColor: const Color(0x00000000),
                        selectionColor: const Color(0x00000000),
                        selectionControls: _noHandles,
                        showCursor: false,
                        maxLines: 1,
                        readOnly: widget.readOnly,
                        autofocus: widget.autofocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: const [CodeFormatter()],
                        autocorrect: false,
                        enableSuggestions: false,
                        onSubmitted: widget.onSubmitted,
                        onChanged: widget.onChanged,
                      ),
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: gap,
                      children: [
                        for (var i = 0; i < codeLength; i++)
                          _Box(
                            width: width,
                            digit: i < digits.length ? digits[i] : null,
                            // A box is ringed while the field has the focus: the next to type, or
                            // the last once the code is whole.
                            ringed: focused && i == active,
                            selected: focused && !_pasted && i == active && i < digits.length,
                            edge: edge,
                            ratio: ratio,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space2,
      children: [FieldCaption(widget.label), group],
    );
  }
}

/// `height: 56px`.
const _boxHeight = 56.0;

final _noHandles = _NoHandles();

/// Text selection with no handles and no toolbar of its own: the boxes show no selection, so a
/// handle would float over them.
class _NoHandles extends TextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => const SizedBox.shrink();

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) => Offset.zero;

  @override
  Size getHandleSize(double textLineHeight) => Size.zero;

  // The menu is the field's `contextMenuBuilder`, not this.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) => const SizedBox.shrink();
}

/// One box of the code: sunken, 2px edge, `radius-md`, a digit in the display face. A ringed box
/// wears the focus ring; a ringed box with a digit has it selected, as the web's box does when the
/// focus moves to it (the browser's own highlight, black on its light blue).
class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.digit,
    required this.ringed,
    required this.selected,
    required this.edge,
    required this.ratio,
  });

  final double width;
  final String? digit;
  final bool ringed;
  final bool selected;
  final Color edge;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final radius = LkSurface.radius(LkRadius.md);
    final style = LkText.codeBox;
    Widget? glyph;
    if (digit != null) {
      glyph = BlinkLine(
        style: style,
        child: Text(
          digit!,
          style: style.copyWith(color: selected ? const Color(0xFF000000) : colors.ink),
        ),
      );
      if (selected) glyph = _Highlighted(style: style, child: glyph);
    }
    return RingBox(
      radius: ringed ? radius : null,
      color: colors.focus,
      child: SnappedDecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: radius,
          border: Border.all(color: edge, width: 2),
        ),
        child: SizedBox(
          width: width,
          height: _boxHeight,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

/// A digit with the browser's selection colour behind it: the width of the glyph, and the height of
/// the font's ascent and descent, each rounded to a whole pixel as Blink does.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _HighlightPainter(
        style: style,
        color: night ? const Color(0xFF1E5172) : const Color(0xFFA1D2F5),
      ),
      child: child,
    );
  }
}

class _HighlightPainter extends CustomPainter {
  const _HighlightPainter({required this.style, required this.color});

  final TextStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final plain = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          fontFeatures: style.fontFeatures,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = plain.computeDistanceToActualBaseline(TextBaseline.alphabetic).roundToDouble();
    final descent = (plain.height - plain.computeDistanceToActualBaseline(TextBaseline.alphabetic))
        .roundToDouble();
    plain.dispose();
    // The line box is 1.5 em; its content area sits in it by the half-leading, floored.
    final line = style.fontSize! * style.height!;
    final top = ((line - ascent - descent) / 2).floorToDouble();
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, ascent + descent), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.style != style || old.color != color;
}
