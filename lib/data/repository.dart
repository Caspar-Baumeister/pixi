import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/pix_map.dart';

/// JSON file persistence. The data set is tiny (a few maps × 365 days),
/// so a single file is simpler and safer than a database for v1.
class Repository {
  Repository._(this._file);

  final File _file;

  static Future<Repository> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pixi_data.json');
    return Repository._(file);
  }

  Future<AppData> load() async {
    try {
      if (!await _file.exists()) return AppData.empty();
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) return AppData.empty();
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt file: keep a backup and start fresh rather than crash.
      try {
        await _file.copy('${_file.path}.broken');
      } catch (_) {}
      return AppData.empty();
    }
  }

  Future<void> save(AppData data) async {
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(_file.path);
  }

  Future<String> exportJson(AppData data) async =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());
}
