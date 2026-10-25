// The import itself, as the web's ImportPanel (apps/web/app/features/onboarding/ImportStep.tsx),
// shared by the app's import page and, later, the welcome's step: the sources, the Budge how-to
// and picker, reading, the preview and the result.
import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../home/home_repository.dart' show HomeFailure;
import '../l10n/app_localizations.dart';
import '../recurring/recurring_row.dart' show formatRecurringDate;
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/css_text.dart';
import '../ui/lk_theme.dart';
import '../ui/offset_underline.dart';
import '../ui/pressable.dart';
import '../ui/press_button.dart';
import '../ui/svg_path.dart';
import 'import_failure.dart';
import 'import_state.dart';
import 'note_text.dart';

/// Rejected rows listed before "y N más".
const rejectedShown = 20;

/// The text for a rejected row's reason code: the importer's known codes, else "no se pudo leer".
String importReasonText(AppLocalizations l10n, String code) => switch (code) {
  'invalid_date' => l10n.importReasonInvalidDate,
  'invalid_amount' => l10n.importReasonInvalidAmount,
  'zero_amount' => l10n.importReasonZeroAmount,
  'missing_category' => l10n.importReasonMissingCategory,
  'currency_mismatch' => l10n.importReasonCurrencyMismatch,
  _ => l10n.importReasonOther,
};

/// The import: [state] says where it is; the rest are what the person can do. [onConfirm] is the
/// confirm inside the panel (the app's import page); [onFresh] is "No, empiezo de cero" under the
/// sources (the welcome). [showPrefill] says that budgets were prefilled (the welcome, whose budgets
/// step follows); the app's page shows the budgets themselves instead.
class ImportPanel extends StatelessWidget {
  const ImportPanel({
    super.key,
    required this.state,
    required this.onChoose,
    required this.onDiscard,
    required this.onSource,
    this.onRetry,
    this.prefillBasis,
    this.onFresh,
    this.onConfirm,
    this.showPrefill = true,
  });

  final ImportState state;

  /// Shows the document picker (the web's file input).
  final VoidCallback onChoose;
  final VoidCallback onDiscard;

  /// From the list of sources to Budge's how-to and picker (true), and back (false).
  final void Function({required bool budge}) onSource;
  final VoidCallback? onRetry;

  /// "Basado en lo que gastaste en tus últimos 3 meses".
  final String? prefillBasis;
  final VoidCallback? onFresh;
  final VoidCallback? onConfirm;
  final bool showPrefill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final state = this.state;
    return switch (state) {
      ImportSources() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space4,
        children: [
          _Sources(onBudge: () => onSource(budge: true)),
          if (onFresh != null)
            SizedBox(
              width: double.infinity,
              child: PressButton.text(
                l10n.importFresh,
                key: const Key('import.fresh'),
                tone: PressTone.secondary,
                onPressed: onFresh,
              ),
            ),
        ],
      ),
      ImportIdle() => _BudgeHowTo(
        error: state.error,
        onChoose: onChoose,
        onOtherSource: () => onSource(budge: false),
      ),
      ImportReading() => Semantics(
        liveRegion: true,
        child: Text(
          l10n.importReading,
          key: const Key('import.reading'),
          style: LkText.copy.copyWith(color: colors.inkMuted),
        ),
      ),
      ImportPreview() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space4,
        children: [
          _Preview(
            preview: state.preview,
            fileName: state.fileName,
            currencyNote: state.currencyNote,
          ),
          if (state.error != null) _StepError(importFailureMessage(l10n, state.error!)),
          if (onConfirm != null && newRows(state.preview) > 0)
            SizedBox(
              width: double.infinity,
              child: PressButton.text(
                state.confirming
                    ? l10n.importImporting
                    : l10n.importConfirm(newRows(state.preview)),
                key: const Key('import.confirm'),
                onPressed: state.confirming || state.discarding ? null : onConfirm,
              ),
            ),
          PressButton.text(
            l10n.importOtherFile,
            key: const Key('import.otherFile'),
            tone: PressTone.secondary,
            onPressed: state.confirming || state.discarding ? null : onDiscard,
          ),
        ],
      ),
      ImportImported() => _Imported(
        state: state,
        onRetry: onRetry,
        prefillBasis: prefillBasis,
        showPrefill: showPrefill,
      ),
    };
  }
}

