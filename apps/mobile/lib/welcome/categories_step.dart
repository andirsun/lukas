// The welcome's categories: the web's CategoriesStep (apps/web/app/features/onboarding/
// CategoriesStep.tsx). Their own first, then the suggestions they don't cover, spending apart from
// income. Tapping a chip chooses or drops it (with no categories yet, the suggestions come
// pre-selected; SIGUIENTE works with no input). "Editar categorías" turns the chips into edit
// buttons: rename, emoji, tint, kind, and delete (archive with transactions). "＋ Agregar categoría"
// makes a new one.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../categories/category_model.dart';
import '../home/category_look.dart';
import '../import/note_text.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/category_chip.dart';
import '../ui/lk_theme.dart';
import '../ui/offset_underline.dart';
import '../ui/press_button.dart';
import 'category_chips.dart';
import 'category_form_sheet.dart';
import 'step_frame.dart';
import 'steps.dart';
import 'welcome_controller.dart';

class CategoriesStep extends StatefulWidget {
  const CategoriesStep({
    super.key,
    required this.chips,
    required this.selected,
    required this.onToggle,
    this.notice,
    required this.onCreate,
    required this.onEdit,
    required this.onRemove,
    required this.transactionsOf,
    required this.errorText,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    this.busy = false,
    this.error,
  });

  /// Their categories first (after an import, the file's), then the suggestions not covered.
  final List<CategoryChipModel> chips;

  /// Chip ids that are chosen.
  final Set<String> selected;
  final Future<void> Function(String chipId) onToggle;

  /// Why a tapped chip stayed chosen (it has transactions), if one did.
  final CategoryNotice? notice;
  final Future<void> Function(NewCategory category) onCreate;
  final Future<void> Function(String chipId, NewCategory category) onEdit;

  /// Deletes (archives) or archives a category; a suggestion just leaves the step.
  final Future<void> Function(String chipId) onRemove;

  /// How many transactions a chip's category has (decides delete or archive).
  final Future<({int count, bool capped})> Function(String chipId) transactionsOf;
  final String Function(Object problem) errorText;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool busy;
  final String? error;

  @override
  State<CategoriesStep> createState() => _CategoriesStepState();
}

class _CategoriesStepState extends State<CategoriesStep> {
  var _editing = false;

  void _openEdit(CategoryChipModel chip) {
    final removal = ValueNotifier<CategoryRemoval>(const RemovalCounting());
    Future<void> remove() => widget.onRemove(chip.id);
    unawaited(
      widget.transactionsOf(chip.id).then(
        (counted) {
          removal.value = counted.count == 0
              ? RemovalDelete(remove)
              : RemovalArchive(count: counted.count, capped: counted.capped, onRemove: remove);
        },
        // Not knowing the count, only archiving is safe.
        onError: (Object _) => removal.value = RemovalUnknown(remove),
      ),
    );
    unawaited(
      openWelcomeCategorySheet(
        context,
        initial: NewCategory(name: chip.name, glyph: chip.glyph, tint: chip.tint, kind: chip.kind),
        onSave: (values) => widget.onEdit(chip.id, values),
        errorText: widget.errorText,
        removal: removal,
      ).whenComplete(removal.dispose),
    );
  }

  Widget _group(AppLocalizations l10n, CategoryKindEnum kind, String label) {
    final colors = context.lkColors;
    final chips = [
      for (final c in widget.chips)
        if (c.kind == kind) c,
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space2,
        children: [
          Semantics(
            header: true,
            child: Text(
              label,
              style: LkText.sectionTitle.copyWith(fontSize: 18, height: 1.5, color: colors.ink),
            ),
          ),
          CategoryChipGrid(
            children: [
              for (final c in chips)
                _editing
                    ? CategoryChip(
                        key: Key('welcome.chip.${c.id}'),
                        glyph: c.glyph,
                        label: c.name,
                        selected: false,
                        editLabel: l10n.welcomeCategoriesEditLabel(c.name),
                        tileFill: Color.lerp(
                          colors.surfaceRow,
                          categoryLook(icon: '', color: c.tint).tint,
                          0.35,
                        ),
                        onSelect: () => _openEdit(c),
                      )
                    : CategoryChip(
                        key: Key('welcome.chip.${c.id}'),
                        glyph: c.glyph,
                        label: c.name,
                        selected: widget.selected.contains(c.id),
                        onSelect: () => unawaited(widget.onToggle(c.id)),
                      ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final notice = widget.notice;
    return StepFrame(
      step: StepId.categories,
      title: l10n.welcomeCategoriesTitle,
      lead: widget.chips.any((c) => c.source == ChipSource.category)
          ? l10n.welcomeCategoriesLead
          : l10n.welcomeCategoriesLeadFresh,
      onBack: widget.onBack,
      skip: StepAction(label: l10n.welcomeSkip, onPressed: widget.busy ? null : widget.onSkip),
      next: StepAction(
        label: widget.busy ? l10n.welcomeSaving : l10n.welcomeNext,
        onPressed: widget.busy ? null : widget.onNext,
      ),
      children: [
        // `flex items-center justify-between gap-2`; the hint is only read out unless editing.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: LukitasTokens.space2,
          children: [
            if (_editing)
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: NoteText(
                    l10n.welcomeCategoriesEditHint,
                    LkText.note.copyWith(color: colors.inkMuted),
                  ),
                ),
              ),
            PressButton(
              key: const Key('welcome.categories.edit'),
              tone: PressTone.ghost,
              size: PressSize.sm,
              expanded: null,
              semanticLabel: _editing
                  ? l10n.welcomeCategoriesEditDone
                  : l10n.welcomeCategoriesEditToggle,
              onPressed: () => setState(() => _editing = !_editing),
              child: OffsetUnderline(
                LkText.upperCase(
                  _editing ? l10n.welcomeCategoriesEditDone : l10n.welcomeCategoriesEditToggle,
                ),
              ),
            ),
          ],
        ),
        if (notice != null)
          Semantics(
            liveRegion: true,
            container: true,
            child: NoteText(
              switch (notice) {
                HasTransactionsNotice(:final name, :final count) =>
                  l10n.welcomeCategoriesCantRemove(name, count),
                UnknownNotice(:final name) => l10n.welcomeCategoriesCantRemoveUnknown(name),
              },
              LkText.note.copyWith(color: colors.ink),
              key: const Key('welcome.categories.notice'),
            ),
          ),
        _group(l10n, CategoryKindEnum.expense, l10n.welcomeCategoriesExpenses),
        _group(l10n, CategoryKindEnum.income, l10n.welcomeCategoriesIncome),
        SizedBox(
          width: double.infinity,
          child: PressButton(
            key: const Key('welcome.categories.add'),
            tone: PressTone.secondary,
            semanticLabel: l10n.welcomeCategoriesAdd,
            onPressed: () => unawaited(
              openWelcomeCategorySheet(
                context,
                onSave: widget.onCreate,
                errorText: widget.errorText,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: LukitasTokens.space2,
              children: [
                const ExcludeSemantics(child: Text('＋')),
                Text(LkText.upperCase(l10n.welcomeCategoriesAdd)),
              ],
            ),
          ),
        ),
        if (widget.error != null) StepError(widget.error!),
      ],
    );
  }
}
