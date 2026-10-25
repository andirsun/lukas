import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../home/category_look.dart';
import '../l10n/app_localizations.dart';
import '../ui/category_chip.dart';

/// The categories as chips four to a row (the web's `lk-chips` of `CategoryChip`), the selected one
/// outlined in gold; "Más" (or "Menos") at the end when some are folded.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.addCategoryLabel,
      child: CategoryChipGrid(
        children: [
          for (final c in chips)
            CategoryChip(
              key: Key('category.${c.id}'),
              glyph: categoryLook(icon: c.icon, color: c.color).glyph,
              label: c.name,
              note: c.archived ? l10n.addArchived : null,
              selected: c.id == selectedId,
              onSelect: () => onSelect(c.id),
            ),
          if (overflow)
            CategoryChip(
              key: const Key('add.moreCategories'),
              glyph: expanded ? '−' : '⋯',
              label: expanded ? l10n.addFewerCategories : l10n.addMoreCategories,
              selected: false,
              expanded: expanded,
              onSelect: onToggleAll,
            ),
        ],
      ),
    );
  }
}
