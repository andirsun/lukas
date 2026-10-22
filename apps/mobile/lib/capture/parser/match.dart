// The category of a draft (spec 5.2): the usual category of that name, else a category with that
// name, else none. Only categories of the draft's kind count: a transaction takes its sign from
// its category, so an income draft must never land in an expense category. Names compare whole, ignoring accents and case on both sides; there are no
// partial matches (`cafetería` is not `Café`, `transportes` is not `Transporte`).
import 'types.dart';
import 'words.dart';

String _key(String name) => fold(name).trim().split(RegExp(r'\s+')).join(' ');

String? matchCategory(String name, Kind kind, List<Usual> usual, List<Category> categories) {
  if (name.trim().isEmpty) return null;
  final key = _key(name);
  final sameKind = {
    for (final c in categories)
      if (c.kind == kind) c.id: c,
  };
  for (final u in usual) {
    // A usual pair counts only when its category is known and of the draft's kind.
    if (_key(u.name) == key && sameKind.containsKey(u.categoryId)) return u.categoryId;
  }
  for (final c in sameKind.values) {
    if (_key(c.name) == key) return c.id;
  }
  return null;
}
