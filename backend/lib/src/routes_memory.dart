part of 'server.dart';

extension MemoryRoutes on VokabelinaServer {
  /// The app sends its memory; the server merges it, consolidates if new chat
  /// turns are waiting (bounded wait), and returns the consolidated view.
  Future<Response> _memorySync(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final hash = VokabelinaServer.deviceHash(deviceId);
    memory.mergeClient(hash, Map<String, dynamic>.from((b['memory'] as Map?) ?? {}));
    if (ai.hasAnyProvider) {
      try {
        await memory.consolidate(hash, target: c.target, native: c.native, level: c.level).timeout(const Duration(seconds: 25));
      } catch (_) {
        // consolidation is best effort; the merged memory is still returned
      }
    }
    return jsonResponse(memory.publicView(hash));
  }

  /// "Delete my data": memory document and every log line of this device.
  Future<Response> _memoryDelete(Request req, String deviceId) async {
    final hash = VokabelinaServer.deviceHash(deviceId);
    memory.delete(hash);
    final removed = store.forgetDevice(hash);
    return jsonResponse({'ok': true, 'removedLogEntries': removed});
  }
}
