// The web's CategoryChip (apps/web/app/ui/CategoryChip.tsx) and the CSS it uses: app.css `.lk-chips`,
// `.lk-chip`, `.lk-chip-tile`, `.lk-chip.is-selected`, `.lk-chip-button` and its press.
import 'package:flutter/material.dart';

import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'lk_theme.dart';
import 'pressable.dart';

/// A category in the add sheet's picker: a pressable glyph tile with the name under it. The whole
/// chip is one toggle named by its label (and note); the selected one gets the `gold` outline on
/// its tile and the `ink` label. A long name is cut off with an ellipsis; the chip never grows.
///
/// The chip is as wide as its parent gives it: [CategoryChipGrid] lays them out four per row.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.glyph,
    required this.label,
    this.note,
    required this.selected,
    required this.onSelect,
    this.expanded,
  });

  /// The category's emoji.
  final String glyph;
  final String label;

  /// A short muted word under the name, e.g. "archivada". Part of the chip's name.
  final String? note;

  final bool selected;
  final VoidCallback onSelect;

  /// The chip opens or closes more chips ("Más"/"Menos"): the web's `aria-expanded`.
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final radius = LkSurface.radius(LkRadius.md);
    final note = this.note;

    return Pressable(
      onPressed: onSelect,
      selected: expanded == null ? selected : null,
      expanded: expanded,
      builder: (context, state) {
        final pressed = state.pressed;
        // The tile carries the edge and sinks: `translateY(3px)` and a 1px edge.
        final tile = PressSurface(
          pressDy: pressed ? 3 : 0,
          decoration: BoxDecoration(
            color: colors.surfaceRow,
            borderRadius: radius,
            border: LkSurface.border(colors),
            boxShadow: pressed ? LkSurface.pressedEdge(lk) : LkSurface.edgeShadow(lk, LkEdge.sm),
          ),
          // `.lk-chip.is-selected .lk-chip-tile { outline: 3px solid var(--gold); outline-offset: 1px }`.
          ringRadius: selected ? radius : null,
          ringColor: colors.gold,
          ringOffset: 1,
          child: ExcludeSemantics(
            child: BlinkLine(
              style: LkText.chipGlyph,
              child: Text(glyph, style: LkText.chipGlyph),
            ),
          ),
        );
        return RingBox(
          radius: state.focusVisible ? radius : null,
          color: colors.focus,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 4,
              children: [
                tile,
                BlinkLine(
                  style: LkText.chip,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: LkText.chip.copyWith(color: selected ? colors.ink : colors.inkMuted),
                  ),
                ),
                if (note != null)
                  BlinkLine(
                    style: LkText.chipNote,
                    child: Text(
                      note,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: LkText.chipNote.copyWith(color: colors.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `.lk-chips`: the chips four to a row, with an 8px gap, each in a column of the same width. The
/// rows are as tall as their tallest chip; a short chip sits at the top of its cell.
class CategoryChipGrid extends StatelessWidget {
  const CategoryChipGrid({super.key, required this.children});

  final List<Widget> children;

  static const _columns = 4;
  static const _gap = LukitasTokens.space2;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}
