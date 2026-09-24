import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service helper untuk mempermudah operasi CRUD ke Cloud Firestore
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get db => _firestore;

  /// Menambahkan dokumen baru ke collection dengan ID otomatis
  Future<DocumentReference<Map<String, dynamic>>?> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef;
    } catch (e) {
      debugPrint('❌ [FirestoreService] Error addDocument ke $collectionPath: $e');
      rethrow;
    }
  }

  /// Menyimpan atau menimpa dokumen dengan ID tertentu
  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: merge));
    } catch (e) {
      debugPrint('❌ [FirestoreService] Error setDocument di $collectionPath/$docId: $e');
      rethrow;
    }
  }

  /// Memperbarui dokumen tertentu
  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [FirestoreService] Error updateDocument di $collectionPath/$docId: $e');
      rethrow;
    }
  }

  /// Menghapus dokumen tertentu
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      debugPrint('❌ [FirestoreService] Error deleteDocument di $collectionPath/$docId: $e');
      rethrow;
    }
  }

  /// Mengambil satu dokumen berdasarkan ID
  Future<DocumentSnapshot<Map<String, dynamic>>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collectionPath).doc(docId).get();
    } catch (e) {
      debugPrint('❌ [FirestoreService] Error getDocument di $collectionPath/$docId: $e');
      rethrow;
    }
  }

  /// Mengambil semua dokumen dalam sebuah collection (sekali ambil)
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } catch (e) {
      debugPrint('❌ [FirestoreService] Error getCollection dari $collectionPath: $e');
      rethrow;
    }
  }

  /// Mendengarkan perubahan data secara realtime (Stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }
}
