import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/theme/theme.dart';

import 'emoji_font.dart';
import 'fonts.dart';

/// The parity harness's app side (docs/mobile/parity.md). Each pair in test/parity/parity.json is
/// a web story in one theme and an app test that renders the same thing as a golden, at the
/// phone's size, from the same data, so tool/parity/compose.dart can lay the two side by side.
///
/// The goldens are pixels from macOS (where the web shots are taken too), so parity tests carry
/// the `golden` tag that CI's Linux job skips (dart_test.yaml).

/// The phone, as the web shots take it: 412 × 915 logical pixels at a device pixel ratio of 2.
const parityViewSize = Size(412, 915);
const parityPixelRatio = 2.0;

/// The family the parity goldens draw emoji with: Noto Color Emoji, as the web shots do.
const parityEmojiFamily = 'Noto Color Emoji';

/// The family the parity goldens draw ✓ with. Nunito has no ✓, so Chrome on the Mac falls back to
/// Zapf Dingbats (checked with CDP's `CSS.getPlatformFontsForNode`); `flutter test` has no fallback
/// of its own, so the same system file is named. On a phone, Android's fallback draws it.
const parityDingbatsFamily = 'Parity Zapf Dingbats';

const _zapfDingbats = '/System/Library/Fonts/ZapfDingbats.ttf';

/// The family the parity goldens draw ⌫ (the keypad's backspace) with. No web font has it, and the
/// web's font stacks end in `ui-rounded, system-ui, sans-serif`, so Chrome on the Mac draws it with
/// San Francisco (`.SF NS`, found with CDP's `CSS.getPlatformFontsForNode`); `flutter test` has no
/// fallback of its own, so the same system file is named. On a phone, Android's fallback font
/// draws it.
const paritySystemFamily = 'Parity San Francisco';

const _sanFrancisco = '/System/Library/Fonts/SFNS.ttf';

/// The family the parity goldens draw ＋ (the bottom bar's add button, U+FF0B) with: no web font has
/// it, and San Francisco does not either, so Chrome on the Mac falls back to PingFang SC (Semibold
/// for the button's weight 700). The Mac keeps PingFang in a downloaded font asset, in a collection
/// whose face 11 is `PingFangSC-Semibold` ([ttcFace]). On a phone, Android's fallback font draws it.
const parityCjkFamily = 'Parity PingFang SC';

/// Where macOS keeps PingFang (the asset's folder is named by a hash).
String _pingFang() {
  final found = Directory('/System/Library/AssetsV2')
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('com_apple_MobileAsset_Font'))
      .expand((d) => d.listSync().whereType<Directory>())
      .map((d) => File('${d.path}/AssetData/PingFang.ttc'))
      .where((f) => f.existsSync());
  if (found.isEmpty) fail('Parity draws ＋ with PingFang, a macOS font asset: not found');
  return found.first.path;
}

/// The fallbacks behind every text style of a parity golden.
const parityFallbackFamilies = [
  parityEmojiFamily,
  parityDingbatsFamily,
  paritySystemFamily,
  parityCjkFamily,
];

/// test/parity, relative to apps/mobile (where `flutter test` runs).
const _parityDir = 'test/parity';

/// One pair of parity.json.
class ParityPair {
  const ParityPair({
    required this.id,
    required this.storyId,
    required this.theme,
    required this.appTest,
  });

  factory ParityPair.fromJson(Map<String, Object?> json) => ParityPair(
    id: json['id']! as String,
    storyId: json['storyId']! as String,
    theme: json['theme']! as String,
    appTest: json['appTest']! as String,
  );

  /// The file name stem: `web/<id>-<theme>.png` and `app/<id>-<theme>.png`.
  final String id;

  /// The Storybook story, e.g. `ui-money--spanish`.
  final String storyId;

  /// "night" or "day".
  final String theme;

  /// The test that renders the app's side, from apps/mobile.
  final String appTest;
}

/// The pairs in test/parity/parity.json.
List<ParityPair> parityPairs() {
  final json = jsonDecode(File('$_parityDir/parity.json').readAsStringSync()) as List<Object?>;
  return [for (final pair in json) ParityPair.fromJson(pair! as Map<String, Object?>)];
}

