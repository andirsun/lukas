// The category of a draft (spec 5.2): the usual category of that name, else a category with that
// name, else none. Names compare whole, ignoring accents and case on both sides; there are no
// partial matches (`cafetería` is not `Café`, `transportes` is not `Transporte`).
import 'types.dart';
import 'words.dart';

String _key(String name) => fold(name).trim().split(RegExp(r'\s+')).join(' ');

String? matchCategory(String name, List<Usual> usual, List<Category> categories) {
  if (name.trim().isEmpty) return null;
  final key = _key(name);
  for (final u in usual) {
    if (_key(u.name) == key) return u.categoryId;
  }
  for (final c in categories) {
    if (_key(c.name) == key) return c.id;
  }
  return null;
}
