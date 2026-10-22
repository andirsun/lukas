import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../home/category_look.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';

/// The categories as tiles four to a row, the selected one outlined in gold; "Más" (or "Menos")
/// at the end when some are folded. The web's `CategoryChip` row.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.chips,
    required this.selectedId,
    required this.overflow,
    required this.expanded,
    required this.onSelect,
    required this.onToggleAll,
  });

  final List<Category> chips;
  final String? selectedId;
  final bool overflow;
  final bool expanded;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleAll;

  static const _perRow = 4;
  static const _gap = LukitasTokens.space2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.addCategoryLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = (constraints.maxWidth - _gap * (_perRow - 1)) / _perRow;
          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final c in chips)
                SizedBox(
                  width: cell,
                  child: _Chip(
                    key: Key('category.${c.id}'),
                    glyph: categoryLook(icon: c.icon, color: c.color).glyph,
                    label: c.name,
                    note: c.archived ? l10n.addArchived : null,
                    selected: c.id == selectedId,
                    onTap: () => onSelect(c.id),
                  ),
                ),
              if (overflow)
                SizedBox(
                  width: cell,
                  child: _Chip(
                    key: const Key('add.moreCategories'),
                    glyph: expanded ? '−' : '⋯',
                    label: expanded ? l10n.addFewerCategories : l10n.addMoreCategories,
                    selected: false,
                    expandedState: expanded,
                    onTap: onToggleAll,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
    this.note,
    this.expandedState,
  });

  final String glyph;
  final String label;
  final String? note;
  final bool selected;
  final bool? expandedState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final spoken = note == null ? label : '$label ($note)';
    return Semantics(
      button: true,
      selected: selected,
      expanded: expandedState,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceRow,
                borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
                border: Border.all(color: colors.stroke, width: 2),
                boxShadow: [BoxShadow(color: colors.surfaceEdge, offset: const Offset(0, 3))],
              ),
              foregroundDecoration: selected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(LukitasTokens.radiusMd + 4),
                      border: Border.all(color: colors.gold, width: 3),
                    )
                  : null,
              child: Text(glyph, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 6),
            Text(
              spoken,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: selected ? colors.ink : colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