/// One answer of a story's fake API.
class ParityResponse {
  const ParityResponse(this.status, this.body);

  final int status;

  /// The decoded JSON, as the API's client would receive it.
  final Object? body;
}

/// A story's data, as apps/web/scripts/parity-fixtures.ts saved it from the story's own fake API:
/// the clock the story ran at and the JSON answers to the GETs the story and the app screen make.
class ParityFixture {
  const ParityFixture({
    required this.storyId,
    required this.now,
    required this.timezone,
    required this.api,
    required this.responses,
  });

  factory ParityFixture.fromJson(Map<String, Object?> json) => ParityFixture(
    storyId: json['storyId']! as String,
    now: DateTime.parse(json['now']! as String),
    timezone: json['timezone']! as String,
    api: json['api']! as bool,
    responses: {
      for (final MapEntry(:key, :value) in (json['responses']! as Map<String, Object?>).entries)
        key: ParityResponse(
          (value! as Map<String, Object?>)['status']! as int,
          (value as Map<String, Object?>)['body'],
        ),
    },
  );

  final String storyId;

  /// The page's clock when the story ran (UTC); [parityGolden] pins the app's to it.
  final DateTime now;

  /// The made-up person's time zone (the story profile's).
  final String timezone;

  /// Whether the story has a fake API at all (a component's story has none).
  final bool api;

  /// `GET <key>` (see [key]) → the answer.
  final Map<String, ParityResponse> responses;

  /// The answer to `GET pathAndQuery` (`/v1/summary?month=2026-10`); fails the test when the
  /// story's API was not asked it (add it to APP_GETS in apps/web/scripts/parity-fixtures.ts).
  ParityResponse get(String pathAndQuery) {
    final found = responses['GET ${key(pathAndQuery)}'];
    if (found == null) {
      fail(
        'The fixture of $storyId has no answer to GET ${key(pathAndQuery)}. Add it to APP_GETS in '
        'apps/web/scripts/parity-fixtures.ts and run `pnpm --filter @lukas/web parity:fixtures`.',
      );
    }
    return found;
  }

