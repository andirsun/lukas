// The web's CategoryForm and the sheets around it (apps/web/app/features/categories/CategoryForm.tsx
// and use-category-sheets.tsx), with the CSS they use: app.css `.lk-input`, and the radio tiles
// (`OPTION` in CategoryForm.tsx).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../home/category_look.dart';
import '../home/home_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/confirm_sheet.dart';
import '../ui/css_text.dart';
import '../ui/lk_theme.dart';
import '../ui/press_button.dart';
import '../ui/pressable.dart';
import '../ui/sheet.dart';
import '../ui/toast.dart';
import '../ui/web_text_field.dart';
import 'categories_actions.dart';
import 'category_model.dart';

/// Opens the category sheet: "Nueva categoría" when [editing] is null, else that category's name,
/// emoji, colour and kind (the kind is fixed while it has transactions), with "Archivar categoría"
/// for one that is not archived: the sheet closes and the question, with its count of recurring
/// payments, takes its place.
///
/// A refusal (a name already taken, say) is said inside the sheet, which stays open with what was
/// typed; a saved one closes it and says so in a toast.
Future<void> openCategorySheet(BuildContext context, {Category? editing}) {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final form = _CategoryForm(
    editing: editing,
    l10n: l10n,
    actions: container.read(categoriesActionsProvider),
    toasts: ToastHost.of(context),
    // The question needs the screen's own context, which outlives this sheet.
    onArchive: editing == null || editing.archived
        ? null
        : (stopping) {
            if (context.mounted) {
              unawaited(openArchiveSheet(context, category: editing, stopping: stopping));
            }
          },
  );
  return LkSheet.show<void>(
    context,
    title: editing == null ? l10n.categoryFormAddTitle : l10n.categoryFormEditTitle,
    children: [_FormBody(form: form)],
  ).whenComplete(form.dispose);
}

/// The archive question (the web's `ConfirmSheet` in `useCategorySheets`): what archiving means,
/// how many recurring payments it also stops ([stopping], none: no line), "Cancelar" and
/// "Sí, archivar". A failure is said in a toast and the sheet stays for another try.
Future<bool> openArchiveSheet(
  BuildContext context, {
  required Category category,
  required int stopping,
}) {
  final l10n = AppLocalizations.of(context);
  final actions = ProviderScope.containerOf(context).read(categoriesActionsProvider);
  final toasts = ToastHost.of(context);
  return ConfirmSheet.show(
    context,
    title: l10n.archiveSheetTitle(category.name),
    body: l10n.archiveSheetBody,
    note: stopping > 0 ? l10n.archiveSheetStopsRecurring(stopping) : null,
    confirmLabel: l10n.archiveSheetConfirm,
    confirmKey: const Key('category.archive.confirm'),
    onConfirm: () async {
      try {
        await actions.archive(category);
      } on HomeFailure catch (failure) {
        toasts.say(categoryFailureMessage(l10n, failure), error: true);
        rethrow;
      }
      toasts.say(l10n.categoriesArchivedToast(category.name));
    },
  );
}

/// What the sheet holds: the values, the error being shown, whether a save is under way, and
/// whether the kind is fixed.
class _CategoryForm extends ChangeNotifier {
  _CategoryForm({
    required this.editing,
    required this.l10n,
    required this.actions,
    required this.toasts,
    required this.onArchive,
  }) : values = editing == null ? NewCategory.blank() : NewCategory.of(editing),
       name = TextEditingController(text: editing?.name ?? ''),
       nameFocus = FocusNode() {
    final category = editing;
    if (category != null) {
      stopping = category.archived ? null : actions.recurrencesStopped(category.id);
      unawaited(
        actions.hasTransactions(category.id).then((has) {
          kindLocked = has ? _Locked.yes : _Locked.no;
          notifyListeners();
        }),
      );
    }
    name.addListener(() {
      final text = name.text;
      if (text == values.name) return;
      values = values.copyWith(name: text);
      notifyListeners();
    });
  }

  final Category? editing;
  final AppLocalizations l10n;
  final CategoriesActions actions;
  final ToastController toasts;

  /// Asks the archive question once the sheet has closed, with the recurring payments it stops.
  final void Function(int stopping)? onArchive;

  NewCategory values;
  final TextEditingController name;
  final FocusNode nameFocus;
  String? error;
  bool saving = false;
  bool _disposed = false;

  /// While the transactions are counted the kind is fixed too, without saying why.
  _Locked kindLocked = _Locked.counting;

