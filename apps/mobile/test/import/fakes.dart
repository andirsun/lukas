import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/files/files_channel.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_repository.dart';

import '../budgets/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';

/// The account of the import tests: Supermercado (an expense) and Salario (an income), as the web's
/// story API starts ("some" categories), in the currency of [currency]. [live] is what the profile
/// says now: confirming an import in another currency changes it, as the real server does.
class ImportHome extends FakeHomeRepository {
  // ignore: use_super_parameters
  ImportHome({String currency = 'EUR', super.items})
    : live = currency,
      super(
        currency: currency,
        timezone: 'America/Bogota',
        categoryList: [
          category('cat-groceries', 'Supermercado', icon: '🛒', color: '#ff9f1c'),
          category('cat-salary', 'Salario', kind: 'income', icon: '💰'),
        ],
      );

  String live;

  @override
  Future<HomeProfile> profile() async {
    calls.add('profile');
    final failure = failures.remove('profile');
    if (failure != null) throw failure;
    return HomeProfile(id: userId, currency: live, timezone: timezone, email: email);
  }
}

/// A preview like the sample Budge file's (the web's `SAMPLE_PREVIEW`, story-harness.tsx): 22 rows,
/// one bad date. The window is the last 3 complete months before 22 October 2026.
Map<String, Object?> sampleStats({
  Map<String, Object?> window = const {'from': '2026-07', 'to': '2026-09', 'months': 3},
}) => {
  'transactions': 22,
  'duplicates': 3,
  'newCategories': ['Salário', 'Investimento', 'Taxes', 'Things'],
  'rejected': [
    {'line': 19, 'reason': 'invalid_date'},
  ],
  'from': '2026-09-01',
  'to': '2026-10-30',
  'averageMonthlySpending': [
    {'category': 'Ocio', 'amount': 6225},
    {'category': 'Supermercado', 'amount': 3589},
  ],
  'currency': 'EUR',
  'averageWindow': window,
  'adoptsCurrency': false,
  'dropsBudgets': false,
};

FileImport importOf(
  Map<String, Object?> stats, {
  String id = 'preview-sample',
  String status = 'preview',
}) => standardSerializers.deserializeWith(FileImport.serializer, {
  'id': id,
  'status': status,
  'stats': stats,
})!;

/// The sample file's categories as the importer names them: [name, kind, icon, color].
const _imported = [
  ('supermercado', 'expense', 'cart', 'orange'),
  ('Ocio', 'expense', 'star', 'orange'),
  ('Taxes', 'expense', 'document', 'yellow'),
  ('Salário', 'income', 'salary', 'orange'),
];

String _plain(String name) => name
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

/// The import endpoints in memory, over [home]'s server (the web's `onboardingFetch`,
/// story-harness.tsx): "the file" is always the sample, in EUR. An empty account in another
/// currency would adopt it on confirm, so its preview counts the rows; with transactions they are
/// rejected. Confirming makes the categories the file brings and the transactions, and a currency
/// switch drops the budgets. Records every call.
class FakeImportServer implements ImportRepository {
  FakeImportServer(
    this.home,
    this.budgets, {
    this.hasTransactions = false,
    this.oldExport = false,
    this.fileStats,
  });

  final ImportHome home;
  final FakeBudgetsRepository budgets;
  final bool hasTransactions;
  final bool oldExport;

  /// Replaces the stats a preview carries (a large file, a file with many bad rows).
  final Map<String, Object?>? fileStats;

  /// `POST /v1/imports`, `DELETE /v1/imports/preview-1`, `POST /v1/imports/preview-1/confirm {...}`.
  final calls = <String>[];

  /// The bytes of every upload, as sent.
  final uploads = <Uint8List>[];

  /// What the next call of that name throws (then cleared): `upload`, `discard`, `confirm`.
  final failures = <String, Object>{};

  /// While set, a confirm waits for it.
  Completer<void>? holdConfirm;

  /// The months the averages cover: the last 3 complete ones, or an old export's own last 3.
  Map<String, Object?> get _window => oldExport
      ? const {'from': '2025-01', 'to': '2025-03', 'months': 3}
      : const {'from': '2026-07', 'to': '2026-09', 'months': 3};

  var _uploads = 0;
  var confirmed = false;

  @override
  Future<FileImport> upload(String fileName, Uint8List bytes) async {
    calls.add('POST /v1/imports');
    uploads.add(bytes);
    final failure = failures.remove('upload');
    if (failure != null) throw failure;
    _uploads += 1;
    final empty = !confirmed && !hasTransactions;
    final adopts = home.live != 'EUR' && empty;
    final window = _window;
    final Map<String, Object?> stats;
    if (fileStats != null) {
      stats = fileStats!;
    } else if (home.live == 'EUR' || adopts) {
      stats = {
        ...sampleStats(window: window),
        'duplicates': 0,
        'adoptsCurrency': adopts,
        'dropsBudgets': adopts && budgets.budgets.isNotEmpty,
      };
    } else {
      stats = {
        ...sampleStats(),
        'transactions': 0,
        'duplicates': 0,
        'newCategories': <String>[],
        'rejected': [
          {'line': 7, 'reason': 'currency_mismatch'},
        ],
        'from': null,
        'to': null,
        'averageMonthlySpending': <Object>[],
        'averageWindow': null,
      };
    }
    return importOf(stats, id: 'preview-$_uploads');
  }

