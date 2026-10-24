// The Categorías tab of home: the web's `CategoriesTab`
// (apps/web/app/features/categories/CategoriesTab.tsx), inside `.lk-panel` (a flex column with a gap
// of `--space-2`).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../categories/categories_actions.dart';
import '../categories/category_sheet.dart';
import '../home/category_look.dart';
import '../home/home_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/budget_bar.dart';
import '../ui/category_row.dart';
import '../ui/lk_theme.dart';
import '../ui/press_button.dart';
import '../ui/segmented_control.dart';
import '../ui/toast.dart';

/// How the API rates a category this month, as the bar takes it.
BudgetState budgetStateOf(SummaryCategoriesInnerStateEnum state) => switch (state) {
  SummaryCategoriesInnerStateEnum.near => BudgetState.near,
  SummaryCategoriesInnerStateEnum.over => BudgetState.over,
  _ => BudgetState.ok,
};

/// Where categories are managed (founder decision 2026-10-24; there is no separate page): a
/// Gastos | Ingresos switch ([kind], [onKind]); one row per category of that kind, in the categories'
/// own order, each opening its detail ([onOpen] gets its id): a spending category with its month's
/// budget bar (the figures are [summary]'s: never recomputed here), an income one with "Ingreso";
/// "Nueva categoría"; and the archived ones of that kind folded at the end ([showArchived],
/// [onToggleArchived]), each with "Restaurar". An archived spending category that has spending in
/// the month on screen is one of the rows instead, noted "archivada". Renaming, the emoji and
/// colour, and archiving are in the detail.
class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({
    super.key,
    required this.summary,
    required this.categories,
    required this.currency,
    required this.kind,
    required this.onKind,
    required this.showArchived,
    required this.onToggleArchived,
    required this.onOpen,
  });

  final Summary summary;

  /// Every category by id (archived ones too).
  final Map<String, Category> categories;
  final String currency;

  /// Which kind is on screen.
  final CategoryKindEnum kind;
  final ValueChanged<CategoryKindEnum> onKind;
  final bool showArchived;
  final VoidCallback onToggleArchived;
  final void Function(String categoryId) onOpen;

  /// A spending category with no line in the summary (just made): no budget, nothing spent.
  static const _noLine = (budget: null, spent: 0, remaining: null);

  Future<void> _restore(BuildContext context, WidgetRef ref, Category category) async {
    final l10n = AppLocalizations.of(context);
    final toasts = ToastHost.of(context);
    try {
      await ref.read(categoriesActionsProvider).restore(category);
    } on HomeFailure catch (failure) {
      toasts.say(categoryFailureMessage(l10n, failure), error: true);
      return;
    }
    toasts.say(l10n.categoriesRestored(category.name));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final lines = {for (final line in summary.categories) line.categoryId: line};
    final ofKind = [
      for (final (index, category) in categories.values.indexed)
        if (category.kind == kind) (index, category),
    ];
    // By the categories' own order, and the list's among equals (JavaScript's sort is stable).
    ofKind.sort((a, b) {
      final byOrder = a.$2.sortOrder.compareTo(b.$2.sortOrder);
      return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
    });
    // An archived spending category with a line in the summary has spending in the month on screen
    // (the API keeps it only then): it stays among the rows, noted, as the web lists it; the rest
    // wait in the fold.
    bool spentThisMonth(Category category) =>
        kind == CategoryKindEnum.expense && category.archived && lines.containsKey(category.id);
    final active = [
      for (final (_, category) in ofKind)
        if (!category.archived || spentThisMonth(category)) category,
    ];
    final archived = [
      for (final (_, category) in ofKind)
        if (category.archived && !spentThisMonth(category)) category,
    ];
    final income = kind == CategoryKindEnum.income;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space2,
      children: [
        _SwitchAndAdd(
          switcher: SegmentedControl<CategoryKindEnum>(
            label: l10n.categoriesKindLabel,
            value: kind,
            options: [
              SegmentOption(
                CategoryKindEnum.expense,
                l10n.categoriesExpenses,
                key: const Key('categories.kind.expense'),
              ),
              SegmentOption(
                CategoryKindEnum.income,
                l10n.categoriesIncome,
                key: const Key('categories.kind.income'),
              ),
            ],
            onChanged: onKind,
          ),
          add: PressButton(
            key: const Key('categories.add'),
            size: PressSize.sm,
            semanticLabel: l10n.categoriesAdd,
            onPressed: () => unawaited(openCategorySheet(context)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: LukitasTokens.space2,
              children: [
                const ExcludeSemantics(child: Text('＋')),
                Text(LkText.upperCase(l10n.categoriesAdd)),
              ],
            ),
          ),
        ),
        if (active.isEmpty)
          Text(
            income ? l10n.categoriesNoneOfKind : l10n.homeNoExpenseCategories,
            style: LkText.bodySm.copyWith(color: colors.inkMuted),
          )
        else
          for (final category in active) _row(l10n, category, lines[category.id], income),
        if (archived.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LukitasTokens.space2,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PressButton(
                  key: const Key('categories.fold'),
                  tone: PressTone.secondary,
                  expanded: showArchived,
                  onPressed: onToggleArchived,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: LukitasTokens.space2,
                    children: [
                      ExcludeSemantics(child: Text(showArchived ? '▾' : '▸')),
                      Text(LkText.upperCase(l10n.categoriesArchivedFold(archived.length))),
                    ],
                  ),
                ),
              ),
              if (showArchived)
                Semantics(
                  container: true,
                  label: l10n.categoriesArchivedTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: LukitasTokens.space2,
                    children: [
                      for (final category in archived) _archivedRow(context, ref, l10n, category),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, Category category, SummaryCategoriesInner? line, bool income) {
    final look = categoryLook(icon: category.icon, color: category.color);
    return CategoryRow(
      key: ValueKey(category.id),
      name: category.name,
      glyph: look.glyph,
      tint: look.tint,
      budget: line?.budget ?? _noLine.budget,
      spent: line?.spent ?? _noLine.spent,
      remaining: line?.remaining ?? _noLine.remaining,
      state: line == null ? BudgetState.ok : budgetStateOf(line.state),
      currency: currency,
      line: income ? l10n.categoriesIncomeLine : null,
      note: category.archived ? l10n.budgetsArchivedNote : null,
      onOpen: () => onOpen(category.id),
    );
  }

  Widget _archivedRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Category category,
  ) {
    final look = categoryLook(icon: category.icon, color: category.color);
    return CategoryRow(
      key: ValueKey(category.id),
      name: category.name,
      glyph: look.glyph,
      tint: look.tint,
      budget: null,
      spent: 0,
      remaining: null,
      state: BudgetState.ok,
      currency: currency,
      line: l10n.categoryArchivedLine,
      onOpen: () => onOpen(category.id),
      control: PressButton(
        key: Key('categories.restore.${category.id}'),
        tone: PressTone.secondary,
        size: PressSize.sm,
        semanticLabel: l10n.categoriesRestoreNamed(category.name),
        onPressed: () => unawaited(_restore(context, ref, category)),
        child: Text(LkText.upperCase(l10n.categoriesRestore)),
      ),
    );
  }
}