  /// How many recurring payments archiving stops, asked when the sheet opens.
  Future<int>? stopping;

  bool get editingExisting => editing != null;
  bool get locked => editing != null && kindLocked != _Locked.no;
  bool get sayLocked => editing != null && kindLocked == _Locked.yes;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    name.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  void set(NewCategory next) {
    values = next;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    if (saving) return;
    final trimmed = values.name.trim();
    if (trimmed.isEmpty) {
      error = l10n.categoryFormNameRequired;
      notifyListeners();
      return;
    }
    final navigator = Navigator.of(context);
    saving = true;
    error = null;
    notifyListeners();
    final category = editing;
    final toSave = values.copyWith(name: trimmed);
    try {
      if (category == null) {
        await actions.create(toSave);
      } else {
        await actions.save(category, toSave);
      }
    } on HomeFailure catch (failure) {
      saving = false;
      error = categoryFailureMessage(l10n, failure);
      notifyListeners();
      return;
    }
    if (_disposed) {
      // Closed meanwhile (a drag down): it was still saved, and it says so.
    } else {
      saving = false;
      navigator.pop();
    }
    toasts.say(
      category == null ? l10n.categoriesCreated(toSave.name) : l10n.categoriesSaved(toSave.name),
    );
  }

  /// "Archivar categoría": the sheet goes, and the question comes after it.
  Future<void> archive(BuildContext context) async {
    if (saving || onArchive == null) return;
    final count = await stopping ?? 0;
    if (_disposed || !context.mounted) return;
    Navigator.of(context).pop();
    onArchive!(count);
  }
}

enum _Locked { counting, yes, no }

/// `<form className="flex flex-col gap-(--space-4) pt-(--space-3)">`.
class _FormBody extends StatelessWidget {
  const _FormBody({required this.form});

