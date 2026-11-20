import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Local Backend Server D-Care (Port 8787)
/// Mengatasi kendala CORS, SSL/TLS (.go.id Kemenkes via HttpClient + curl fallback),
/// serta CloudFront/Hotlink (Halodoc, Alodokter, HelloSehat, dll.) saat aplikasi dijalankan di Flutter Web.
void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8787, shared: true);
  stdout.writeln('✅ D-Care Article Scraper Backend berjalan di http://localhost:8787');

  // Jalankan sinkronisasi otomatis gambar artikel ke Firestore di background setiap 4 detik
  Timer.periodic(const Duration(seconds: 4), (_) => _syncMissingFirestoreArticleImages());
  _syncMissingFirestoreArticleImages();

  await for (final HttpRequest request in server) {
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;
    if (path == '/api/scrape') {
      await _handleScrape(request);
    } else if (path == '/api/image') {
      await _handleImageProxy(request);
    } else if (path == '/health') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'status': 'ok'}));
      await request.response.close();
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }
}

Future<void> _handleScrape(HttpRequest request) async {
  final rawUrl = request.uri.queryParameters['url']?.trim() ?? '';
  if (rawUrl.isEmpty) {
    request.response.statusCode = HttpStatus.badRequest;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'error': 'URL kosong'}));
    await request.response.close();
    return;
  }

  final targetUrl = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
  try {
    final html = await _fetchHtmlWithBrowserHeaders(targetUrl);
    if (html == null || html.trim().isEmpty) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': 'Gagal mengambil halaman artikel'}));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
    request.response.write(html);
    await request.response.close();
  } catch (e) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleImageProxy(HttpRequest request) async {
  final rawUrl = request.uri.queryParameters['url']?.trim() ?? '';
  if (rawUrl.isEmpty) {
    request.response.statusCode = HttpStatus.badRequest;
    await request.response.close();
    return;
  }

  final bytes = await _fetchImageBytes(rawUrl);
  if (bytes != null && bytes.isNotEmpty) {
    final lower = rawUrl.toLowerCase();
    if (lower.contains('.png')) {
      request.response.headers.contentType = ContentType('image', 'png');
    } else if (lower.contains('.webp')) {
      request.response.headers.contentType = ContentType('image', 'webp');
    } else {
      request.response.headers.contentType = ContentType('image', 'jpeg');
    }
    request.response.headers.set('Cache-Control', 'public, max-age=86400');
    request.response.add(bytes);
    await request.response.close();
  } else {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}

Future<String?> _fetchHtmlWithBrowserHeaders(String url) async {
  // 1. Utamakan curl native OS pada Desktop (mendukung TLS Schannel untuk server .kemkes.go.id, CloudFront Halodoc, Alodokter, dll. tanpa hang)
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

  // 2. Fallback melalui HttpClient
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

  return null;
}

Future<List<int>?> _fetchImageBytes(String url) async {
  // 1. Utamakan curl binary pada Desktop untuk mengambil bytes gambar (bebas masalah SSL .go.id & hotlink)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      final uri = Uri.parse(url);
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
          '-e',
          '${uri.scheme}://${uri.host}/',
          url,
        ],
        stdoutEncoding: null,
      );
      if (result.exitCode == 0 && result.stdout is List<int>) {
        final bytes = result.stdout as List<int>;
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (_) {}
  }

  // 2. Fallback HttpClient
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
    req.headers.set(HttpHeaders.acceptHeader, 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8');
    req.headers.set(HttpHeaders.refererHeader, '${uri.scheme}://${uri.host}/');

    final resp = await req.close().timeout(const Duration(seconds: 6));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final bytes = await resp.fold<List<int>>(<int>[], (prev, el) => prev..addAll(el));
      if (bytes.isNotEmpty) return bytes;
    }
  } catch (_) {
  } finally {
    client.close();
  }

  return null;
}

bool _isSyncingFirestore = false;
String? _cachedIdToken;
DateTime? _tokenExpiry;

Future<void> _syncMissingFirestoreArticleImages() async {
  if (_isSyncingFirestore) return;
  _isSyncingFirestore = true;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final listUri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/d-care-78c58/databases/(default)/documents/admin_articles',
    );
    final req = await client.getUrl(listUri);
    final resp = await req.close().timeout(const Duration(seconds: 6));
    if (resp.statusCode != 200) return;

    final bodyStr = await resp.transform(utf8.decoder).join();
    final jsonMap = jsonDecode(bodyStr) as Map<String, dynamic>;
    final docs = (jsonMap['documents'] as List<dynamic>?) ?? [];

    for (final docObj in docs) {
      if (docObj is! Map<String, dynamic>) continue;
      final docName = docObj['name']?.toString() ?? '';
      final fields = (docObj['fields'] as Map<String, dynamic>?) ?? {};
      final imgVal = (fields['imageUrl']?['stringValue']?.toString() ?? '').trim();
      final srcUrl = (fields['sourceUrl']?['stringValue']?.toString() ?? '').trim();

      if ((imgVal.isEmpty || imgVal.startsWith('assets/')) && srcUrl.startsWith('http')) {
        final html = await _fetchHtmlWithBrowserHeaders(srcUrl);
        if (html != null && html.isNotEmpty) {
          final extractedImg = _extractBestImageFromHtml(html, srcUrl);
          if (extractedImg.isNotEmpty) {
            final safeImg =
                'https://wsrv.nl/?url=${Uri.encodeComponent(extractedImg)}&w=800&output=jpg';
            await _patchFirestoreImageUrl(client, docName, safeImg);
            stdout.writeln('🔄 Auto-synced image for $docName -> $extractedImg');
          }
        }
      }
    }
  } catch (_) {
  } finally {
    client.close();
    _isSyncingFirestore = false;
  }
}

