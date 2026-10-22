import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as io;
import 'package:vokabelina_server/src/server.dart';
import 'package:vokabelina_server/src/store.dart';

Future<void> main() async {
  final env = Platform.environment;
  final store = Store(Directory(env['DATA_DIR'] ?? 'data'));
  final server = VokabelinaServer(
    store: store,
    httpClient: http.Client(),
    adminToken: env['ADMIN_TOKEN'] ?? '',
    adminWebDir: env['ADMIN_WEB_DIR'] ?? 'web',
  );
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final srv = await io.serve(server.handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Vokabelina server on :${srv.port} '
      '(admin ${server.adminToken.isEmpty ? "DISABLED - set ADMIN_TOKEN" : "enabled at /admin"})');
}