  final _CategoryForm form;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: form,
    builder: (context, _) {
      final l10n = form.l10n;
      final colors = context.lkColors;
      final values = form.values;
      final nameInvalid = form.error != null && values.name.trim().isEmpty;
      return Padding(
        padding: const EdgeInsets.only(top: LukitasTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space4,
          children: [
            _Group(
              label: l10n.categoryFormNameLabel,
              child: WebTextField(
                controller: form.name,
                focusNode: form.nameFocus,
                fieldKey: const Key('category.name'),
                label: l10n.categoryFormNameLabel,
                placeholder: l10n.categoryFormNamePlaceholder,
                invalid: nameInvalid,
                inputFormatters: [LengthLimitingTextInputFormatter(categoryNameMaxLength)],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => unawaited(form.save(context)),
              ),
            ),
            _Group(
              label: l10n.categoryFormKindLabel,
              disabled: form.locked,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: LukitasTokens.space2,
                children: [
                  _OptionGrid(
                    columns: 2,
                    children: [
                      for (final (kind, label, key) in [
                        (
                          CategoryKindEnum.expense,
                          l10n.categoryFormKindExpense,
                          'category.kind.expense',
                        ),
                        (
                          CategoryKindEnum.income,
                          l10n.categoryFormKindIncome,
                          'category.kind.income',
                        ),
                      ])
                        _OptionTile(
                          key: Key(key),
                          label: label,
                          selected: values.kind == kind,
                          enabled: !form.locked,
                          onSelect: () => form.set(values.copyWith(kind: kind)),
                          horizontalPadding: LukitasTokens.space3,
                          child: Text(label, style: LkText.copy.copyWith(color: colors.ink)),
                        ),
                    ],
                  ),
                  if (form.sayLocked)
                    Text(
                      l10n.categoryFormKindLocked,
                      style: LkText.note.copyWith(color: colors.inkMuted),
                    ),
                ],
              ),
            ),
            _Group(
              label: l10n.categoryFormGlyphLabel,
              child: _OptionGrid(
                columns: 5,
                children: [
                  for (final glyph in glyphChoices(values.glyph))
                    _OptionTile(
                      key: Key('category.glyph.$glyph'),
                      label: glyph,
                      selected: values.glyph == glyph,
                      onSelect: () => form.set(values.copyWith(glyph: glyph)),
                      child: Text(glyph, style: _glyphStyle.copyWith(color: colors.ink)),
                    ),
                ],
              ),
            ),
            _Group(
              label: l10n.categoryFormTintLabel,
              child: _OptionGrid(
                columns: 6,
                children: [
                  for (final name in categoryTintNames)
                    _OptionTile(
                      key: Key('category.tint.$name'),
                      label: _tintLabel(l10n, name),
                      selected: values.tint == categoryTintHex(name),
                      // `color-mix(in srgb, tint 70%, var(--surface-sunken))`.
                      fill: Color.lerp(
                        colors.surfaceSunken,
                        categoryLook(icon: '', color: name).tint,
                        0.7,
                      ),
                      onSelect: () => form.set(values.copyWith(tint: categoryTintHex(name))),
                      child: const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
            if (form.error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  form.error!,
                  key: const Key('category.error'),
                  style: LkText.note.copyWith(color: colors.over),
                ),
              ),
            Semantics(
              container: true,
              child: PressButton.text(
                l10n.categoryFormSave,
                key: const Key('category.save'),
                onPressed: form.saving ? null : () => unawaited(form.save(context)),
              ),
            ),
            if (form.onArchive != null)
              Align(
                alignment: Alignment.center,
                child: PressButton(
                  key: const Key('category.archive'),
                  tone: PressTone.ghost,
                  onPressed: form.saving ? null : () => unawaited(form.archive(context)),
                  child: Text(
                    LkText.upperCase(l10n.categoryFormArchive),
                    style: TextStyle(color: colors.over, decorationColor: colors.over),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  static const _glyphStyle = TextStyle(
    fontFamily: LkText.textFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.5,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// The colour's name for screen readers (`onboarding.categories.tints.<name>`).
String _tintLabel(AppLocalizations l10n, String name) => switch (name) {
  'orange' => l10n.categoryTintOrange,
  'red' => l10n.categoryTintRed,
  'purple' => l10n.categoryTintPurple,
  'indigo' => l10n.categoryTintIndigo,
  'blue' => l10n.categoryTintBlue,
  'pink' => l10n.categoryTintPink,
  'amber' => l10n.categoryTintAmber,
  'green' => l10n.categoryTintGreen,
  'teal' => l10n.categoryTintTeal,
  'gray' => l10n.categoryTintGray,
  'yellow' => l10n.categoryTintYellow,
  _ => l10n.categoryTintSky,
};

/// A field's caption over the field (`<label className="text-[15px] text-ink-muted">`, or the
/// `<legend className="pb-(--space-1) text-[15px] text-ink-muted">` of a group of tiles): the web
/// gives a label and a legend the same room, 4px under it. A [disabled] group (`<fieldset
/// disabled>`) is read as one that cannot be changed.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child, this.disabled = false});

  final String label;
  final Widget child;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return Semantics(
      container: true,
      enabled: !disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space1,
        children: [
          ExcludeSemantics(
            child: CssLines(
              style: LkText.note,
              child: Text(label, style: LkText.note.copyWith(color: colors.inkMuted)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// `grid grid-cols-N gap-(--space-2)`: equal columns with an 8px gap.
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  static const _gap = LukitasTokens.space2;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

/// The web's `OPTION` radio tile: a 44px tile that sits on its edge (`border-2 border-stroke
/// shadow-edge-sm`, `rounded-md`), outlined in gold while chosen (`has-checked:outline-3
/// outline-gold outline-offset-1`) and ringed while the keyboard is on it, at 60% when disabled.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelect,
    required this.child,
    this.fill,
    this.enabled = true,
    this.horizontalPadding = 0,
  });

  /// What a screen reader says.
  final String label;
  final bool selected;
  final VoidCallback onSelect;
  final Widget child;

  /// The tile's colour; the row colour without one.
  final Color? fill;
  final bool enabled;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final radius = LkSurface.radius(LkRadius.md);
    return Pressable(
      onPressed: enabled ? onSelect : null,
      label: label,
      checked: selected,
      builder: (context, state) {
        final tile = PressSurface(
          decoration: BoxDecoration(
            color: fill ?? colors.surfaceRow,
            borderRadius: radius,
            border: LkSurface.border(colors),
            boxShadow: LkSurface.edgeShadow(lk, LkEdge.sm),
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          // Focus wins over the chosen tile's gold outline.
          ringRadius: state.focusVisible || selected ? radius : null,
          ringColor: state.focusVisible ? colors.focus : colors.gold,
          ringOffset: state.focusVisible ? 2 : 1,
          child: SizedBox(
            width: double.infinity,
            child: Center(child: child),
          ),
        );
        return enabled ? tile : Opacity(opacity: 0.6, child: tile);
      },
    );
  }
}