String _extractBestImageFromHtml(String html, String pageUrl) {
  // 1. Cek og:image / twitter:image
  for (final key in ['og:image', 'og:image:secure_url', 'twitter:image']) {
    final m1 = RegExp(
      '<meta\\s+[^>]*?(?:property|name)=["\']$key["\'][^>]*?content=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(html);
    final m2 = RegExp(
      '<meta\\s+[^>]*?content=["\']([^"\']+)["\'][^>]*?(?:property|name)=["\']$key["\']',
      caseSensitive: false,
    ).firstMatch(html);
    final raw = (m1?.group(1) ?? m2?.group(1) ?? '').trim();
    if (raw.isNotEmpty && !_isRejectedImg(raw)) {
      return _resolveImgUrl(pageUrl, raw);
    }
  }

  // 2. Cek gambar utama di dalam <article> atau <main>
  String scope = html.replaceAll(
    RegExp(r'<(script|style|nav|header|footer|aside)[^>]*>.*?</\1>',
        caseSensitive: false, dotAll: true),
    '',
  );
  final artM =
      RegExp(r'<article[^>]*>(.*?)</article>', caseSensitive: false, dotAll: true).firstMatch(scope);
  if (artM != null) {
    scope = artM.group(1) ?? scope;
  }

  final imgs = RegExp(r'<img\s+[^>]*?>', caseSensitive: false, dotAll: true).allMatches(scope);
  for (final m in imgs) {
    final tag = m.group(0) ?? '';
    for (final attr in ['data-src', 'data-lazy-src', 'data-original', 'src']) {
      final am = RegExp('$attr=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(tag);
      if (am != null) {
        final candidate = _resolveImgUrl(pageUrl, (am.group(1) ?? '').trim());
        if (!_isRejectedImg(candidate)) {
          return candidate;
        }
      }
    }
  }
  return '';
}

bool _isRejectedImg(String url) {
  final l = url.toLowerCase().trim();
  if (l.isEmpty || l.startsWith('data:') || l.endsWith('.svg') || l.endsWith('.ico')) return true;
  for (final p in [
    'placeholder',
    '/logoweb/',
    '/images/logo/',
    'logokemkes',
    'logo_kemkes',
    'logo_upk',
    'hastag',
    '/icon_menu/',
    '/icons/512x512',
    'favicon',
    'vectors/404',
    'facebook.com/tr',
  ]) {
    if (l.contains(p)) return true;
  }
  return false;
}

String _resolveImgUrl(String baseUrl, String rel) {
  if (rel.startsWith('http://') || rel.startsWith('https://')) return rel;
  try {
    return Uri.parse(baseUrl).resolve(rel).toString();
  } catch (_) {
    return rel;
  }
}

Future<void> _patchFirestoreImageUrl(HttpClient client, String docName, String imageUrl) async {
  try {
    if (_cachedIdToken == null ||
        _tokenExpiry == null ||
        DateTime.now().isAfter(_tokenExpiry!)) {
      final authReq = await client.postUrl(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyBXB_QIdYBLS2FAdtfGRbmV6m1-10uyvgc',
        ),
      );
      authReq.headers.contentType = ContentType.json;
      authReq.write(jsonEncode({
        'email': 'admin@dcare.id',
        'password': 'AdminDcare2026!',
        'returnSecureToken': true,
      }));
      final authResp = await authReq.close();
      if (authResp.statusCode == 200) {
        final authData = jsonDecode(await authResp.transform(utf8.decoder).join());
        _cachedIdToken = authData['idToken']?.toString();
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 45));
      }
    }
    if (_cachedIdToken == null) return;

    final patchUri = Uri.parse(
      'https://firestore.googleapis.com/v1/$docName?updateMask.fieldPaths=imageUrl',
    );
    final patchReq = await client.patchUrl(patchUri);
    patchReq.headers.set('Authorization', 'Bearer $_cachedIdToken');
    patchReq.headers.contentType = ContentType.json;
    patchReq.write(jsonEncode({
      'fields': {
        'imageUrl': {'stringValue': imageUrl},
      },
    }));
    await patchReq.close();
  } catch (_) {}
}