/// `flex flex-wrap items-center gap-(--space-2)` holding the switch (`min-w-[200px] flex-1`) and the
/// button: side by side when the switch keeps its 200px, otherwise the switch takes the whole row
/// and the button sits under it, at the start.
class _SwitchAndAdd extends MultiChildRenderObjectWidget {
  _SwitchAndAdd({required Widget switcher, required Widget add}) : super(children: [switcher, add]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSwitchAndAdd();
}

class _SwitchAndAddData extends ContainerBoxParentData<RenderBox> {}

class _RenderSwitchAndAdd extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SwitchAndAddData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SwitchAndAddData> {
  static const _minSwitch = 200.0;
  static const _gap = LukitasTokens.space2;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SwitchAndAddData) child.parentData = _SwitchAndAddData();
  }

  RenderBox get _switch => firstChild!;
  RenderBox get _add => childAfter(firstChild!)!;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final add = _add.getDryLayout(BoxConstraints(maxWidth: width));
    if (_minSwitch + _gap + add.width <= width) {
      final sw = _switch.getDryLayout(BoxConstraints.tightFor(width: width - _gap - add.width));
      return Size(width, sw.height > add.height ? sw.height : add.height);
    }
    final sw = _switch.getDryLayout(BoxConstraints.tightFor(width: width));
    return Size(width, sw.height + _gap + add.height);
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    _add.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    final addSize = _add.size;
    final switchData = _switch.parentData! as _SwitchAndAddData;
    final addData = _add.parentData! as _SwitchAndAddData;
    if (_minSwitch + _gap + addSize.width <= width) {
      _switch.layout(
        BoxConstraints.tightFor(width: width - _gap - addSize.width),
        parentUsesSize: true,
      );
      final height = _switch.size.height > addSize.height ? _switch.size.height : addSize.height;
      switchData.offset = Offset(0, (height - _switch.size.height) / 2);
      addData.offset = Offset(width - addSize.width, (height - addSize.height) / 2);
      size = Size(width, height);
    } else {
      _switch.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      switchData.offset = Offset.zero;
      addData.offset = Offset(0, _switch.size.height + _gap);
      size = Size(width, _switch.size.height + _gap + addSize.height);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