  /// The key of a request, as the web script builds it: the API's path (no `/api` mount) and the
  /// query parameters sorted by name, then value.
  static String key(String pathAndQuery) {
    final uri = Uri.parse(pathAndQuery);
    final path = uri.path.replaceFirst(RegExp(r'^/api(?=/v1/)'), '');
    final params = [
      for (final MapEntry(:key, :value) in uri.queryParametersAll.entries)
        for (final v in value) (key, v),
    ]..sort((a, b) => a.$1 == b.$1 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
    if (params.isEmpty) return path;
    final query = params
        .map((p) => '${Uri.encodeQueryComponent(p.$1)}=${Uri.encodeQueryComponent(p.$2)}')
        .join('&');
    return '$path?$query';
  }
}

/// The stories' saved data (test/parity/fixtures).
abstract final class ParityFixtures {
  /// The fixture of [storyId]; run `pnpm --filter @lukas/web parity:fixtures` to (re)make them.
  static ParityFixture load(String storyId) {
    final file = File('$_parityDir/fixtures/$storyId.json');
    if (!file.existsSync()) {
      fail('No fixture for $storyId: run `pnpm --filter @lukas/web parity:fixtures`.');
    }
    return ParityFixture.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
  }
}

var _fontsLoaded = false;

/// The fonts the parity goldens draw with: the app's Fredoka and Nunito ([loadAppFonts]), Noto
/// Color Emoji for emoji (test/parity/fonts, the file the web shots use; see emoji_font.dart),
/// and Material's icon font from the Flutter SDK, so icons draw rather than as boxes.
Future<void> loadParityFonts() async {
  if (_fontsLoaded) return;
  await loadAppFonts();
  final emoji = sbixFromCbdt(File('$_parityDir/fonts/NotoColorEmoji.ttf').readAsBytesSync());
  await (FontLoader(parityEmojiFamily)..addFont(Future.value(ByteData.sublistView(emoji)))).load();
  await loadMaterialIcons();
  final dingbats = File(_zapfDingbats);
  if (!dingbats.existsSync()) fail('Parity draws ✓ with $_zapfDingbats, a macOS system font');
  await (FontLoader(
    parityDingbatsFamily,
  )..addFont(Future.value(ByteData.sublistView(dingbats.readAsBytesSync())))).load();
  final sanFrancisco = File(_sanFrancisco);
  if (!sanFrancisco.existsSync()) fail('Parity draws ⌫ with $_sanFrancisco, a macOS system font');
  await (FontLoader(
    paritySystemFamily,
  )..addFont(Future.value(ByteData.sublistView(sanFrancisco.readAsBytesSync())))).load();
  final pingFang = ttcFace(File(_pingFang()).readAsBytesSync(), 11);
  await (FontLoader(parityCjkFamily)..addFont(Future.value(ByteData.sublistView(pingFang)))).load();
  _fontsLoaded = true;
}

/// The app's theme for a parity golden: the app's own, with Noto Color Emoji behind every text
/// style (on a phone, Android's own fallback finds its Noto Color Emoji; `flutter test` has no
/// fallback, so it is named).
ThemeData parityTheme(String theme) {
  final base = switch (theme) {
    'night' => nightTheme,
    'day' => dayTheme,
    _ => throw ArgumentError.value(theme, 'theme', 'must be "night" or "day"'),
  };
  return base.copyWith(textTheme: base.textTheme.apply(fontFamilyFallback: parityFallbackFamilies));
}

/// The app's side of the parity pair [id] in [theme] (`night` or `day`): [screen] in the app's
/// theme and copy (in [locale]), at 412 × 915 logical pixels and a device pixel ratio of 2, with
/// the app's clock at the moment the story's fixture was taken, compared with
/// `test/parity/app/<id>-<theme>.png`. The pair must be listed in parity.json.
///
/// [screen] is what the story shows: a screen, or a component in [ParityStoryFrame].
///
/// [act] does what the story's `play` function does before the web's picture is taken (taps,
/// keys), once the screen has settled; the picture is taken after it has settled again. Do the
/// taps first and the keys last: a key puts the app in keyboard mode, where the focused control
/// shows its focus ring, and a tap puts it back.
Future<void> parityGolden(
  WidgetTester t,
  String id,
  Widget screen, {
  required String theme,
  Locale locale = const Locale('es'),
  Future<void> Function(WidgetTester t)? act,
}) async {
  final pair = parityPairs().where((p) => p.id == id && p.theme == theme).firstOrNull;
  if (pair == null) fail('$id-$theme is not a pair in test/parity/parity.json');
  await t.runAsync(loadParityFonts);

  t.view
    ..physicalSize = parityViewSize * parityPixelRatio
    ..devicePixelRatio = parityPixelRatio;
  addTearDown(t.view.reset);

  // `flutter test` draws shadows hard-edged (so goldens do not flake across machines); the web's
  // glow under a primary button is a 24px blur, so the parity pictures draw it blurred.
  debugDisableShadows = false;
  try {
    await _pumpAndCompare(t, id, screen, pair, locale, act);
  } finally {
    // The test framework checks it is back as it set it, before it runs the tear-downs.
    debugDisableShadows = true;
  }
}

Future<void> _pumpAndCompare(
  WidgetTester t,
  String id,
  Widget screen,
  ParityPair pair,
  Locale locale,
  Future<void> Function(WidgetTester t)? act,
) async {
  final fixture = ParityFixtures.load(pair.storyId);
  final theme = pair.theme;

  await t.pumpWidget(
    ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => fixture.now)],
      child: MaterialApp(
        theme: parityTheme(theme),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    ),
  );
  await t.pumpAndSettle();
  if (act != null) {
    await act(t);
    await t.pumpAndSettle();
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(Uri.file('${Directory.current.path}/$_parityDir/app/$id-$theme.png')),
  );
}

