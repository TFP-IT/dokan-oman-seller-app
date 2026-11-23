import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Logs every request/response made through package:http.
/// Installed globally in main.dart via http.runWithClient (debug builds only).
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner);

  final http.Client _inner;
  static const _tag = '[HTTP]';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final sw = Stopwatch()..start();
    _logRequest(request);

    try {
      final response = await _inner.send(request);
      final bytes = await response.stream.toBytes();
      sw.stop();
      _logResponse(request, response, bytes, sw.elapsedMilliseconds);

      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      sw.stop();
      _print('$_tag ✖ ${request.method} ${request.url} '
          '(${sw.elapsedMilliseconds}ms)\n$_tag error: $e');
      rethrow;
    }
  }

  void _logRequest(http.BaseRequest request) {
    final b = StringBuffer()
      ..writeln('$_tag ➜ ${request.method} ${request.url}')
      ..writeln('$_tag headers: ${request.headers}');
    if (request is http.Request && request.body.isNotEmpty) {
      b.writeln('$_tag body: ${request.body}');
    } else if (request is http.MultipartRequest) {
      b.writeln('$_tag fields: ${request.fields}');
      b.writeln('$_tag files: ${request.files.map((f) => '${f.field}=${f.filename} (${f.length}B)').toList()}');
    }
    _print(b.toString());
  }

  void _logResponse(http.BaseRequest request, http.StreamedResponse response,
      List<int> bytes, int ms) {
    final body = utf8.decode(bytes, allowMalformed: true);
    _print('$_tag ⬅ ${response.statusCode} ${request.method} ${request.url} '
        '(${ms}ms)\n$_tag response: $body');
  }

  /// Logcat truncates long lines (~1000 chars), so print in chunks.
  void _print(String msg) {
    const chunk = 800;
    for (var i = 0; i < msg.length; i += chunk) {
      debugPrint(msg.substring(i, i + chunk > msg.length ? msg.length : i + chunk));
    }
  }

  @override
  void close() => _inner.close();
}
