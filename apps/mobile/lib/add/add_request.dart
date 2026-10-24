import '../api/gen/lukitas_api.dart';
import 'add_form.dart';

/// What opens the add sheet: a new movement of [kind] (starting in [categoryId] when it is one of
/// that kind), or an existing one to edit ([editing]; [focusName] puts the cursor on its name).
class AddRequest {
  const AddRequest({
    this.kind = Kind.expense,
    this.editing,
    this.focusName = false,
    this.categoryId,
  });

  final Kind kind;
  final String? categoryId;
  final Transaction? editing;
  final bool focusName;
}