/// An error under the control it is about, read out when it appears.
class _StepError extends StatelessWidget {
  const _StepError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        key: const Key('import.error'),
        style: LkText.note.copyWith(color: context.lkColors.over),
      ),
    );
  }
}

/// A source in the list: Budge opens its how-to; the rest say "Pronto" and do nothing yet.
class _Sources extends StatelessWidget {
  const _Sources({required this.onBudge});

  final VoidCallback onBudge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lk = context.lk;
    final colors = lk.colors;
    final display = LkText.sectionTitle.copyWith(color: colors.ink, height: 1.5);

    Widget soon(String label) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: LkSurface.radius(LkRadius.lg),
          border: LkSurface.border(colors),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: LukitasTokens.space3,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: LkText.copy.copyWith(color: colors.inkMuted)),
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: LkSurface.radius(LkRadius.pill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              // 13px at 1.5 is 19.5px a line in CSS, which makes the badge, not the label, the row's
              // tallest part: three rows 0.5px taller each than Flutter's whole-pixel line.
              child: CssLines(
                style: LkText.copy.copyWith(fontSize: 13),
                child: Text(
                  l10n.importSoon,
                  style: LkText.copy.copyWith(fontSize: 13, color: colors.inkMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space2,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.importSourcesLabel, style: display.copyWith(fontSize: 18)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LukitasTokens.space2,
            children: [
              Pressable(
                key: const Key('import.source.budge'),
                onPressed: onBudge,
                label: l10n.importSourceBudge,
                builder: (context, press) {
                  final pressed = press.pressed;
                  final radius = LkSurface.radius(LkRadius.lg);
                  return PressSurface(
                    pressDy: pressed ? 3 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceRow,
                      borderRadius: radius,
                      border: LkSurface.border(colors),
                      boxShadow: pressed
                          ? LkSurface.pressedEdge(lk)
                          : LkSurface.edgeShadow(lk, LkEdge.sm),
                    ),
                    ringRadius: press.focusVisible ? radius : null,
                    ringColor: colors.focus,
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        spacing: LukitasTokens.space3,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.importSourceBudge, style: display.copyWith(fontSize: 18)),
                          DefaultTextStyle.merge(
                            style: TextStyle(color: colors.ink),
                            child: _Icon(_chevron, strokeWidth: 2.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              soon(l10n.importSourceSheet),
              soon(l10n.importSourceBuddy),
              soon(l10n.importSourceOther),
            ],
          ),
        ],
      ),
    );
  }
}

/// How to get the CSV out of Budge, then the picker. The steps are deliberately neutral (no menu
/// names): the founder still has to confirm Budge's exact menu path.
class _BudgeHowTo extends StatelessWidget {
  const _BudgeHowTo({required this.error, required this.onChoose, required this.onOtherSource});

  final HomeFailure? error;
  final VoidCallback onChoose;
  final VoidCallback onOtherSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final steps = [l10n.importBudgeStep1, l10n.importBudgeStep2, l10n.importBudgeStep3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space3,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.importBudgeTitle,
            style: LkText.sectionTitle.copyWith(color: colors.ink, height: 1.5),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space2,
          children: [
            for (final (index, step) in steps.indexed)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // `list-decimal` with `pl-5` (24px) and the marker in the display font, muted: it
                  // sits outside the text, with its space after it. The marker's font makes the
                  // first line 25px, so an item is 25px (49px for two lines).
                  SizedBox(
                    width: LukitasTokens.space5,
                    height: 25,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${index + 1}.',
                          style: LkText.sectionTitle.copyWith(
                            fontSize: 16,
                            height: 1.5,
                            color: colors.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(step, style: LkText.copy.copyWith(color: colors.ink)),
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: PressButton(
            key: const Key('import.choose'),
            tone: PressTone.secondary,
            onPressed: onChoose,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: LukitasTokens.space2,
              children: [_Icon(_upload, strokeWidth: 2), Text(l10n.importChoose.toUpperCase())],
            ),
          ),
        ),
        if (error != null) _StepError(importFailureMessage(l10n, error!)),
        Align(
          alignment: Alignment.centerLeft,
          child: PressButton(
            key: const Key('import.otherSource'),
            tone: PressTone.ghost,
            semanticLabel: l10n.importOtherSource,
            onPressed: onOtherSource,
            child: OffsetUnderline(LkText.upperCase(l10n.importOtherSource)),
          ),
        ),
      ],
    );
  }
}

