// The welcome's use of the category sheet: the web's CategoryForm (apps/web/app/features/categories/
// CategoryForm.tsx) with `initial`, `onSave` and `removal`, as the categories step opens it. The
// sheet itself (its fields and look) is the one of home's Categorías tab
// (lib/categories/category_sheet.dart); what differs is what saving does and what else it offers
// besides: deleting a category with no transactions, or archiving one that has some.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../categories/category_model.dart';
import '../categories/category_sheet.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/press_button.dart';
import '../ui/sheet.dart';

/// What the sheet offers besides saving, when editing: deleting (no transactions; the API
/// archives), archiving (it has transactions, so it can't go), or nothing yet while they are
/// counted.
sealed class CategoryRemoval {
  const CategoryRemoval();
}

class RemovalCounting extends CategoryRemoval {
  const RemovalCounting();
}

class RemovalDelete extends CategoryRemoval {
  const RemovalDelete(this.onRemove);

  final Future<void> Function() onRemove;
}

class RemovalArchive extends CategoryRemoval {
  const RemovalArchive({required this.count, required this.capped, required this.onRemove});

  final int count;
  final bool capped;
  final Future<void> Function() onRemove;
}

/// The count failed: only archiving is safe.
class RemovalUnknown extends CategoryRemoval {
  const RemovalUnknown(this.onRemove);

  final Future<void> Function() onRemove;
}

/// Opens the sheet: "Nueva categoría" when [initial] is null, else "Editar categoría" with that
/// category's values. [onSave] saves; a rejection is said inside the sheet ([errorText]), which
/// stays open with what was typed. [removal] says what else it offers once the category's
/// transactions are counted (null when adding).
Future<void> openWelcomeCategorySheet(
  BuildContext context, {
  NewCategory? initial,
  required Future<void> Function(NewCategory) onSave,
  required String Function(Object problem) errorText,
  ValueListenable<CategoryRemoval>? removal,
}) {
  final l10n = AppLocalizations.of(context);
  final form = WelcomeCategoryForm(
    l10n: l10n,
    initial: initial,
    onSave: onSave,
    errorText: errorText,
    removal: removal,
  );
  return LkSheet.show<void>(
    context,
    title: initial == null ? l10n.categoryFormAddTitle : l10n.categoryFormEditTitle,
    children: [CategoryFormBody(form: form)],
  ).whenComplete(form.dispose);
}

class WelcomeCategoryForm extends CategoryFormModel {
  WelcomeCategoryForm({
    required super.l10n,
    NewCategory? initial,
    required this.onSave,
    required this.errorText,
    this.removal,
  }) : editing = initial != null,
       super(initial: initial ?? NewCategory.blank()) {
    removal?.addListener(notifyListeners);
  }

  /// Editing an existing category (or a suggestion) rather than adding one.
  final bool editing;
  final Future<void> Function(NewCategory) onSave;
  final String Function(Object problem) errorText;
  final ValueListenable<CategoryRemoval>? removal;

  CategoryRemoval? get _removal => removal?.value;

  // The kind can't change while the transactions are counted or when there are some.
  @override
  bool get locked => switch (_removal) {
    RemovalCounting() || RemovalArchive() || RemovalUnknown() => true,
    _ => false,
  };

  @override
  bool get sayLocked => switch (_removal) {
    RemovalArchive() || RemovalUnknown() => true,
    _ => false,
  };

  @override
  void dispose() {
    removal?.removeListener(notifyListeners);
    super.dispose();
  }

  /// Runs a write, and closes the sheet once it is through; a failure is said in the sheet.
  Future<void> _act(BuildContext context, Future<void> Function() write) async {
    if (saving) return;
    final navigator = Navigator.of(context);
    saving = true;
    error = null;
    notifyListeners();
    try {
      await write();
      if (!disposed) navigator.pop();
    } on Object catch (problem) {
      error = errorText(problem);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  Future<void> save(BuildContext context) async {
    final trimmed = values.name.trim();
    if (trimmed.isEmpty) {
      error = l10n.categoryFormNameRequired;
      notifyListeners();
      return;
    }
    await _act(context, () => onSave(values.copyWith(name: trimmed)));
  }

  @override
  Widget? removalSection(BuildContext context) {
    final colors = context.lkColors;
    final removal = _removal;
    return switch (removal) {
      null => null,
      RemovalCounting() => Semantics(
        liveRegion: true,
        child: Text(
          l10n.categoryFormCounting,
          key: const Key('category.counting'),
          style: LkText.note.copyWith(color: colors.inkMuted),
        ),
      ),
      RemovalDelete() => Align(
        alignment: Alignment.center,
        child: PressButton(
          key: const Key('category.delete'),
          tone: PressTone.ghost,
          onPressed: saving ? null : () => unawaited(_act(context, removal.onRemove)),
          child: Text(
            LkText.upperCase(l10n.categoryFormDelete),
            style: TextStyle(color: colors.over, decorationColor: colors.over),
          ),
        ),
      ),
      RemovalArchive() || RemovalUnknown() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LukitasTokens.space2,
        children: [
          Text(
            switch (removal) {
              RemovalUnknown() => l10n.categoryFormCountFailed,
              RemovalArchive(:final capped, :final count) =>
                capped
                    ? l10n.categoryFormHasManyTransactions(count)
                    : l10n.categoryFormHasTransactions(count),
              _ => '',
            },
            key: const Key('category.removal.note'),
            style: LkText.note.copyWith(color: colors.ink),
          ),
          PressButton.text(
            l10n.categoryFormArchive,
            key: const Key('category.archive'),
            tone: PressTone.secondary,
            onPressed: saving
                ? null
                : () => unawaited(
                    _act(context, switch (removal) {
                      RemovalArchive(:final onRemove) => onRemove,
                      RemovalUnknown(:final onRemove) => onRemove,
                      _ => () async {},
                    }),
                  ),
          ),
        ],
      ),
    };
  }
}