/// What Storybook puts around a component's story (apps/web/.storybook/preview.tsx): the page's
/// background (app.css `body { background: var(--bg) }`), the decorator's
/// `<div className="p-(--space-4)">`, and the text the story inherits from `body`: Nunito 700 in
/// the ink colour, at the browser's 16px and Tailwind's line height 1.5.
///
/// The story's element sits on a line of that text, as an inline element does in CSS: its
/// baseline goes on the line's, and the line is at least as tall above it as the body's text
/// makes it (CSS's strut). Blink rounds a font's ascent and descent to whole pixels and floors
/// the half-leading, so the strut is worked out that way; see [cssStrutAscent].
///
/// A story whose root is a block (a `div`: a flex column, a grid, a `max-w` box) is not inline: it
/// starts at the top of the frame and is as wide as it, with no line around it. Pass [block].
class ParityStoryFrame extends StatelessWidget {
  const ParityStoryFrame({super.key, required this.child, this.block = false});

  final Widget child;

  /// The story's root is a block, not an inline element on the body's line.
  final bool block;

  /// The browser's default size, which the web never changes on `html` or `body`.
  static const _bodySize = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final body = TextStyle(
      fontFamily: LkText.textFamily,
      fontFamilyFallback: parityFallbackFamilies,
      fontSize: _bodySize,
      fontWeight: FontWeight.w700,
      height: 1.5,
      leadingDistribution: TextLeadingDistribution.even,
      color: colors.ink,
    );
    return ColoredBox(
      color: colors.bg,
      child: SizedBox.expand(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: body,
              child: block
                  ? Align(alignment: Alignment.topLeft, child: child)
                  : _CssLine(strutAscent: cssStrutAscent(body), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A block-level box: as wide as its container, up to [maxWidth] (Tailwind's `max-w-[...]`).
Widget cssBlock({double? maxWidth, required Widget child}) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
  child: SizedBox(width: double.infinity, child: child),
);

/// `.lk-pad` (app.css): a flex column with 16px of padding and a 12px gap, as a block.
Widget lkPad(List<Widget> children) => cssBlock(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  ),
);

/// `.lk-row-flex` (app.css): a wrapping flex row, centred, with a 12px gap.
Widget lkRowFlex(List<Widget> children) => Wrap(
  spacing: 12,
  runSpacing: 12,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// How far a line's baseline sits below its top in Blink when the line's strut is [style] with a
/// line height of `height × fontSize`: the font's ascent rounded to a whole pixel, plus half the
/// leading (line height − rounded ascent − rounded descent), floored.
double cssStrutAscent(TextStyle style) {
  // The font's own ascent and descent: the style without its line height.
  final painter = TextPainter(
    text: TextSpan(
      text: 'x',
      style: TextStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final ascent = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  final descent = painter.height - ascent;
  painter.dispose();
  final lineHeight = style.fontSize! * style.height!;
  final leading = lineHeight - ascent.roundToDouble() - descent.roundToDouble();
  return ascent.roundToDouble() + (leading / 2).floorToDouble();
}

/// One line holding [child] inline: [child]'s baseline sits [strutAscent] below the top, or
/// lower when [child] is taller above its baseline than that.
class _CssLine extends SingleChildRenderObjectWidget {
  const _CssLine({required this.strutAscent, required Widget super.child});

  final double strutAscent;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCssLine(strutAscent);

  @override
  void updateRenderObject(BuildContext context, _RenderCssLine renderObject) {
    renderObject.strutAscent = strutAscent;
  }
}

class _RenderCssLine extends RenderShiftedBox {
  _RenderCssLine(this._strutAscent) : super(null);

  double _strutAscent;
  set strutAscent(double value) {
    if (value == _strutAscent) return;
    _strutAscent = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    final baseline = child.getDistanceToBaseline(TextBaseline.alphabetic) ?? child.size.height;
    final top = _strutAscent > baseline ? _strutAscent - baseline : 0.0;
    (child.parentData! as BoxParentData).offset = Offset(0, top);
    size = constraints.constrain(Size(child.size.width, top + child.size.height));
  }
}