/// The currency line: the file's currency, switching the account, or kept out.
class _CurrencyLine extends StatelessWidget {
  const _CurrencyLine(this.note);

  final CurrencyNote note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final text = LkText.note.copyWith(color: colors.ink);
    return Container(
      key: const Key('import.currency'),
      decoration: BoxDecoration(
        borderRadius: LkSurface.radius(LkRadius.md),
        border: Border.all(color: colors.gold, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space1,
        children: [
          NoteText(switch (note.kind) {
            CurrencyNoteKind.switched => l10n.importCurrencySwitched(note.file),
            CurrencyNoteKind.switching => l10n.importCurrencySwitching(note.file),
            CurrencyNoteKind.locked => l10n.importCurrencyLocked(note.file, note.account),
          }, text),
          if (note.kind == CurrencyNoteKind.switching && note.dropsBudgets)
            NoteText(
              l10n.importBudgetsDropped(note.account, note.file),
              text.copyWith(fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

/// What the file holds: transactions, duplicates, rows with problems, new categories.
class _Preview extends StatefulWidget {
  const _Preview({required this.preview, required this.fileName, required this.currencyNote});

  final FileImport preview;
  final String fileName;
  final CurrencyNote? currencyNote;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lk = context.lk;
    final colors = lk.colors;
    final locale = l10n.localeName;
    final stats = widget.preview.stats;
    final rejected = stats.rejected;
    final muted = LkText.note.copyWith(color: colors.inkMuted);
    final from = stats.from;
    final to = stats.to;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.importPreviewTitle,
      child: Container(
        key: const Key('import.preview'),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: LkSurface.radius(LkRadius.xl),
          border: LkSurface.border(colors),
          boxShadow: LkSurface.edgeShadow(lk, LkEdge.md),
        ),
        padding: const EdgeInsets.all(LukitasTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space3,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.importPreviewTitle,
                style: LkText.sectionTitle.copyWith(color: colors.ink, height: 1.5),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NoteText(l10n.importFile(widget.fileName), muted),
                if (from != null && to != null)
                  NoteText(
                    l10n.importRange(
                      formatRecurringDate(from, locale),
                      formatRecurringDate(to, locale),
                    ),
                    muted,
                  ),
              ],
            ),
            if (widget.currencyNote != null) _CurrencyLine(widget.currencyNote!),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: LukitasTokens.space2,
                children: [
                  Expanded(
                    child: _Stat(
                      term: l10n.importTransactions,
                      value: stats.transactions,
                      color: colors.good,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      term: l10n.importDuplicates,
                      value: stats.duplicates,
                      color: colors.ink,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      term: l10n.importRejected,
                      value: rejected.length,
                      color: rejected.isNotEmpty ? colors.near : colors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (stats.newCategories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NoteText(l10n.importNewCategories, muted),
                  Text(
                    stats.newCategories.join(', '),
                    style: LkText.note.copyWith(color: colors.ink),
                  ),
                ],
              ),
            if (rejected.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Pressable(
                    key: const Key('import.rejected.toggle'),
                    onPressed: () => setState(() => _open = !_open),
                    expanded: _open,
                    label: l10n.importRejectedDetails,
                    builder: (context, press) => ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: CustomPaint(
                        // The browser's own focus ring on a `<summary>`, with the keyboard on it.
                        foregroundPainter: press.focusVisible ? const _ChromeRingPainter() : null,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OffsetUnderline(
                            l10n.importRejectedDetails,
                            style: LkText.note.copyWith(color: colors.ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_open) ...[
                    const SizedBox(height: LukitasTokens.space1),
                    Semantics(
                      container: true,
                      label: l10n.importRejected,
                      child: Column(
                        key: const Key('import.rejected.list'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: LukitasTokens.space1,
                        children: [
                          for (final row in rejected.take(rejectedShown))
                            NoteText(
                              l10n.importRejectedLine(row.line, importReasonText(l10n, row.reason)),
                              muted,
                            ),
                        ],
                      ),
                    ),
                    if (rejected.length > rejectedShown)
                      Padding(
                        padding: const EdgeInsets.only(top: LukitasTokens.space1),
                        child: NoteText(
                          l10n.importRejectedMore(rejected.length - rejectedShown),
                          muted,
                        ),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One count: the number over its name, on a sunken tile.
class _Stat extends StatelessWidget {
  const _Stat({required this.term, required this.value, required this.color});

  final String term;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return Semantics(
      label: '$term $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: LkSurface.radius(LkRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LukitasTokens.space2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: LukitasTokens.space1,
            children: [
              Text(
                '$value',
                style: LkText.sectionTitle.copyWith(
                  fontSize: 26,
                  height: 1.5,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                term,
                textAlign: TextAlign.center,
                style: LkText.copy.copyWith(fontSize: 13, height: 1.25, color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Imported extends StatelessWidget {
  const _Imported({
    required this.state,
    required this.onRetry,
    required this.prefillBasis,
    required this.showPrefill,
  });

  final ImportImported state;
  final VoidCallback? onRetry;
  final String? prefillBasis;
  final bool showPrefill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final count = state.result.stats.inserted ?? newRows(state.result);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space3,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.importImported(count),
              key: const Key('import.imported'),
              style: LkText.sectionTitle.copyWith(color: colors.good, height: 1.5),
            ),
          ),
          if (state.currencyNote?.kind == CurrencyNoteKind.switched)
            _CurrencyLine(state.currencyNote!),
          if (state.error != null) ...[
            _StepError(importFailureMessage(l10n, state.error!)),
            PressButton.text(
              l10n.retry,
              key: const Key('import.retry'),
              tone: PressTone.secondary,
              onPressed: state.retrying ? null : onRetry,
            ),
          ],
          if (state.prefilled && showPrefill) ...[
            Text(l10n.importPrefilled, style: LkText.copy.copyWith(color: colors.ink)),
            if (prefillBasis != null)
              Text(prefillBasis!, style: LkText.note.copyWith(color: colors.inkMuted)),
          ],
        ],
      ),
    );
  }
}

// -- The icons: 22px, from a 24px viewBox, in the colour of the text around them. ---------------

final _chevron = [parseSvgPath('m9 5 7 7-7 7')];
final _upload = [parseSvgPath('M12 16V4'), parseSvgPath('m7 9 5-5 5 5'), parseSvgPath('M5 20h14')];

class _Icon extends StatelessWidget {
  const _Icon(this.paths, {required this.strokeWidth});

  final List<Path> paths;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(22),
        painter: _IconPainter(paths, strokeWidth, color),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.paths, this.strokeWidth, this.color);

  final List<Path> paths;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;
    for (final path in paths) {
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.paths != paths;
}

/// Chrome's focus ring on a control with none of its own: 2px of blue centred on its edge, with
/// small corners.
class _ChromeRingPainter extends CustomPainter {
  const _ChromeRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF005FCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ChromeRingPainter old) => false;
}
