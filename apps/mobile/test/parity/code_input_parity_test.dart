@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/entry/code_input.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/ui/lk_theme.dart';

import '../support/parity.dart';

/// `CodeInput` against `sign-in-codeinput--*` (apps/web/app/features/sign-in/CodeInput.stories.tsx),
/// each story as Storybook shows it after its `play` function (`Invalid` pins day). The story's
/// harness is `<div className="max-w-[360px]"><CodeInput autoFocus/><output>{value}</output></div>`:
/// the typed code, as plain text, under the boxes.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The story's harness: the boxes and the `<output>` after them.
class _Harness extends StatefulWidget {
  const _Harness({this.invalid = false});

  final bool invalid;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return cssBlock(
      maxWidth: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CodeInput(
            fieldKey: const Key('entry.code'),
            controller: _controller,
            focusNode: _focus,
            label: 'Código de 6 dígitos',
            invalid: widget.invalid,
            autofocus: true,
          ),
          // An empty `<output>` has no line.
          if (_controller.text.isNotEmpty)
            Text(_controller.text, style: LkText.copy.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

Widget _story({bool invalid = false}) =>
    ParityStoryFrame(block: true, child: _Harness(invalid: invalid));

Finder get _code => find.byKey(const Key('entry.code'));

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('code input parity: typing a whole code ($theme)', (t) async {
      await parityGolden(
        t,
        'code-input-typing',
        _story(),
        theme: theme,
        act: (t) async {
          for (var i = 1; i <= 6; i++) {
            await t.enterText(_code, '123456'.substring(0, i));
          }
        },
      );
    });

    testWidgets('code input parity: typing back to nothing ($theme)', (t) async {
      await parityGolden(
        t,
        'code-input-backspace',
        _story(),
        theme: theme,
        act: (t) async {
          await t.enterText(_code, '12');
          await t.enterText(_code, '');
        },
      );
    });

    testWidgets('code input parity: a pasted code ($theme)', (t) async {
      await parityGolden(
        t,
        'code-input-paste',
        _story(),
        theme: theme,
        act: (t) async {
          await t.enterText(_code, 'Code: 987-654');
        },
      );
    });
  }

  testWidgets('code input parity: marked invalid, by day', (t) async {
    await parityGolden(t, 'code-input-invalid', _story(invalid: true), theme: 'day');
  });
}
