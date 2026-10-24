// The Categorías tab of home: the web's `Budgets` (apps/web/app/features/home/Home.tsx), inside
// `.lk-panel` (a flex column with a gap of `--space-2`).
import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../home/category_look.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/budget_bar.dart';
import '../ui/category_row.dart';
import '../ui/lk_theme.dart';

/// How the API rates a category this month, as the bar takes it.
BudgetState budgetStateOf(SummaryCategoriesInnerStateEnum state) => switch (state) {
  SummaryCategoriesInnerStateEnum.near => BudgetState.near,
  SummaryCategoriesInnerStateEnum.over => BudgetState.over,
  _ => BudgetState.ok,
};

/// One row per spending category of [summary], in the categories' own order, each opening that
/// category's detail ([onOpen] gets its id). The summary keeps an archived category only while it
/// has spending that month; such a row says "archivada". An account with no spending category says
/// so. The figures are [summary]'s: never recomputed here.
class BudgetsTab extends StatelessWidget {
  const BudgetsTab({
    super.key,
    required this.summary,
    required this.categories,
    required this.currency,
    required this.onOpen,
  });

  final Summary summary;

  /// Every category by id (archived ones too).
  final Map<String, Category> categories;
  final String currency;
  final void Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final found = <(int, SummaryCategoriesInner, Category)>[
      for (final (index, line) in summary.categories.indexed)
        if (categories[line.categoryId] case final category?
            when category.kind == CategoryKindEnum.expense)
          (index, line, category),
    ];
    // By the categories' own order, and the summary's among equals (JavaScript's sort is stable).
    found.sort((a, b) {
      final byOrder = a.$3.sortOrder.compareTo(b.$3.sortOrder);
      return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
    });
    final rows = [for (final (_, line, category) in found) (line, category)];
    if (rows.isEmpty) {
      return Text(
        l10n.homeNoExpenseCategories,
        style: LkText.bodySm.copyWith(color: context.lkColors.inkMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space2,
      children: [
        for (final (line, category) in rows)
          CategoryRow(
            key: ValueKey(category.id),
            name: category.name,
            note: category.archived ? l10n.budgetsArchivedNote : null,
            glyph: categoryLook(icon: category.icon, color: category.color).glyph,
            tint: categoryLook(icon: category.icon, color: category.color).tint,
            budget: line.budget,
            spent: line.spent,
            remaining: line.remaining,
            state: budgetStateOf(line.state),
            currency: currency,
            onOpen: () => onOpen(category.id),
          ),
      ],
    );
  }
}
