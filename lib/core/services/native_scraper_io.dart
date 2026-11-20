import 'dart:convert';
import 'dart:io';

/// Fetch HTML langsung menggunakan dart:io HttpClient (+ fallback curl di Desktop)
/// dengan toleransi sertifikat SSL (.go.id Kemenkes) dan header browser Chrome lengkap.
Future<String?> fetchRawHtmlDirectNative(String url) async {
  final client = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true)
    ..connectionTimeout = const Duration(seconds: 5);

  try {
    final uri = Uri.parse(url);
    final req = await client.getUrl(uri).timeout(const Duration(seconds: 5));
    req.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    );
    req.headers.set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    );
    req.headers.set(HttpHeaders.acceptLanguageHeader, 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7');

    final resp = await req.close().timeout(const Duration(seconds: 6));
    if (resp.statusCode >= 200 && resp.statusCode < 400) {
      final bytes = await resp.fold<List<int>>(<int>[], (prev, el) => prev..addAll(el));
      final html = utf8.decode(bytes, allowMalformed: true);
      if (html.trim().isNotEmpty) return html;
    }
  } catch (_) {
  } finally {
    client.close();
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      final curlBin = Platform.isWindows ? 'curl.exe' : 'curl';
      final result = await Process.run(
        curlBin,
        [
          '-4',
          '-s',
          '-L',
          '-k',
          '--connect-timeout',
          '5',
          '--max-time',
          '10',
          '-A',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          url,
        ],
        stdoutEncoding: null,
      );
      if (result.exitCode == 0 && result.stdout is List<int>) {
        final out = utf8.decode(result.stdout as List<int>, allowMalformed: true);
        if (out.trim().isNotEmpty) return out;
      }
    } catch (_) {}
  }

  return null;
}
