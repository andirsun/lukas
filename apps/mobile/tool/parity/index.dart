// The review index: one page listing every pair compose.dart composed, with its picture, its ink
// share and its known-difference note, worst first. Run after compose.dart:
//
//   dart run tool/parity/index.dart        # → build/parity/index.html (git-ignored, review only)
import 'dart:convert';
import 'dart:io';

String _esc(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

void main() {
  final root = File.fromUri(Platform.script).parent.parent.parent.path;
  final summary =
      (jsonDecode(File('$root/build/parity/summary.json').readAsStringSync()) as Map<String, Object?>)
          .cast<String, Map<String, Object?>>();
  final names = summary.keys.toList()
    ..sort((a, b) => (summary[b]!['inkPercent']! as num).compareTo(summary[a]!['inkPercent']! as num));
  final worst = names.isEmpty ? 0 : (summary[names.first]!['inkPercent']! as num);
  final b = StringBuffer()
    ..writeln('<!doctype html><html lang="en"><meta charset="utf-8">')
    ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1">')
    ..writeln('<title>Lukitas parity index</title>')
    ..writeln('<style>')
    ..writeln('body{font:14px/1.4 system-ui,sans-serif;margin:16px;background:#fafafa;color:#222}')
    ..writeln('.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:16px}')
    ..writeln('figure{margin:0;background:#fff;border:1px solid #ddd;border-radius:8px;padding:8px}')
    ..writeln('img{width:100%;height:auto;display:block}')
    ..writeln('figcaption{margin-top:6px}b{font-variant-numeric:tabular-nums}')
    ..writeln('.warn{color:#b45309}.note{color:#555;font-size:12px}')
    ..writeln('</style>')
    ..writeln('<h1>Parity: ${names.length} pairs</h1>')
    ..writeln('<p>Worst pair: ${worst.toStringAsFixed(2)}% of its ink differs (the limit is 2%). '
        'Sorted worst first. Each picture: the web top left, the app top right, '
        'the differing pixels in magenta underneath.</p>')
    ..writeln('<div class="grid">');
  for (final name in names) {
    final e = summary[name]!;
    final ink = (e['inkPercent']! as num).toStringAsFixed(2);
    final page = (e['canvasPercent']! as num).toStringAsFixed(2);
    final notes = [...?(e['knownDifferences'] as List<Object?>?)?.cast<String>()];
    final image = (e['image']! as String).replaceFirst('build/parity/', '');
    b
      ..writeln('<figure><a href="${_esc(image)}"><img loading="lazy" src="${_esc(image)}" alt="${_esc(name)}"></a>')
      ..writeln('<figcaption><b>${_esc(name)}</b><br>'
          '<span class="${(e['inkPercent']! as num) > 2 ? 'warn' : ''}">$ink% of the ink differs</span> '
          '($page% of the page)<br><span class="note">${_esc(e['storyId']! as String)}</span>');
    for (final n in notes) {
      b.writeln('<br><span class="note"><b>Known difference:</b> ${_esc(n)}</span>');
    }
    b.writeln('</figcaption></figure>');
  }
  b.writeln('</div></html>');
  File('$root/build/parity/index.html').writeAsStringSync(b.toString());
  stdout.writeln('build/parity/index.html: ${names.length} pairs, worst ${worst.toStringAsFixed(2)}%');
}