  @override
  Future<void> discard(String id) async {
    calls.add('DELETE /v1/imports/$id');
    final failure = failures.remove('discard');
    if (failure != null) throw failure;
  }

  @override
  Future<FileImport> confirm(String id, {bool adoptFileCurrency = false}) async {
    calls.add(
      'POST /v1/imports/$id/confirm${adoptFileCurrency ? ' ${jsonEncode({'adoptFileCurrency': true})}' : ''}',
    );
    await holdConfirm?.future;
    final failure = failures.remove('confirm');
    if (failure != null) throw failure;
    if (home.live != 'EUR') {
      // Like the API: a mismatch goes in only by adopting the file's currency, atomically, which
      // drops the budgets in the old one.
      if (!adoptFileCurrency) throw const HomeFailure(409, code: 'import_currency_changed');
      home.live = 'EUR';
      budgets.budgets.clear();
    }
    confirmed = true;
    // Like the importer: the file's categories that don't exist yet (by name, any case or accent)
    // are made, as the file writes them.
    for (final (name, kind, icon, color) in _imported) {
      if (home.categoryList.any((c) => _plain(c.name) == _plain(name))) continue;
      home.categoryList.add(
        category('cat-${home.categoryList.length}', name, kind: kind, icon: icon, color: color),
      );
    }
    home.items.addAll([
      tx('imp-1', '2026-10-03', -4200, name: 'Café'),
      tx('imp-2', '2026-10-04', -8800, name: 'Cine'),
    ]);
    budgets.publish();
    return importOf(
      {...sampleStats(window: _window), 'duplicates': 0, 'inserted': 22},
      id: id,
      status: 'confirmed',
    );
  }
}

/// The phone's document picker: gives the file it was told to, and records what it was asked.
class FakeFilesChannel implements FilesChannel {
  /// What the person picks next; null: they close the picker.
  PickedFile? next;

  /// What the next pick throws instead (then cleared).
  Object? failure;

  /// While set, the pick waits for it.
  Completer<void>? hold;

  final asked = <({List<String> mimeTypes, int maxBytes})>[];
  final saved = <(String, Uint8List, String)>[];
  final shared = <(String, Uint8List, String)>[];

  @override
  Future<PickedFile?> pickFile({
    required List<String> mimeTypes,
    int maxBytes = FilesChannel.defaultMaxBytes,
  }) async {
    asked.add((mimeTypes: mimeTypes, maxBytes: maxBytes));
    await hold?.future;
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
    final file = next;
    // A file bigger than the limit is never read: the channel refuses it, as the Kotlin side does.
    if (file != null && file.bytes.length > maxBytes) {
      throw const FilesFailure(FilesFailureKind.tooLarge);
    }
    return file;
  }

  @override
  Future<bool> saveFile(String name, Uint8List bytes, String mime) async {
    saved.add((name, bytes, mime));
    return true;
  }

  @override
  Future<bool> shareFile(String name, Uint8List bytes, String mime) async {
    shared.add((name, bytes, mime));
    return true;
  }
}

/// A Budge file of [rows] rows, as CSV bytes.
Uint8List budgeCsv({int rows = 2, String name = 'budge'}) {
  final out = StringBuffer('Date,Payment,Category,Amount,Currency\n');
  for (var i = 0; i < rows; i++) {
    final day = (i % 28 + 1).toString().padLeft(2, '0');
    out.writeln('2026-09-$day,Shop $i,Supermercado,-${(i % 90) + 1}.50,EUR');
  }
  return Uint8List.fromList(utf8.encode(out.toString()));
}

/// The notice/home/budget servers an import test needs, built together.
({ImportHome home, FakeBudgetsRepository budgets, FakeImportServer server}) importWorld({
  String currency = 'EUR',
  bool budgeted = false,
  bool hasTransactions = false,
  bool oldExport = false,
  Map<String, Object?>? fileStats,
}) {
  final home = ImportHome(currency: currency);
  final budgets = FakeBudgetsRepository(home, budgets: budgeted ? {'cat-groceries': 30000000} : {});
  final server = FakeImportServer(
    home,
    budgets,
    hasTransactions: hasTransactions,
    oldExport: oldExport,
    fileStats: fileStats,
  );
  return (home: home, budgets: budgets, server: server);
}
