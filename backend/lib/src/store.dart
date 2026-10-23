import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'config.dart';

/// Tiny file-backed store: `config.json` (admin settings + secrets) and
/// `interactions.jsonl` (append-only log used for stats and fine-tune export).
/// Pass a null [dir] for a purely in-memory store (tests).
class Store {
  Store(this.dir) {
    final d = dir;
    if (d != null) {
      d.createSync(recursive: true);
      // keys, memories and chat logs live here: owner-only access
      if (!Platform.isWindows) Process.runSync('chmod', ['700', d.path]);
    }
    config = _loadConfig();
    tokenSecret = _loadSecret();
  }

  final Directory? dir;
  late ServerConfig config;
  late String tokenSecret;
  final List<Map<String, dynamic>> _memoryLog = [];
  int totalRequests = 0;
  int totalErrors = 0;
  final Set<String> activeDevices = {};

  File? get _configFile => dir == null ? null : File('${dir!.path}/config.json');
  File? get _logFile => dir == null ? null : File('${dir!.path}/interactions.jsonl');

  ServerConfig _loadConfig() {
    final f = _configFile;
    if (f != null && f.existsSync()) {
      try {
        return ServerConfig.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt file: keep a copy and start from defaults.
        f.copySync('${f.path}.corrupt');
      }
    }
    return ServerConfig.defaults();
  }

  String _loadSecret() {
    final env = Platform.environment['TOKEN_SECRET'];
    if (env != null && env.isNotEmpty) return env;
    final d = dir;
    if (d == null) return _randomHex(32);
    final f = File('${d.path}/token_secret');
    if (f.existsSync()) return f.readAsStringSync().trim();
    d.createSync(recursive: true);
    final s = _randomHex(32);
    f.writeAsStringSync(s);
    if (!Platform.isWindows) Process.runSync('chmod', ['600', f.path]);
    return s;
  }

  void saveConfig() {
    final f = _configFile;
    if (f == null) return;
    f.parent.createSync(recursive: true);
    final tmp = File('${f.path}.tmp')..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(config.toJson()));
    tmp.renameSync(f.path);
    // the file holds provider API keys: owner-only access
    if (!Platform.isWindows) Process.runSync('chmod', ['600', f.path]);
  }

  /// Appends one AI interaction (used for stats + JSONL fine-tune export).
  void logInteraction(Map<String, dynamic> entry) {
    final e = {'ts': DateTime.now().toUtc().toIso8601String(), ...entry};
    final f = _logFile;
    if (f == null) {
      _memoryLog.add(e);
      return;
    }
    f.parent.createSync(recursive: true);
    f.writeAsStringSync('${jsonEncode(e)}\n', mode: FileMode.append);
  }

  List<Map<String, dynamic>> readLog() {
    final f = _logFile;
    if (f == null) return List.of(_memoryLog);
    if (!f.existsSync()) return [];
    return [
      for (final line in f.readAsLinesSync())
        if (line.trim().isNotEmpty) jsonDecode(line) as Map<String, dynamic>
    ];
  }

  /// Reads a JSON document under the data dir (`name` may contain one sub-folder).
  Map<String, dynamic>? readDoc(String name) {
    final d = dir;
    if (d == null) return _memDocs[name];
    final f = File('${d.path}/$name');
    if (!f.existsSync()) return null;
    try {
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void writeDoc(String name, Map<String, dynamic> doc) {
    final d = dir;
    if (d == null) {
      _memDocs[name] = doc;
      return;
    }
    final f = File('${d.path}/$name');
    f.parent.createSync(recursive: true);
    final tmp = File('${f.path}.tmp')..writeAsStringSync(jsonEncode(doc));
    tmp.renameSync(f.path);
  }

  void deleteDoc(String name) {
    final d = dir;
    if (d == null) {
      _memDocs.remove(name);
      return;
    }
    final f = File('${d.path}/$name');
    if (f.existsSync()) f.deleteSync();
  }

  /// Binary blobs (generated images). Returns null in memory-only mode.
  File? blobFile(String name) => dir == null ? null : File('${dir!.path}/$name');

  final Map<String, Map<String, dynamic>> _memDocs = {};

  /// Removes every log entry of one (hashed) device — "delete my data".
  int forgetDevice(String deviceHash) {
    final kept = readLog().where((e) => e['device'] != deviceHash).toList();
    final removed = readLog().length - kept.length;
    final f = _logFile;
    if (f == null) {
      _memoryLog
        ..clear()
        ..addAll(kept);
    } else if (f.existsSync()) {
      final tmp = File('${f.path}.tmp')..writeAsStringSync(kept.map((e) => '${jsonEncode(e)}\n').join());
      tmp.renameSync(f.path);
    }
    return removed;
  }

  static String _randomHex(int bytes) {
    final r = Random.secure();
    return List.generate(bytes, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
