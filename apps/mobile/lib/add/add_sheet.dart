import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/gen/lukitas_api.dart';
import '../l10n/app_localizations.dart';
import '../ui/sheet.dart';
import 'add_body.dart';
import 'add_footer.dart';
import 'add_form.dart';
import 'add_pinned.dart';
import 'add_request.dart';
import 'add_session.dart';

export 'add_form.dart' show Kind;
export 'add_session.dart' show AddSheet, SheetsWithInput, sheetsWithInputProvider;
export 'save_outcome.dart' show canRetrySave;

/// Opens the add sheet (spec section 6.1.3) to enter one movement by hand, on [kind]. It is the
/// one way in: the ＋ on home calls it, and so will the widget's deep link. It needs only the
/// app's providers (the home figures it reads categories and the currency from, and the API), no
/// home screen state.
///
/// Completes when the sheet is closed. A save closes it by itself, updates home and shows the
/// toast with Deshacer.
///
/// [categoryId] preselects a category (the "Agregar gasto" of a category's detail); the sheet
/// falls back to the first of [kind] when it is not one.
Future<void> openAddSheet(BuildContext context, {Kind kind = Kind.expense, String? categoryId}) =>
    _open(context, AddRequest(kind: kind, categoryId: categoryId));

/// Opens the sheet on an existing [transaction] (a tap on its row, a swipe right, "Ponerle
/// nombre"): saving sends only what changed. [focusName] puts the cursor on the name.
Future<void> openEditSheet(
  BuildContext context,
  Transaction transaction, {
  bool focusName = false,
}) => _open(context, AddRequest(editing: transaction, focusName: focusName));

/// The sheet is [LkSheet], the web's, with the add sheet's parts in it: the kind and the amount
/// pinned under the header, the name, the categories and "Más opciones" scrolling between, and the
/// keypad and Guardar pinned at the bottom, so every key and Guardar are in view even on a short
/// phone (apps/web/app/features/add-transaction/AddTransactionSheet.tsx). What the parts share is
/// in [AddSheet], which wraps the sheet.
Future<void> _open(BuildContext context, AddRequest request) => LkSheet.show<void>(
  context,
  title: AppLocalizations.of(context).addTitleExpense,
  titleOf: (context) => AddSession.of(context).title(context),
  wrap: (sheet) => AddSheet(
    key: const Key('add.sheet'),
    request: request,
    nameIt: (context, tx) => openEditSheet(context, tx, focusName: true),
    child: sheet,
  ),
  pinned: const [AddPinned()],
  children: const [AddBody()],
  footer: const [AddFooter()],
);
