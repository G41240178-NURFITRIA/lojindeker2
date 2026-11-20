import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'native_scraper_stub.dart' if (dart.library.io) 'native_scraper_io.dart';

/// Model metadata hasil scraping otomatis dari URL website artikel
class ArticleScrapedMetadata {
  final String title;
  final String summary;
  final String imageUrl;
  final String sourceName;
  final String author;
  final String publishedDate;
  final String content;
  final String readTime;
  final String originalUrl;

  const ArticleScrapedMetadata({
    this.title = '',
    this.summary = '',
    this.imageUrl = '',
    this.sourceName = '',
    this.author = '',
    this.publishedDate = '',
    this.content = '',
    this.readTime = '3 menit baca',
    this.originalUrl = '',
  });
}

/// Model artikel yang dibuat admin dan disimpan di Firestore
class AdminArticleModel {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String content;
  final String readTime;
  final String reviewer;
  final String sourceUrl;
  final String imageUrl;
  final String sourceName;
  final String author;
  final String publishedDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdminArticleModel({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.readTime,
    required this.reviewer,
    this.sourceUrl = '',
    this.imageUrl = '',
    this.sourceName = '',
    this.author = '',
    this.publishedDate = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final rawImg = (data['imageUrl'] as String?)?.trim() ?? '';
    final cleanImg = rawImg.startsWith('assets/') ? '' : rawImg;
    return AdminArticleModel(
      id: doc.id,
      category: data['category'] ?? 'Umum',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      content: data['content'] ?? '',
      readTime: data['readTime'] ?? '3 menit baca',
      reviewer: data['reviewer'] ?? 'Tim Medis LojinDeker',
      sourceUrl: data['sourceUrl'] ?? '',
      imageUrl: cleanImg,
      sourceName: data['sourceName'] ?? '',
      author: data['author'] ?? '',
      publishedDate: data['publishedDate'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final cleanImg = imageUrl.trim().startsWith('assets/') ? '' : imageUrl.trim();
    return {
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'readTime': readTime,
      'reviewer': reviewer,
      'sourceUrl': sourceUrl,
      'imageUrl': cleanImg,
      'sourceName': sourceName,
      'author': author,
      'publishedDate': publishedDate,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  AdminArticleModel copyWith({
    String? id,
    String? category,
    String? title,
    String? subtitle,
    String? content,
    String? readTime,
    String? reviewer,
    String? sourceUrl,
    String? imageUrl,
    String? sourceName,
    String? author,
    String? publishedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminArticleModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      content: content ?? this.content,
      readTime: readTime ?? this.readTime,
      reviewer: reviewer ?? this.reviewer,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceName: sourceName ?? this.sourceName,
      author: author ?? this.author,
      publishedDate: publishedDate ?? this.publishedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service untuk CRUD artikel admin ke Firestore & Ekstraksi Artikel Akurat dari Halaman Sumber
class ArticleService {
  static final ArticleService instance = ArticleService._();
  ArticleService._();

  static const String localBackendBase = 'http://localhost:8787';

  final _col = FirebaseFirestore.instance.collection('admin_articles');
  final Set<String> _autoHealingIds = <String>{};

  /// Stream real-time semua artikel admin, diurutkan terbaru
  Stream<List<AdminArticleModel>> streamArticles() {
    return _col.snapshots().map((snap) {
      final validDocs = snap.docs.where((doc) {
        if (doc.id.startsWith('_deleted_builtin_')) return false;
        final data = doc.data();
        if (data['isDeletedBuiltin'] == true) return false;
        return true;
      });
      final list = validDocs.map(AdminArticleModel.fromFirestore).toList();
      for (final art in list) {
        if (art.imageUrl.trim().isEmpty && art.sourceUrl.trim().isNotEmpty) {
          _autoHealMissingArticleImage(art);
        }
      }
      list.sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt;
        final dateB = b.updatedAt ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Stream daftar ID artikel bawaan (art-1, art-2, art-3) yang telah dihapus oleh Admin
  Stream<Set<String>> streamDeletedBuiltinIds() {
    return _col.snapshots().map((snap) {
      final deleted = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        if (doc.id.startsWith('_deleted_builtin_')) {
          final id = (data['builtinId'] as String?)?.trim() ??
              doc.id.replaceFirst('_deleted_builtin_', '');
          if (id.isNotEmpty) deleted.add(id);
        } else if (data['isDeletedBuiltin'] == true) {
          final id = (data['builtinId'] as String?)?.trim() ?? '';
          if (id.isNotEmpty) deleted.add(id);
        }
      }
      return deleted;
    });
  }

  /// Hapus artikel bawaan secara permanen (tersinkronisasi real-time ke Admin & Pasien)
  Future<void> deleteBuiltinArticle(String builtinId) async {
    await _col.doc('_deleted_builtin_$builtinId').set({
      'isDeletedBuiltin': true,
      'builtinId': builtinId,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream real-time satu artikel spesifik berdasarkan ID
  Stream<AdminArticleModel?> streamArticle(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final art = AdminArticleModel.fromFirestore(doc);
      if (art.imageUrl.trim().isEmpty && art.sourceUrl.trim().isNotEmpty) {
        _autoHealMissingArticleImage(art);
      }
      return art;
    });
  }

  Future<void> _autoHealMissingArticleImage(AdminArticleModel article) async {
    if (article.id.isEmpty || _autoHealingIds.contains(article.id)) return;
    final targetUrl = article.sourceUrl.trim();
    if (targetUrl.isEmpty) return;
    _autoHealingIds.add(article.id);

    try {
      final meta = await fetchMetadataFromUrl(targetUrl);
      if (meta != null && meta.imageUrl.trim().isNotEmpty) {
        final updates = <String, dynamic>{
          'imageUrl': meta.imageUrl.trim(),
        };
        if (_isWebsiteOrGenericName(article.title) && meta.title.isNotEmpty) {
          updates['title'] = meta.title;
        }
        if (article.author.trim().isEmpty && meta.author.isNotEmpty) {
          updates['author'] = meta.author;
        }
        if (article.publishedDate.trim().isEmpty && meta.publishedDate.isNotEmpty) {
          updates['publishedDate'] = meta.publishedDate;
        }
        await _col.doc(article.id).update(updates);
      }
    } catch (e) {
      debugPrint('⚠️ [ArticleService] Auto-heal image error: $e');
    }
  }

  /// Tambah artikel baru ke Firestore
  Future<void> addArticle(AdminArticleModel article) async {
    await _col.add(article.toFirestore());
  }

  /// Update / Edit artikel di Firestore secara real-time
  Future<void> updateArticle(AdminArticleModel article) async {
    final cleanImg = article.imageUrl.trim().startsWith('assets/') ? '' : article.imageUrl.trim();
    await _col.doc(article.id).update({
      'category': article.category,
      'title': article.title,
      'subtitle': article.subtitle,
      'content': article.content,
      'readTime': article.readTime,
      'reviewer': article.reviewer,
      'sourceUrl': article.sourceUrl,
      'imageUrl': cleanImg,
      'sourceName': article.sourceName,
      'author': article.author,
      'publishedDate': article.publishedDate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus artikel dari Firestore berdasarkan ID
  Future<void> deleteArticle(String id) async {
    await _col.doc(id).delete();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Ekstraksi Artikel Akurat dari Halaman Sumber (H1, Ringkasan, Gambar, Penulis, Tanggal)
  // ───────────────────────────────────────────────────────────────────────────

  /// Mengambil informasi asli artikel dari URL website sumber:
  /// - Judul dari elemen H1 utama artikel (bukan nama website).
  /// - Ringkasan dari deskripsi artikel atau paragraf pembuka.
  /// - Gambar utama dari og:image atau elemen gambar utama dalam konten artikel (diverifikasi aksesnya).
  /// - Nama penulis, tanggal publikasi, dan nama sumber jika tersedia.
  /// - Tidak mengisi data dengan nama website atau konten default jika pengambilan gagal.
  Future<ArticleScrapedMetadata?> fetchMetadataFromUrl(String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Jalankan ekstraksi paralel dari:
    // 1. Primary HTML Backend (Jina Cloud Headless HTML DOM / Native HTTP / Local Backend)
    // 2. Jina JSON Reader dengan X-With-Images-Summary
    // 3. Microlink Open Graph Backend
    final results = await Future.wait([
      _fetchFromPrimaryHtmlBackend(url),
      _fetchFromJinaBackend(url),
      _fetchFromMicrolinkBackend(url),
    ]);

    final htmlParsed = results[0];
    final jina = results[1];
    final microlink = results[2];

    // 1. Judul Artikel: Utamakan H1 utama artikel dari HTML, tolak nama website/instansi
    String title = _firstValidArticleTitle([
      htmlParsed?.title,
      jina?.title,
      microlink?.title,
    ]);

    // 2. Isi Konten Artikel Lengkap
    final contentCandidates = [
      htmlParsed?.content ?? '',
      jina?.content ?? '',
      microlink?.content ?? '',
    ].where((c) => !_isErrorOrBlockedText(c)).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final String content =
        contentCandidates.firstWhere((c) => c.trim().isNotEmpty, orElse: () => '');

    // 3. Ringkasan Artikel: Ambil dari deskripsi artikel atau paragraf pembuka artikel
    String summary = _firstValidSummary([
      htmlParsed?.summary,
      jina?.summary,
      microlink?.summary,
    ]);

    if (summary.isEmpty && content.isNotEmpty) {
      final firstPara = _extractOpeningParagraph(content);
      if (firstPara.isNotEmpty) {
        summary = firstPara;
      }
    }

    // 4. Nama Penulis & Tanggal Publikasi
    final String author = _firstNonEmpty([
      htmlParsed?.author,
      jina?.author,
      microlink?.author,
    ]);

    final String publishedDate = _firstNonEmpty([
      htmlParsed?.publishedDate,
      jina?.publishedDate,
      microlink?.publishedDate,
    ]);

    // 5. Nama Sumber Website (hanya diisi jika pengambilan artikel berhasil)
    final bool hasAnyArticleData =
        title.isNotEmpty || summary.isNotEmpty || content.isNotEmpty;
    final String sourceName = hasAnyArticleData
        ? _firstNonEmpty([
            htmlParsed?.sourceName,
            microlink?.sourceName,
            jina?.sourceName,
            _extractDomainName(url),
          ])
        : '';

    // 6. Gambar Utama Artikel (og:image atau gambar utama dalam konten artikel)
    final candidateImages = <String>[
      if (htmlParsed != null && htmlParsed.imageUrl.isNotEmpty) htmlParsed.imageUrl,
      if (jina != null && jina.imageUrl.isNotEmpty) jina.imageUrl,
      if (microlink != null && microlink.imageUrl.isNotEmpty) microlink.imageUrl,
    ];

    String verifiedImageUrl = '';
    for (final candidate in candidateImages) {
      final trimmed = candidate.trim();
      if (_isValidArticleImageUrl(trimmed)) {
        final isAccessible = await _verifyImageAccessible(trimmed);
        if (isAccessible) {
          verifiedImageUrl = trimmed;
          break;
        }
      }
    }

    // Jika semua data gagal diambil, kembalikan null (jangan isi nama website atau konten default)
    if (title.isEmpty && summary.isEmpty && content.isEmpty && verifiedImageUrl.isEmpty) {
      return null;
    }

    final readTime = content.isNotEmpty ? _calculateReadTime(content) : '3 menit baca';

    return ArticleScrapedMetadata(
      title: title,
      summary: summary,
      imageUrl: verifiedImageUrl,
      sourceName: sourceName,
      author: author,
      publishedDate: publishedDate,
      content: content,
      readTime: readTime,
      originalUrl: url,
    );
  }

  /// Verifikasi bahwa URL gambar benar-benar dapat diakses (HTTP 200)
  Future<bool> _verifyImageAccessible(String rawImageUrl) async {
    final trimmed = rawImageUrl.trim();
    if (!_isValidArticleImageUrl(trimmed)) return false;

    // Pada Web (dan fallback umum), verifikasi melalui wsrv.nl yang mendukung CORS penuh
    final checkUrls = <String>[
      'https://wsrv.nl/?url=${Uri.encodeComponent(trimmed)}&w=400&output=jpg',
      if (!kIsWeb) trimmed,
    ];

    for (final testUrl in checkUrls) {
      try {
        final resp = await http
            .head(Uri.parse(testUrl))
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode >= 200 && resp.statusCode < 400) {
          return true;
        }
        final getResp = await http
            .get(Uri.parse(testUrl))
            .timeout(const Duration(seconds: 6));
        if (getResp.statusCode >= 200 &&
            getResp.statusCode < 300 &&
            getResp.bodyBytes.length > 500) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Backend 1: Mengambil DOM HTML lengkap dari halaman sumber
  /// - Pada Native (!kIsWeb): Direct HTTP / curl IPv4 dengan toleransi SSL (.go.id Kemenkes)
  /// - Pada Flutter Web (kIsWeb): Jina Cloud Headless HTML (`X-Return-Format: html`) yang mendukung CORS penuh
  Future<ArticleScrapedMetadata?> _fetchFromPrimaryHtmlBackend(String url) async {
    if (!kIsWeb) {
      final rawHtml = await fetchRawHtmlDirectNative(url);
      if (rawHtml != null && rawHtml.isNotEmpty) {
        final parsed = parseHtmlMetadata(rawHtml, url);
        if (parsed.title.isNotEmpty || parsed.imageUrl.isNotEmpty || parsed.content.isNotEmpty) {
          return parsed;
        }
      }
    }

    // 1. Jina Cloud Headless HTML DOM (100% CORS Allowed: Access-Control-Allow-Headers: x-return-format)
    try {
      final jinaHtmlResp = await http.get(
        Uri.parse('https://r.jina.ai/$url'),
        headers: {'X-Return-Format': 'html'},
      ).timeout(const Duration(seconds: 12));

      if (jinaHtmlResp.statusCode >= 200 &&
          jinaHtmlResp.statusCode < 300 &&
          jinaHtmlResp.body.isNotEmpty) {
        final parsed = parseHtmlMetadata(jinaHtmlResp.body, url);
        if (parsed.title.isNotEmpty || parsed.imageUrl.isNotEmpty || parsed.content.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ArticleService] Jina HTML format error: $e');
    }

    // 2. Fallback Local Backend / Cloud CORS Proxy
    final endpoints = <String>[
      '$localBackendBase/api/scrape?url=${Uri.encodeComponent(url)}',
      'https://corsproxy.io/?${Uri.encodeComponent(url)}',
    ];

    for (final ep in endpoints) {
      try {
        final isLocal = ep.startsWith(localBackendBase);
        final response = await http
            .get(Uri.parse(ep))
            .timeout(Duration(seconds: isLocal ? 2 : 8));

        if (response.statusCode >= 200 && response.statusCode < 300 && response.body.isNotEmpty) {
          final parsed = parseHtmlMetadata(response.body, url);
          if (parsed.title.isNotEmpty || parsed.imageUrl.isNotEmpty || parsed.content.isNotEmpty) {
            return parsed;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Backend 2: Jina Reader JSON API dengan X-With-Images-Summary: true
  Future<ArticleScrapedMetadata?> _fetchFromJinaBackend(String url) async {
    try {
      final endpoint = Uri.parse('https://r.jina.ai/$url');
      final response = await http.get(
        endpoint,
        headers: {
          'Accept': 'application/json',
          'X-With-Images-Summary': 'true',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          final data = decoded['data'] as Map<String, dynamic>;
          final rawTitle = _cleanText(data['title']?.toString() ?? '');
          if (_isErrorOrBlockedText(rawTitle)) return null;

          final rawMarkdown = data['content']?.toString() ?? '';
          if (_isErrorOrBlockedText(rawMarkdown)) return null;

          // Jika data['title'] ternyata adalah nama website (misal: "Direktorat Jenderal Kesehatan Lanjutan"),
          // cari judul artikel asli dari heading markdown atau caption gambar utama artikel
          String articleTitle = _isWebsiteOrGenericName(rawTitle) ? '' : _cleanArticleTitle(rawTitle);

          String mainArticleImage = '';
          if (data['images'] is Map) {
            final imgMap = data['images'] as Map;
            for (final entry in imgMap.entries) {
              final rawKey = entry.key.toString();
              final altText = rawKey.contains(':')
                  ? rawKey.split(':').sublist(1).join(':').trim()
                  : rawKey.trim();
              final altLower = altText.toLowerCase();
              final candidate = _resolveUrl(url, entry.value?.toString().trim() ?? '');

              if (!_isValidArticleImageUrl(candidate)) continue;
              if (altLower.contains('logo') ||
                  altLower.contains('hastag') ||
                  altLower.contains('maskot') ||
                  altLower.contains('icon') ||
                  _isWebsiteOrGenericName(altText)) {
                continue;
              }

              // Gambar utama pertama di dalam konten artikel
              mainArticleImage = candidate;
              if (articleTitle.isEmpty && altText.length >= 10) {
                articleTitle = altText;
              }
              break;
            }
          }

          if (mainArticleImage.isEmpty) {
            mainArticleImage = _extractFirstValidImageFromMarkdown(rawMarkdown, url);
          }

          final cleanContent = _parseJinaMarkdownToCleanArticle(rawMarkdown);
          if (articleTitle.isEmpty) {
            // Cek heading pertama di markdown
            final firstHeading = cleanContent
                .split('\n\n')
                .map((b) => b.trim())
                .firstWhere((b) => b.startsWith('## '), orElse: () => '');
            if (firstHeading.isNotEmpty) {
              final hCandidate = firstHeading.substring(3).trim();
              if (!_isWebsiteOrGenericName(hCandidate)) {
                articleTitle = hCandidate;
              }
            }
          }

          String summary = _cleanText(data['description']?.toString() ?? '');
          if (_isWebsiteOrGenericName(summary) || summary.length < 35) {
            summary = _extractOpeningParagraph(cleanContent);
          }

          final publishedTime = _cleanText(data['publishedTime']?.toString() ?? '');

          return ArticleScrapedMetadata(
            title: articleTitle,
            summary: summary,
            imageUrl: mainArticleImage,
            sourceName: _extractDomainName(url),
            publishedDate: publishedTime,
            content: cleanContent,
            originalUrl: url,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ArticleService] Jina JSON backend error: $e');
    }
    return null;
  }

  /// Backend 3: Microlink Open Graph & Metadata API
  Future<ArticleScrapedMetadata?> _fetchFromMicrolinkBackend(String url) async {
    try {
      final endpoint = Uri.parse('https://api.microlink.io/?url=${Uri.encodeComponent(url)}');
      final response = await http.get(endpoint).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['status'] == 'success' &&
            decoded['data'] is Map<String, dynamic>) {
          final data = decoded['data'] as Map<String, dynamic>;
          final rawTitle = _cleanText(data['title']?.toString() ?? '');
          if (_isErrorOrBlockedText(rawTitle)) return null;

          final cleanTitle =
              _isWebsiteOrGenericName(rawTitle) ? '' : _cleanArticleTitle(rawTitle);
          final description = _cleanText(data['description']?.toString() ?? '');
          final validSummary =
              (_isWebsiteOrGenericName(description) || description.length < 30)
                  ? ''
                  : description;
          final publisher = _cleanText(data['publisher']?.toString() ?? '');
          final author = _cleanText(data['author']?.toString() ?? '');
          final date = _cleanText(data['date']?.toString() ?? '');

          String ogImage = '';
          if (data['image'] is Map<String, dynamic>) {
            ogImage = (data['image']['url']?.toString() ?? '').trim();
          } else if (data['image'] is String) {
            ogImage = (data['image'] as String).trim();
          }
          if (!_isValidArticleImageUrl(ogImage)) {
            ogImage = '';
          }

          return ArticleScrapedMetadata(
            title: cleanTitle,
            summary: validSummary,
            imageUrl: ogImage,
            sourceName: publisher.isNotEmpty ? publisher : _extractDomainName(url),
            author: author,
            publishedDate: date,
            content: validSummary,
            originalUrl: url,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ArticleService] Microlink backend error: $e');
    }
    return null;
  }

  /// Parsing HTML string untuk mengekstrak:
  /// 1. Judul dari elemen H1 utama artikel (bukan nama website).
  /// 2. Gambar utama dari og:image atau elemen gambar utama dalam konten artikel.
  /// 3. Ringkasan dari deskripsi atau paragraf pembuka artikel.
  /// 4. Nama penulis, tanggal publikasi, dan nama sumber.
  ArticleScrapedMetadata parseHtmlMetadata(String html, String pageUrl) {
    // 1. Ekstraksi Judul: PRIORITASKAN elemen H1 utama artikel
    String title = _extractMainArticleH1(html);

    if (title.isEmpty) {
      final metaTitle = _extractMeta(html, 'og:title') ??
          _extractMeta(html, 'twitter:title') ??
          '';
      final cleanedMetaTitle = _cleanArticleTitle(metaTitle);
      if (cleanedMetaTitle.isNotEmpty && !_isWebsiteOrGenericName(cleanedMetaTitle)) {
        title = cleanedMetaTitle;
      }
    }

    if (title.isEmpty) {
      final titleMatch =
          RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true)
              .firstMatch(html);
      if (titleMatch != null) {
        final cleanedDocTitle = _cleanArticleTitle(_cleanText(titleMatch.group(1) ?? ''));
        if (cleanedDocTitle.isNotEmpty && !_isWebsiteOrGenericName(cleanedDocTitle)) {
          title = cleanedDocTitle;
        }
      }
    }

    // 2. Ekstraksi Penulis (Author) & Tanggal Publikasi (Published Date)
    final String author = _extractAuthorFromHtml(html);
    final String publishedDate = _extractPublishedDateFromHtml(html);

    // 3. Ekstraksi Gambar Utama Artikel:
    //    (a) Cek kontainer gambar utama artikel spesifik (misal <div class="artikel-detail-image"> di Kemenkes Keslan)
    //    (b) Cek metadata og:image / twitter:image / JSON-LD (tolak placeholder/logo)
    //    (c) Cek gambar utama di dalam konten <article> / <main>
    String imageUrl = _extractDedicatedArticleContainerImage(html, pageUrl);

    if (imageUrl.isEmpty) {
      final metaCandidates = [
        _extractMeta(html, 'og:image'),
        _extractMeta(html, 'og:image:secure_url'),
        _extractMeta(html, 'og:image:url'),
        _extractMeta(html, 'twitter:image'),
        _extractMeta(html, 'twitter:image:src'),
        _extractLinkRel(html, 'image_src'),
        _extractJsonLdImage(html),
      ];

      for (final rawCandidate in metaCandidates) {
        if (rawCandidate != null && rawCandidate.trim().isNotEmpty) {
          final resolved = _resolveUrl(pageUrl, rawCandidate.trim());
          if (_isValidArticleImageUrl(resolved)) {
            imageUrl = resolved;
            break;
          }
        }
      }
    }

    if (imageUrl.isEmpty) {
      imageUrl = _extractMainImageFromArticleHtml(html, pageUrl, title);
    }

    // 4. Ekstraksi Isi Konten Artikel
    final String content = _extractArticleParagraphs(html);

    // 5. Ekstraksi Ringkasan: Dari deskripsi artikel atau paragraf pembuka artikel
    String summary = _extractMeta(html, 'og:description') ??
        _extractMeta(html, 'twitter:description') ??
        _extractMeta(html, 'description') ??
        '';
    summary = _cleanText(summary);
    if (_isWebsiteOrGenericName(summary) || summary.length < 35) {
      summary = '';
    }
    if (summary.isEmpty && content.isNotEmpty) {
      summary = _extractOpeningParagraph(content);
    }

    // 6. Ekstraksi Nama Sumber Website
    String siteName = _extractMeta(html, 'og:site_name') ??
        _extractMeta(html, 'twitter:site') ??
        '';
    if (siteName.isEmpty) {
      siteName = _extractDomainName(pageUrl);
    } else {
      siteName = _cleanText(siteName).replaceAll('@', '');
    }

    final readTime = content.isNotEmpty ? _calculateReadTime(content) : '3 menit baca';

    return ArticleScrapedMetadata(
      title: title,
      summary: summary,
      imageUrl: imageUrl,
      sourceName: siteName,
      author: author,
      publishedDate: publishedDate,
      content: content,
      readTime: readTime,
      originalUrl: pageUrl,
    );
  }

  /// Ekstrak elemen H1 utama dari artikel (mengabaikan H1 slogan di header/navigasi dan menolak nama website)
  String _extractMainArticleH1(String html) {
    // 1. Cari H1 dengan class spesifik judul artikel (misal: artikel-detail-title di Kemenkes Keslan, main-title, post-title, entry-title)
    final specificH1Matches = RegExp(
      r'<h1[^>]*class=["\x27][^"\x27]*(?:artikel-detail-title|main-title|post-title|entry-title|article-title|detail-title|title-detail|news-title)[^"\x27]*["\x27][^>]*>(.*?)</h1>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    for (final m in specificH1Matches) {
      final candidate = _cleanArticleTitle(_cleanText(m.group(1) ?? ''));
      if (candidate.length >= 8 && !_isWebsiteOrGenericName(candidate)) {
        return candidate;
      }
    }

    // 2. Hilangkan script, style, nav, header, footer, aside lalu cari H1 di dalam <article> atau <main>
    final cleanedHtml = html.replaceAll(
      RegExp(r'<(script|style|nav|header|footer|aside)[^>]*>.*?</\1>',
          caseSensitive: false, dotAll: true),
      '',
    );

    final articleBlock =
        RegExp(r'<article[^>]*>(.*?)</article>', caseSensitive: false, dotAll: true)
            .firstMatch(cleanedHtml);
    final mainBlock =
        RegExp(r'<main[^>]*>(.*?)</main>', caseSensitive: false, dotAll: true)
            .firstMatch(cleanedHtml);

    final scopes = <String>[
      if (articleBlock != null) articleBlock.group(1) ?? '',
      if (mainBlock != null) mainBlock.group(1) ?? '',
      cleanedHtml,
    ];

    for (final scope in scopes) {
      if (scope.trim().isEmpty) continue;
      final h1Matches =
          RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true).allMatches(scope);
      for (final m in h1Matches) {
        final candidate = _cleanArticleTitle(_cleanText(m.group(1) ?? ''));
        if (candidate.length >= 8 && !_isWebsiteOrGenericName(candidate)) {
          return candidate;
        }
      }
    }

    return '';
  }

  /// Ekstrak gambar dari kontainer gambar utama artikel (seperti <div class="artikel-detail-image"> pada Kemenkes)
  String _extractDedicatedArticleContainerImage(String html, String pageUrl) {
    final containerMatches = RegExp(
      r'<div[^>]*class=["\x27][^"\x27]*(?:artikel-detail-image|article-detail-image|post-thumbnail|featured-image|article-featured-image|detail-image|main-article-image)[^"\x27]*["\x27][^>]*>(.*?)</div>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    for (final cm in containerMatches) {
      final block = cm.group(1) ?? '';
      final imgMatch = RegExp(r'<img\s+[^>]*?>', caseSensitive: false, dotAll: true).firstMatch(block);
      if (imgMatch != null) {
        final tag = imgMatch.group(0) ?? '';
        for (final attr in ['data-src', 'data-lazy-src', 'data-original', 'src']) {
          final attrMatch =
              RegExp('$attr=["\x27]([^"\x27]+)["\x27]', caseSensitive: false).firstMatch(tag);
          if (attrMatch != null) {
            final resolved = _resolveUrl(pageUrl, _unescapeHtml(attrMatch.group(1) ?? '').trim());
            if (_isValidArticleImageUrl(resolved)) {
              return resolved;
            }
          }
        }
      }
    }
    return '';
  }

  /// Ekstrak Nama Penulis (Author) dari HTML
  String _extractAuthorFromHtml(String html) {
    // 1. Kemenkes Keslan: <span class="artikel-author-name">...</span> + <span class="artikel-author-unit">...</span>
    final keslanAuthorMatch = RegExp(
      r'<span[^>]*class=["\x27][^"\x27]*artikel-author-name[^"\x27]*["\x27][^>]*>(.*?)</span>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (keslanAuthorMatch != null) {
      final name = _cleanText(keslanAuthorMatch.group(1) ?? '');
      final unitMatch = RegExp(
        r'<span[^>]*class=["\x27][^"\x27]*artikel-author-unit[^"\x27]*["\x27][^>]*>(.*?)</span>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html);
      final unit = unitMatch != null ? _cleanText(unitMatch.group(1) ?? '') : '';
      if (name.isNotEmpty) {
        return unit.isNotEmpty ? '$name ($unit)' : name;
      }
    }

    // 2. Meta author
    final metaAuthor = _extractMeta(html, 'author') ??
        _extractMeta(html, 'article:author') ??
        _extractMeta(html, 'twitter:creator') ??
        '';
    if (metaAuthor.isNotEmpty &&
        !_isWebsiteOrGenericName(metaAuthor) &&
        !metaAuthor.startsWith('http')) {
      return _cleanText(metaAuthor);
    }

    // 3. JSON-LD author
    final ldMatches = RegExp(
      r'<script[^>]*type=["\x27]application/ld\+json["\x27][^>]*>(.*?)</script>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);
    for (final m in ldMatches) {
      final rawJson = m.group(1) ?? '';
      final authorMatch = RegExp(
        r'"author"\s*:\s*(?:\[\s*)?\{\s*[^}]*?"name"\s*:\s*"([^"]+)"',
        caseSensitive: false,
      ).firstMatch(rawJson);
      if (authorMatch != null) {
        final candidate = _cleanText(authorMatch.group(1) ?? '');
        if (candidate.isNotEmpty && !_isWebsiteOrGenericName(candidate)) {
          return candidate;
        }
      }
    }

    // 4. Elemen class author / reviewer / penulis
    final classAuthorMatch = RegExp(
      r'<(?:span|a|div|p)[^>]*class=["\x27][^"\x27]*(?:author-name|post-author|article-author|doctor-name|reviewer-name|penulis)[^"\x27]*["\x27][^>]*>(.*?)</(?:span|a|div|p)>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (classAuthorMatch != null) {
      final candidate = _cleanText(classAuthorMatch.group(1) ?? '');
      if (candidate.length >= 3 &&
          candidate.length <= 90 &&
          !_isWebsiteOrGenericName(candidate)) {
        return candidate;
      }
    }

    return '';
  }

  /// Ekstrak Tanggal Publikasi dari HTML
  String _extractPublishedDateFromHtml(String html) {
    // 1. Kemenkes Keslan: <span class="artikel-detail-date">...</span>
    final keslanDateMatch = RegExp(
      r'<span[^>]*class=["\x27][^"\x27]*artikel-detail-date[^"\x27]*["\x27][^>]*>(.*?)</span>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (keslanDateMatch != null) {
      final dateStr = _cleanText(keslanDateMatch.group(1) ?? '');
      if (dateStr.isNotEmpty && !dateStr.contains('1970')) {
        return dateStr;
      }
    }

    // 2. Elemen <time> atau class date
    final timeMatch =
        RegExp(r'<time[^>]*>(.*?)</time>', caseSensitive: false, dotAll: true).firstMatch(html);
    if (timeMatch != null) {
      final t = _cleanText(timeMatch.group(1) ?? '');
      if (t.isNotEmpty && !t.contains('1970') && t.length <= 50) {
        return t;
      }
    }

    final classDateMatch = RegExp(
      r'<(?:span|div|p)[^>]*class=["\x27][^"\x27]*(?:post-date|article-date|publish-date|entry-date|tanggal)[^"\x27]*["\x27][^>]*>(.*?)</(?:span|div|p)>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (classDateMatch != null) {
      final d = _cleanText(classDateMatch.group(1) ?? '');
      if (d.isNotEmpty && !d.contains('1970') && d.length <= 50) {
        return d;
      }
    }

    // 3. Meta article:published_time / JSON-LD datePublished
    final metaDate = _extractMeta(html, 'article:published_time') ??
        _extractMeta(html, 'pubdate') ??
        _extractMeta(html, 'publish-date') ??
        '';
    if (metaDate.isNotEmpty && !metaDate.contains('1970')) {
      return metaDate.split('T').first.trim();
    }

    final ldMatches = RegExp(
      r'<script[^>]*type=["\x27]application/ld\+json["\x27][^>]*>(.*?)</script>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);
    for (final m in ldMatches) {
      final rawJson = m.group(1) ?? '';
      final dateMatch = RegExp(
        r'"datePublished"\s*:\s*"([^"]+)"',
        caseSensitive: false,
      ).firstMatch(rawJson);
      if (dateMatch != null) {
        final d = (dateMatch.group(1) ?? '').split('T').first.trim();
        if (d.isNotEmpty && !d.contains('1970')) return d;
      }
    }

    return '';
  }

  /// Ambil paragraf pembuka pertama yang valid dari isi artikel sebagai ringkasan
  String _extractOpeningParagraph(String content) {
    if (content.trim().isEmpty) return '';
    final paragraphs = content
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) =>
            !p.startsWith('## ') &&
            !p.startsWith('• ') &&
            p.length >= 40 &&
            !_isWebsiteOrGenericName(p))
        .toList();

    if (paragraphs.isEmpty) return '';
    final first = paragraphs.first;
    return first.length > 260 ? '${first.substring(0, 257)}...' : first;
  }

  /// Deteksi apakah suatu teks hanyalah nama website/instansi/slogan umum (bukan judul artikel)
  bool _isWebsiteOrGenericName(String? text) {
    if (text == null || text.trim().isEmpty) return true;
    final lower = text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');

    const genericWebsiteNames = {
      'direktorat jenderal kesehatan lanjutan',
      'ditjen kesehatan lanjutan',
      'direktorat jenderal pelayanan kesehatan',
      'ditjen yankes',
      'kementerian kesehatan republik indonesia',
      'kementerian kesehatan ri',
      'kementerian kesehatan',
      'kemenkes ri',
      'kemenkes',
      'unit pelayanan kesehatan',
      'upk kemenkes',
      'ayo sehat',
      'ayosehat',
      'generasi sehat, masa depan hebat',
      'alodokter',
      'halodoc',
      'hello sehat',
      'hellosehat',
      'klikdokter',
      'kompas health',
      'detik health',
      'beranda',
      'home',
      'artikel',
      'baca artikel',
      'rilis kesehatan',
      'informasi kesehatan',
    };

    if (genericWebsiteNames.contains(lower)) return true;
    if (lower.startsWith('klikdokter - konsultasi medis')) return true;
    return false;
  }

  bool _isErrorOrBlockedText(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final lower = text.trim().toLowerCase();
    return lower.contains('the request could not be satisfied') ||
        lower.contains('access denied') ||
        lower.contains('403 forbidden') ||
        lower.contains('404 not found') ||
        lower.contains('halaman tidak ditemukan') ||
        lower.contains('just a moment...') ||
        lower.contains('attention required! | cloudflare') ||
        lower.contains('503 service temporarily unavailable') ||
        lower.contains('error 522');
  }

  String _firstValidArticleTitle(List<String?> values) {
    for (final v in values) {
      if (v != null &&
          v.trim().isNotEmpty &&
          !_isErrorOrBlockedText(v) &&
          !_isWebsiteOrGenericName(v)) {
        return _cleanArticleTitle(v.trim());
      }
    }
    return '';
  }

  String _firstValidSummary(List<String?> values) {
    for (final v in values) {
      if (v != null &&
          v.trim().isNotEmpty &&
          !_isErrorOrBlockedText(v) &&
          !_isWebsiteOrGenericName(v) &&
          v.trim().length >= 30) {
        return v.trim();
      }
    }
    return '';
  }

  String _cleanArticleTitle(String rawTitle) {
    var title = rawTitle.trim();
    for (final sep in [' - ', ' | ', ' — ', ' – ']) {
      if (title.contains(sep)) {
        final parts = title.split(sep);
        final firstPart = parts.first.trim();
        final lastPart = parts.last.trim();
        if (firstPart.length >= 10 && !_isWebsiteOrGenericName(firstPart)) {
          title = firstPart;
          break;
        } else if (lastPart.length >= 10 && !_isWebsiteOrGenericName(lastPart)) {
          title = lastPart;
          break;
        }
      }
    }
    return _isWebsiteOrGenericName(title) ? '' : title;
  }

  String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) {
        return v.trim();
      }
    }
    return '';
  }

  /// Validasi ketat apakah URL gambar adalah gambar artikel asli
  /// (menolak placeholder, logo website, maskot, hashtag header, icon, avatar, pixel tracker, atau gambar 404)
  bool _isValidArticleImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) return false;
    final lower = Uri.decodeFull(trimmed).toLowerCase();
    if (lower.startsWith('data:')) return false;
    if (lower.endsWith('.svg') || lower.contains('.svg?')) return false;
    if (lower.endsWith('.ico') || lower.contains('favicon')) return false;

    const rejectedPatterns = [
      'placeholder',
      'default-image',
      'default_image',
      'no-image',
      'no_image',
      '/logoweb/',
      '/images/logo/',
      'logokemkes',
      'logo_kemkes',
      'logo kemkes',
      'logo_upk',
      'logo_slide',
      'logo-header',
      'logo-footer',
      'logo putih',
      'logo_putih',
      'hastag',
      'maskot.png',
      '/maskot',
      'helloSEHAT-1.png',
      'hellosehat-1.png',
      '/icon_menu/',
      '/icons/512x512',
      '/icons/192x192',
      'apple-touch-icon',
      '/footer/pengaduan',
      'vectors/404',
      'facebook.com/tr',
      'google-analytics.com',
      'doubleclick.net',
      '1x1',
      'pixel.',
      'blank.gif',
      'spacer.gif',
      'spinner',
      'loader.',
      '/avatar',
    ];

    for (final pattern in rejectedPatterns) {
      if (lower.contains(pattern)) return false;
    }
    return true;
  }

  /// Ekstraksi gambar dari JSON-LD (Schema.org NewsArticle / MedicalWebPage / Article)
  String? _extractJsonLdImage(String html) {
    final matches = RegExp(
      r'<script[^>]*type=["\x27]application/ld\+json["\x27][^>]*>(.*?)</script>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    for (final m in matches) {
      final rawJson = m.group(1) ?? '';
      final imgMatches = RegExp(
        r'"(?:image|thumbnailUrl)"\s*:\s*(?:\{\s*[^}]*?"url"\s*:\s*"([^"]+)"|"([^"]+)")',
        caseSensitive: false,
      ).allMatches(rawJson);
      for (final im in imgMatches) {
        final candidate = _unescapeHtml((im.group(1) ?? im.group(2) ?? '').trim());
        if (_isValidArticleImageUrl(candidate)) {
          return candidate;
        }
      }
    }
    return null;
  }

  /// Prioritas 2: Cari gambar utama atau thumbnail dari isi halaman artikel yang sesuai dengan topik artikel
  String _extractMainImageFromArticleHtml(String html, String pageUrl, String articleTitle) {
    String cleanedHtml = html.replaceAll(
      RegExp(r'<(script|style|nav|header|footer|aside)[^>]*>.*?</\1>',
          caseSensitive: false, dotAll: true),
      '',
    );

    final articleBlockMatch =
        RegExp(r'<article[^>]*>(.*?)</article>', caseSensitive: false, dotAll: true)
            .firstMatch(cleanedHtml);
    final mainBlockMatch =
        RegExp(r'<main[^>]*>(.*?)</main>', caseSensitive: false, dotAll: true)
            .firstMatch(cleanedHtml);

    final searchScopes = <String>[
      if (articleBlockMatch != null) articleBlockMatch.group(1) ?? '',
      if (mainBlockMatch != null) mainBlockMatch.group(1) ?? '',
      cleanedHtml,
    ];

    final titleWords = articleTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .toSet();

    for (final scope in searchScopes) {
      if (scope.trim().isEmpty) continue;

      final imgTags =
          RegExp(r'<img\s+[^>]*?>', caseSensitive: false, dotAll: true).allMatches(scope);

      String bestUrl = '';
      int bestScore = -1;

      for (final m in imgTags) {
        final tag = m.group(0) ?? '';
        final tagLower = tag.toLowerCase();

        final altMatch =
            RegExp(r'alt=["\x27]([^"\x27]*)["\x27]', caseSensitive: false).firstMatch(tag);
        final altText = (altMatch?.group(1) ?? '').trim().toLowerCase();
        if (altText == 'logo' ||
            altText.startsWith('logo ') ||
            altText.contains('hastag') ||
            altText.contains('maskot') ||
            altText.contains('icon') ||
            altText.contains('pengaduan') ||
            tagLower.contains('class="logo') ||
            tagLower.contains('id="logo')) {
          continue;
        }

        String candidateUrl = '';
        for (final attr in ['data-src', 'data-lazy-src', 'data-original', 'src', 'srcset']) {
          final attrMatch =
              RegExp('$attr=["\x27]([^"\x27]+)["\x27]', caseSensitive: false).firstMatch(tag);
          if (attrMatch != null) {
            var rawCandidate = _unescapeHtml(attrMatch.group(1) ?? '').trim();
            if (attr == 'srcset' && rawCandidate.contains(' ')) {
              rawCandidate = rawCandidate.split(' ').first.trim();
            }
            final resolved = _resolveUrl(pageUrl, rawCandidate);
            if (_isValidArticleImageUrl(resolved)) {
              candidateUrl = resolved;
              break;
            }
          }
        }

        if (candidateUrl.isEmpty) continue;

        int score = 10;
        final urlLower = candidateUrl.toLowerCase();

        if (altText.isNotEmpty && titleWords.isNotEmpty) {
          int matchedWords = 0;
          for (final w in titleWords) {
            if (altText.contains(w) || urlLower.contains(w)) {
              matchedWords++;
            }
          }
          score += matchedWords * 25;
        }

        if (urlLower.contains('gambarartikel') ||
            urlLower.contains('/bg-img/') ||
            urlLower.contains('/content/') ||
            urlLower.contains('/uploads/') ||
            urlLower.contains('/attached_image/') ||
            urlLower.contains('/storage/') ||
            urlLower.contains('/artikel/') ||
            urlLower.contains('/berita/') ||
            urlLower.contains('/news/') ||
            urlLower.contains('/media/') ||
            urlLower.contains('cloudfront.net')) {
          score += 50;
        }

        if (urlLower.contains('.jpg') ||
            urlLower.contains('.jpeg') ||
            urlLower.contains('.webp')) {
          score += 15;
        }

        if (score > bestScore) {
          bestScore = score;
          bestUrl = candidateUrl;
        }
      }

      if (bestUrl.isNotEmpty) {
        return bestUrl;
      }
    }

    return '';
  }

  /// Ekstraksi gambar utama pertama dari Markdown Jina Reader
  String _extractFirstValidImageFromMarkdown(String markdown, String pageUrl) {
    final matches = RegExp(r'!\[([^\]]*)\]\(([^)\s]+)[^)]*\)').allMatches(markdown);
    for (final m in matches) {
      final alt = (m.group(1) ?? '').toLowerCase();
      if (alt.contains('logo') ||
          alt.contains('icon') ||
          alt.contains('hastag') ||
          alt.contains('maskot')) {
        continue;
      }
      final candidate = _resolveUrl(pageUrl, (m.group(2) ?? '').trim());
      if (_isValidArticleImageUrl(candidate)) {
        return candidate;
      }
    }
    return '';
  }

  /// Bersihkan Markdown hasil Jina Reader menjadi paragraf dan subjudul artikel D-Care yang rapi
  String _parseJinaMarkdownToCleanArticle(String markdown) {
    if (markdown.trim().isEmpty) return '';

    final lines = markdown.split('\n');
    final blocks = <String>[];
    final seen = <String>{};

    for (var rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('![') || (line.contains('](http') && line.startsWith('['))) {
        if (RegExp(r'^!?\[[^\]]*\]\([^)]+\)$').hasMatch(line)) continue;
      }
      line = line.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '').trim();
      line = line.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '');
      line = line.replaceAll(RegExp(r'<[^>]+>'), '');
      line = line.replaceAll('**', '').replaceAll('__', '').trim();

      if (line.isEmpty) continue;

      final lower = line.toLowerCase();
      if (lower.contains('copyright') ||
          lower.contains('baca juga') ||
          lower.contains('simak video') ||
          lower.contains('advertisement') ||
          lower.contains('all rights reserved') ||
          lower.contains('kebijakan privasi') ||
          lower.contains('syarat dan ketentuan') ||
          lower.contains('bagikan artikel') ||
          lower.contains('artikel lainnya') ||
          lower.contains('baca selengkapnya') ||
          lower.contains('kali dilihat') ||
          lower.contains('cookies') ||
          lower.startsWith('http://') ||
          lower.startsWith('https://')) {
        continue;
      }

      if (line.startsWith('#')) {
        final headingText = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        if (headingText.length >= 4 &&
            headingText.length <= 120 &&
            !_isWebsiteOrGenericName(headingText) &&
            !seen.contains(headingText.toLowerCase())) {
          seen.add(headingText.toLowerCase());
          blocks.add('## $headingText');
        }
        continue;
      }

      if (RegExp(r'^(\*|-|•)\s+').hasMatch(line)) {
        final itemText = line.replaceFirst(RegExp(r'^(\*|-|•)\s+'), '').trim();
        if (itemText.length > 20 &&
            itemText.length < 350 &&
            !seen.contains(itemText.toLowerCase())) {
          seen.add(itemText.toLowerCase());
          blocks.add('• $itemText');
        }
        continue;
      }

      if (line.length > 35 && !_isWebsiteOrGenericName(line) && !seen.contains(lower)) {
        seen.add(lower);
        blocks.add(line);
      }
    }

    if (blocks.isEmpty) return '';
    return blocks.take(26).join('\n\n');
  }

  /// Ekstraksi elemen meta property atau meta name dari HTML
  String? _extractMeta(String html, String propertyName) {
    final pattern = RegExp(
      '<meta\\s+[^>]*?(?:property|name)=["\']${RegExp.escape(propertyName)}["\'][^>]*?>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match != null) {
      final tag = match.group(0) ?? '';
      final contentMatch = RegExp('content=["\'](.*?)["\']', caseSensitive: false).firstMatch(tag);
      if (contentMatch != null) {
        final val = _unescapeHtml(contentMatch.group(1) ?? '').trim();
        if (val.isNotEmpty) return val;
      }
    }

    final reversePattern = RegExp(
      '<meta\\s+[^>]*?content=["\'](.*?)["\'][^>]*?(?:property|name)=["\']${RegExp.escape(propertyName)}["\'][^>]*?>',
      caseSensitive: false,
    );
    final revMatch = reversePattern.firstMatch(html);
    if (revMatch != null) {
      final val = _unescapeHtml(revMatch.group(1) ?? '').trim();
      if (val.isNotEmpty) return val;
    }

    return null;
  }

  String? _extractLinkRel(String html, String relName) {
    final pattern = RegExp(
      '<link\\s+[^>]*?rel=["\']${RegExp.escape(relName)}["\'][^>]*?href=["\'](.*?)["\'][^>]*?>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match != null) {
      return _unescapeHtml(match.group(1) ?? '').trim();
    }
    return null;
  }

  /// Ambil isi paragraf dan subjudul dari elemen HTML artikel, main, atau body
  String _extractArticleParagraphs(String html) {
    String searchScope = html;

    searchScope = searchScope.replaceAll(
      RegExp(r'<(script|style|nav|footer|aside|header|noscript|form)[^>]*>.*?</\1>',
          caseSensitive: false, dotAll: true),
      '',
    );

    // Utamakan div konten artikel spesifik (seperti artikel-detail-content pada Kemenkes Keslan)
    final contentDivMatch = RegExp(
      r'<div[^>]*class=["\x27][^"\x27]*(?:artikel-detail-content|article-content|post-content|entry-content|detail-content|isi-konten)[^"\x27]*["\x27][^>]*>(.*?)</div>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(searchScope);

    if (contentDivMatch != null && (contentDivMatch.group(1)?.trim().length ?? 0) > 100) {
      searchScope = contentDivMatch.group(1) ?? searchScope;
    } else {
      final articleMatch =
          RegExp(r'<article[^>]*>(.*?)</article>', caseSensitive: false, dotAll: true)
              .firstMatch(searchScope);
      if (articleMatch != null) {
        searchScope = articleMatch.group(1) ?? searchScope;
      } else {
        final mainMatch =
            RegExp(r'<main[^>]*>(.*?)</main>', caseSensitive: false, dotAll: true)
                .firstMatch(searchScope);
        if (mainMatch != null) {
          searchScope = mainMatch.group(1) ?? searchScope;
        }
      }
    }

    final blockMatches = RegExp(
      r'<(h2|h3|p|li)[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(searchScope);

    final blocks = <String>[];
    final seen = <String>{};

    for (final m in blockMatches) {
      final tag = (m.group(1) ?? 'p').toLowerCase();
      final rawText = m.group(2) ?? '';
      final clean = _cleanText(rawText);
      if (clean.isEmpty) continue;

      final lower = clean.toLowerCase();
      if (lower.contains('copyright') ||
          lower.contains('baca juga') ||
          lower.contains('simak video') ||
          lower.contains('advertisement') ||
          lower.contains('all rights reserved') ||
          lower.contains('kebijakan privasi') ||
          lower.contains('syarat dan ketentuan') ||
          lower.contains('baca selengkapnya') ||
          lower.contains('cookies')) {
        continue;
      }

      if (tag == 'h2' || tag == 'h3') {
        if (clean.length >= 4 &&
            clean.length <= 120 &&
            !_isWebsiteOrGenericName(clean) &&
            !seen.contains(lower)) {
          seen.add(lower);
          blocks.add('## $clean');
        }
      } else if (tag == 'li') {
        if (clean.length > 20 && clean.length < 350 && !seen.contains(lower)) {
          seen.add(lower);
          blocks.add('• $clean');
        }
      } else {
        if (clean.length > 35 && !_isWebsiteOrGenericName(clean) && !seen.contains(lower)) {
          seen.add(lower);
          blocks.add(clean);
        }
      }
    }

    if (blocks.isEmpty) return '';

    final limited = blocks.take(26).toList();
    return limited.join('\n\n');
  }

  String _cleanText(String input) {
    var text = input.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    text = text.replaceAll(
        RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = _unescapeHtml(text);
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  String _unescapeHtml(String text) {
    var s = text;
    s = s.replaceAll('&nbsp;', ' ');
    s = s.replaceAll('&amp;', '&');
    s = s.replaceAll('&quot;', '"');
    s = s.replaceAll('&#39;', "'");
    s = s.replaceAll('&#039;', "'");
    s = s.replaceAll('&apos;', "'");
    s = s.replaceAll('&lt;', '<');
    s = s.replaceAll('&gt;', '>');
    s = s.replaceAll('&ndash;', '–');
    s = s.replaceAll('&mdash;', '—');
    s = s.replaceAll('&hellip;', '…');
    s = s.replaceAll('&#8217;', "'");
    s = s.replaceAll('&#8216;', "'");
    s = s.replaceAll('&#8220;', '"');
    s = s.replaceAll('&#8221;', '"');
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : '';
    });
    return s.trim();
  }

  String _resolveUrl(String baseUrl, String relativeUrl) {
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }
    try {
      final base = Uri.parse(baseUrl);
      return base.resolve(relativeUrl).toString();
    } catch (_) {
      return relativeUrl;
    }
  }

  String _extractDomainName(String urlStr) {
    try {
      final uri = Uri.parse(urlStr);
      final host = uri.host.toLowerCase().replaceAll('www.', '');
      if (host.contains('keslan.kemkes.go.id')) return 'Kemenkes Ditjen Kesehatan Lanjutan';
      if (host.contains('upk.kemkes.go.id')) return 'UPK Kemenkes RI';
      if (host.contains('ayosehat.kemkes.go.id')) return 'Ayo Sehat Kemenkes RI';
      if (host.contains('kemkes.go.id')) return 'Kemenkes RI';
      if (host.contains('alodokter.com')) return 'Alodokter';
      if (host.contains('halodoc.com')) return 'Halodoc';
      if (host.contains('klikdokter.com')) return 'KlikDokter';
      if (host.contains('hellosehat.com')) return 'Hello Sehat';
      if (host.contains('kompas.com')) return 'Kompas Health';
      if (host.contains('detik.com')) return 'Detik Health';
      if (host.contains('idai.or.id')) return 'IDAI';
      if (host.contains('who.int')) return 'WHO';

      final dotIdx = host.indexOf('.');
      if (dotIdx > 0) {
        final raw = host.substring(0, dotIdx).replaceAll('-', ' ');
        return raw
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
      }
      return host;
    } catch (_) {
      return '';
    }
  }

  String _calculateReadTime(String content) {
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (words / 150).ceil().clamp(1, 10);
    return '$minutes menit baca';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget Gambar Thumbnail Artikel Asli (TANPA Gambar Default / Logo D-Care)
// ─────────────────────────────────────────────────────────────────────────────

Widget buildArticleThumbnailWidget({
  required String imageUrl,
  double height = 140,
  double width = double.infinity,
  BorderRadius? borderRadius,
  BoxFit fit = BoxFit.cover,
  bool showErrorMessage = false,
}) {
  final trimmed = imageUrl.trim();
  final hasValidHttpUrl =
      trimmed.startsWith('http://') || trimmed.startsWith('https://');

  Widget buildFailedOrEmptyBox() {
    if (showErrorMessage) {
      return Container(
        height: height,
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          border: Border.all(color: const Color(0xFFFFB74D)),
          borderRadius: borderRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFFE65100)),
            const SizedBox(height: 6),
            Text(
              'Gambar artikel tidak berhasil diambil',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE65100),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(
              'Gambar artikel tidak tersedia',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  if (!hasValidHttpUrl) {
    return buildFailedOrEmptyBox();
  }

  final isAlreadyProxied = trimmed.startsWith('https://wsrv.nl/') ||
      trimmed.startsWith('http://localhost:8787/');
  final candidateUrls = <String>[
    if (isAlreadyProxied) trimmed,
    if (kIsWeb && !isAlreadyProxied)
      'https://wsrv.nl/?url=${Uri.encodeComponent(trimmed)}&w=800&output=jpg',
    if (!isAlreadyProxied) trimmed,
    if (!kIsWeb && !isAlreadyProxied)
      'https://wsrv.nl/?url=${Uri.encodeComponent(trimmed)}&w=800&output=jpg',
  ];

  Widget buildImageWithFallbacks(int index) {
    if (index >= candidateUrls.length) {
      return buildFailedOrEmptyBox();
    }
    return Image.network(
      candidateUrls[index],
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return buildImageWithFallbacks(index + 1);
      },
      loadingBuilder: (context, imgChild, progress) {
        if (progress == null) return imgChild;
        return Container(
          height: height,
          width: width,
          color: const Color(0xFFFCF8F9),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD81B60)),
          ),
        );
      },
    );
  }

  final child = buildImageWithFallbacks(0);
  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
  return child;
}

// ─────────────────────────────────────────────────────────────────────────────
// In-App Article Reader Modal / Screen (Tanpa Redirect ke Browser Eksternal)
// ─────────────────────────────────────────────────────────────────────────────

void showAdminArticleDetailSheet(BuildContext context, AdminArticleModel article) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StreamBuilder<AdminArticleModel?>(
      stream: ArticleService.instance.streamArticle(article.id),
      initialData: article,
      builder: (ctx, snap) {
        final currentArticle = snap.data ?? article;
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          maxChildSize: 0.96,
          minChildSize: 0.5,
          expand: false,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2E7D32),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Artikel D-Care Terverifikasi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentArticle.sourceName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE4EC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentArticle.sourceName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD81B60),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF8BBD0)),
                Expanded(
                  child: SingleChildScrollView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentArticle.imageUrl.trim().isNotEmpty) ...[
                          buildArticleThumbnailWidget(
                            imageUrl: currentArticle.imageUrl,
                            height: 195,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD81B60).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentArticle.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD81B60),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF9E9E9E)),
                                const SizedBox(width: 4),
                                Text(
                                  currentArticle.readTime,
                                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
                                ),
                              ],
                            ),
                            if (currentArticle.publishedDate.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF9E9E9E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentArticle.publishedDate,
                                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentArticle.title,
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141414),
                            height: 1.35,
                          ),
                        ),
                        if (currentArticle.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCF8F9),
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                left: BorderSide(color: Color(0xFFD81B60), width: 3.5),
                              ),
                            ),
                            child: Text(
                              currentArticle.subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF424242),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded, size: 17, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ditinjau oleh: ${currentArticle.reviewer}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (currentArticle.author.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF374151)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Penulis: ${currentArticle.author}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (currentArticle.sourceName.isNotEmpty || currentArticle.sourceUrl.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.language_rounded, size: 16, color: Color(0xFFD81B60)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sumber Resmi: ${currentArticle.sourceName.isNotEmpty ? currentArticle.sourceName : "Website Edukasi Kesehatan"}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFD81B60),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFormattedArticleBody(currentArticle.content),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCF8F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF8BBD0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.chrome_reader_mode_rounded, size: 20, color: Color(0xFFD81B60)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mode Pembaca Artikel D-Care',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFD81B60),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Baca artikel dalam tampilan layar penuh yang nyaman langsung di dalam aplikasi D-Care tanpa berpindah ke browser eksternal.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF616161),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => InAppArticleReaderScreen(article: currentArticle),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.menu_book_rounded, size: 18, color: Colors.white),
                                  label: Text(
                                    'Buka Mode Baca Penuh di Aplikasi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD81B60),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildFormattedArticleBody(
  String rawContent, {
  double fontSize = 14,
  Color textColor = const Color(0xFF2B2B2B),
  Color headingColor = const Color(0xFF141414),
}) {
  final blocks = rawContent
      .split('\n\n')
      .map((b) => b.trim())
      .where((b) => b.isNotEmpty)
      .toList();

  if (blocks.isEmpty) {
    return Text(
      rawContent,
      style: GoogleFonts.poppins(fontSize: fontSize, color: textColor, height: 1.75),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: blocks.map((block) {
      if (block.startsWith('## ')) {
        final heading = block.substring(3).trim();
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: fontSize + 2.5,
              fontWeight: FontWeight.w700,
              color: headingColor,
              height: 1.4,
            ),
          ),
        );
      } else if (block.startsWith('• ')) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: GoogleFonts.poppins(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD81B60),
                ),
              ),
              Expanded(
                child: Text(
                  block.substring(2).trim(),
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    color: textColor,
                    height: 1.65,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          block,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: textColor,
            height: 1.75,
            letterSpacing: 0.1,
          ),
        ),
      );
    }).toList(),
  );
}

/// Layar Pembaca Artikel Penuh di Dalam Aplikasi (In-App Reader Tanpa Redirect Browser Eksternal)
class InAppArticleReaderScreen extends StatefulWidget {
  final AdminArticleModel article;

  const InAppArticleReaderScreen({super.key, required this.article});

  @override
  State<InAppArticleReaderScreen> createState() => _InAppArticleReaderScreenState();
}

class _InAppArticleReaderScreenState extends State<InAppArticleReaderScreen> {
  double _fontSize = 14.5;
  String _themeMode = 'light'; // 'light', 'sepia', 'dark'
  bool _isSyncing = false;
  late String _fullContent;

  @override
  void initState() {
    super.initState();
    _fullContent = widget.article.content;
    _tryEnrichContentFromSource();
  }

  Future<void> _tryEnrichContentFromSource() async {
    final url = widget.article.sourceUrl.trim();
    if (url.isEmpty) return;

    if (_fullContent.length < 600) {
      setState(() => _isSyncing = true);
      final meta = await ArticleService.instance.fetchMetadataFromUrl(url);
      if (!mounted) return;
      if (meta != null && meta.content.length > _fullContent.length) {
        setState(() {
          _fullContent = meta.content;
          _isSyncing = false;
        });
      } else {
        setState(() => _isSyncing = false);
      }
    }
  }

  Color get _bgColor {
    switch (_themeMode) {
      case 'sepia':
        return const Color(0xFFFBF5E9);
      case 'dark':
        return const Color(0xFF181A1F);
      default:
        return Colors.white;
    }
  }

  Color get _textColor {
    switch (_themeMode) {
      case 'sepia':
        return const Color(0xFF3E3226);
      case 'dark':
        return const Color(0xFFE4E6EB);
      default:
        return const Color(0xFF2B2B2B);
    }
  }

  Color get _headingColor {
    switch (_themeMode) {
      case 'sepia':
        return const Color(0xFF231B12);
      case 'dark':
        return Colors.white;
      default:
        return const Color(0xFF141414);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final hostLabel = article.sourceName.isNotEmpty
        ? article.sourceName
        : (article.sourceUrl.isNotEmpty ? article.sourceUrl : 'D-Care Health Reader');

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, size: 13, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$hostLabel • Mode Baca D-Care',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Perkecil Huruf',
            icon: const Icon(Icons.text_decrease_rounded, size: 18),
            onPressed: () {
              setState(() => _fontSize = (_fontSize - 1).clamp(12.0, 22.0));
            },
          ),
          IconButton(
            tooltip: 'Perbesar Huruf',
            icon: const Icon(Icons.text_increase_rounded, size: 18),
            onPressed: () {
              setState(() => _fontSize = (_fontSize + 1).clamp(12.0, 22.0));
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Tema Baca',
            icon: const Icon(Icons.palette_outlined, size: 20),
            onSelected: (v) => setState(() => _themeMode = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'light', child: Text('Mode Terang')),
              const PopupMenuItem(value: 'sepia', child: Text('Mode Sepia (Nyaman Mata)')),
              const PopupMenuItem(value: 'dark', child: Text('Mode Malam')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSyncing)
            const LinearProgressIndicator(
              minHeight: 2.5,
              color: Color(0xFFD81B60),
              backgroundColor: Color(0xFFFCE4EC),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.imageUrl.trim().isNotEmpty) ...[
                    buildArticleThumbnailWidget(
                      imageUrl: article.imageUrl,
                      height: 210,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD81B60).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD81B60),
                          ),
                        ),
                      ),
                      if (article.sourceName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sumber: ${article.sourceName}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD81B60),
                            ),
                          ),
                        ),
                      Text(
                        '• ${article.readTime}',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: _textColor.withValues(alpha: 0.7)),
                      ),
                      if (article.publishedDate.isNotEmpty)
                        Text(
                          '• ${article.publishedDate}',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: _textColor.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: GoogleFonts.poppins(
                      fontSize: _fontSize + 5,
                      fontWeight: FontWeight.w800,
                      color: _headingColor,
                      height: 1.35,
                    ),
                  ),
                  if (article.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD81B60).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: Color(0xFFD81B60), width: 4),
                        ),
                      ),
                      child: Text(
                        article.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: _fontSize - 0.5,
                          fontWeight: FontWeight.w500,
                          color: _textColor,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ditinjau oleh: ${article.reviewer}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (article.author.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 16, color: _textColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Penulis: ${article.author}',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _textColor.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _buildFormattedArticleBody(
                    _fullContent,
                    fontSize: _fontSize,
                    textColor: _textColor,
                    headingColor: _headingColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
