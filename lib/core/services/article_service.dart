import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Model artikel yang dibuat admin dan disimpan di Firestore
class AdminArticleModel {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String content;
  final String readTime;
  final String reviewer;
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
    required this.createdAt,
    this.updatedAt,
  });

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  factory AdminArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AdminArticleModel(
      id: doc.id,
      category: data['category']?.toString() ?? 'Umum',
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      readTime: data['readTime']?.toString() ?? '3 menit baca',
      reviewer: data['reviewer']?.toString() ?? 'Tim Medis LojinDeker',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseNullableDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'readTime': readTime,
      'reviewer': reviewer,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service untuk CRUD artikel admin ke Firestore
class ArticleService {
  static final ArticleService instance = ArticleService._();
  ArticleService._();

  final _col = FirebaseFirestore.instance.collection('admin_articles');

  /// Stream real-time semua artikel admin, diurutkan terbaru
  Stream<List<AdminArticleModel>> streamArticles() {
    return _col.snapshots().map((snap) {
      final list = <AdminArticleModel>[];
      for (final doc in snap.docs) {
        try {
          list.add(AdminArticleModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ [ArticleService] Gagal parsing artikel ${doc.id}: $e');
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

  /// Stream real-time satu artikel spesifik berdasarkan ID
  Stream<AdminArticleModel?> streamArticle(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AdminArticleModel.fromFirestore(doc);
    });
  }

  /// Tambah artikel baru ke Firestore
  Future<void> addArticle(AdminArticleModel article) async {
    await _col.add(article.toFirestore());
  }

  /// Update / Edit artikel di Firestore secara real-time
  Future<void> updateArticle(AdminArticleModel article) async {
    await _col.doc(article.id).update({
      'category': article.category,
      'title': article.title,
      'subtitle': article.subtitle,
      'content': article.content,
      'readTime': article.readTime,
      'reviewer': article.reviewer,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus artikel dari Firestore berdasarkan ID
  Future<void> deleteArticle(String id) async {
    await _col.doc(id).delete();
  }
}

/// Helper Bottom Sheet Detail Artikel Admin yang tersinkronisasi secara real-time
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
          initialChildSize: 0.9,
          maxChildSize: 0.95,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              'Artikel Terverifikasi Tim Medis',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF8BBD0)),
                Expanded(
                  child: SingleChildScrollView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge kategori + waktu baca
                        Row(
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
                            const SizedBox(width: 8),
                            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF9E9E9E)),
                            const SizedBox(width: 4),
                            Text(
                              currentArticle.readTime,
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
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
                            height: 1.3,
                          ),
                        ),
                        if (currentArticle.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentArticle.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF616161),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCF8F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF2E7D32)),
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
                        ),
                        const SizedBox(height: 20),
                        Text(
                          currentArticle.content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                            height: 1.7,
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
