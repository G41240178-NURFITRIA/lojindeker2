import 'package:cloud_firestore/cloud_firestore.dart';

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

  AdminArticleModel({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.readTime,
    required this.reviewer,
    required this.createdAt,
  });

  factory AdminArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminArticleModel(
      id: doc.id,
      category: data['category'] ?? 'Umum',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      content: data['content'] ?? '',
      readTime: data['readTime'] ?? '3 menit baca',
      reviewer: data['reviewer'] ?? 'Tim Medis LojinDeker',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    };
  }
}

/// Service untuk CRUD artikel admin ke Firestore
class ArticleService {
  static final ArticleService instance = ArticleService._();
  ArticleService._();

  final _col = FirebaseFirestore.instance.collection('admin_articles');

  /// Stream real-time semua artikel admin, diurutkan terbaru (sort di client)
  Stream<List<AdminArticleModel>> streamArticles() {
    return _col
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AdminArticleModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Tambah artikel baru ke Firestore
  Future<void> addArticle(AdminArticleModel article) async {
    await _col.add(article.toFirestore());
  }

  /// Hapus artikel dari Firestore berdasarkan ID
  Future<void> deleteArticle(String id) async {
    await _col.doc(id).delete();
  }
}
