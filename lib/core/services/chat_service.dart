import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/doctor/screens/doctor_dashboard_screen.dart';
import '../../services/user_repository.dart';

/// Model pesan real-time
class RealtimeChatMessage {
  final String id;
  final String text;
  final String senderRole; // 'pasien' | 'doctor'
  final String senderName;
  final String senderId;
  final String time;
  final DateTime? timestamp;
  final bool isRead;

  RealtimeChatMessage({
    required this.id,
    required this.text,
    required this.senderRole,
    required this.senderName,
    required this.senderId,
    required this.time,
    this.timestamp,
    this.isRead = false,
  });

  bool get isPatient => senderRole == 'pasien';
  bool get isDoctor => senderRole == 'doctor';

  factory RealtimeChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final ts = data['timestamp'] as Timestamp?;
    final dt = ts?.toDate();
    final timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : data['time']?.toString() ?? '';

    return RealtimeChatMessage(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      senderRole: data['senderRole']?.toString() ?? 'pasien',
      senderName: data['senderName']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      time: timeStr,
      timestamp: dt,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderRole': senderRole,
      'senderName': senderName,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

/// Model sesi konsultasi chat real-time
class RealtimeConsultationChat {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String lastMessage;
  final String lastMessageTime;
  final DateTime? lastTimestamp;
  final String lastSenderRole;
  final int unreadCountForDoctor;
  final int unreadCountForPatient;
  final String glucoseNote;

  RealtimeConsultationChat({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastTimestamp,
    required this.lastSenderRole,
    required this.unreadCountForDoctor,
    required this.unreadCountForPatient,
    required this.glucoseNote,
  });

  factory RealtimeConsultationChat.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final ts = data['lastMessageTime'] as Timestamp?;
    final dt = ts?.toDate();
    final timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return RealtimeConsultationChat(
      id: doc.id,
      patientId: data['patientId']?.toString() ?? '',
      patientName: data['patientName']?.toString() ?? 'Pasien',
      doctorId: data['doctorId']?.toString() ?? '',
      doctorName: data['doctorName']?.toString() ?? 'Dokter',
      doctorSpecialty: data['doctorSpecialty']?.toString() ?? 'Spesialis Penyakit Dalam',
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageTime: timeStr,
      lastTimestamp: dt,
      lastSenderRole: data['lastSenderRole']?.toString() ?? '',
      unreadCountForDoctor: (data['unreadCountForDoctor'] as num?)?.toInt() ?? 0,
      unreadCountForPatient: (data['unreadCountForPatient'] as num?)?.toInt() ?? 0,
      glucoseNote: data['glucoseNote']?.toString() ?? '',
    );
  }

  DoctorPatientChat toDoctorPatientChat() {
    return DoctorPatientChat(
      id: id,
      name: patientName,
      message: lastMessage.isEmpty ? 'Konsultasi baru dimulai' : lastMessage,
      time: lastMessageTime.isEmpty ? 'Baru saja' : lastMessageTime,
      unreadCount: unreadCountForDoctor,
      glucoseNote: glucoseNote.isEmpty ? 'Kondisi Gula Darah Terkontrol' : glucoseNote,
    );
  }
}

/// Service pusat untuk Chat Real-time Pasien & Dokter
class ChatService {
  ChatService._internal();
  static final ChatService instance = ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Mendapatkan atau membuat sesi chat antara pasien saat ini dan dokter
  Future<String> getOrCreateChat({
    required String doctorName,
    String? doctorId,
    String? doctorSpecialty,
    String? glucoseNote,
    String? patientName,
  }) async {
    final uid = currentUid ?? _auth.currentUser?.uid ?? 'guest_patient';

    String resolvedPatientName = patientName ?? '';
    if (resolvedPatientName.isEmpty && uid != 'guest_patient') {
      try {
        final userProfile = await UserRepository.instance.findByUid(uid);
        if (userProfile != null && userProfile.fullName.isNotEmpty) {
          resolvedPatientName = userProfile.fullName;
        } else if (_auth.currentUser?.displayName != null &&
            _auth.currentUser!.displayName!.isNotEmpty) {
          resolvedPatientName = _auth.currentUser!.displayName!;
        }
      } catch (e) {
        debugPrint('⚠️ [ChatService] Gagal mengambil profil pasien: $e');
      }
    }
    if (resolvedPatientName.isEmpty) {
      resolvedPatientName = 'Pasien';
    }

    final targetDoctorName = doctorName.toLowerCase().trim();
    final cleanTargetDoctor =
        targetDoctorName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // 1. Cek apakah sudah ada sesi chat antara pasien ini dan dokter ini
    try {
      final query = await _db
          .collection('consultation_chats')
          .where('patientId', isEqualTo: uid)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final docDoctorId = data['doctorId']?.toString().trim() ?? '';
        final docDoctorName =
            data['doctorName']?.toString().toLowerCase().trim() ?? '';
        final cleanDocDoctor =
            docDoctorName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

        bool isMatch = false;

        // Cocokkan berdasarkan ID dokter jika keduanya tersedia
        if (doctorId != null &&
            doctorId.isNotEmpty &&
            docDoctorId.isNotEmpty) {
          if (docDoctorId == doctorId) {
            isMatch = true;
          }
        }

        // Jika ID belum cocok atau salah satu kosong, cocokkan berdasarkan nama
        if (!isMatch &&
            cleanDocDoctor.isNotEmpty &&
            cleanTargetDoctor.isNotEmpty) {
          if (cleanDocDoctor.contains(cleanTargetDoctor) ||
              cleanTargetDoctor.contains(cleanDocDoctor)) {
            isMatch = true;
          }
        }

        if (isMatch) {
          // Percakapan lama ditemukan — pertahankan dan perbarui kelengkapan datanya
          final updateData = <String, dynamic>{
            'patientName': resolvedPatientName,
            if (doctorId != null &&
                doctorId.isNotEmpty &&
                docDoctorId != doctorId)
              'doctorId': doctorId,
            if (glucoseNote != null && glucoseNote.isNotEmpty)
              'glucoseNote': glucoseNote,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          doc.reference.update(updateData).catchError((_) {});
          return doc.id;
        }
      }

      // 1b. Fallback: jika pasien baru login dengan UID baru, cari sesi chat lama dengan nama pasien dan nama dokter yang sama
      if (resolvedPatientName.isNotEmpty && resolvedPatientName != 'Pasien') {
        final fallbackQuery = await _db
            .collection('consultation_chats')
            .where('patientName', isEqualTo: resolvedPatientName)
            .get();

        for (final doc in fallbackQuery.docs) {
          final data = doc.data();
          final docDoctorName =
              data['doctorName']?.toString().toLowerCase().trim() ?? '';
          final cleanDocDoctor =
              docDoctorName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

          if (cleanDocDoctor.isNotEmpty &&
              (cleanDocDoctor.contains(cleanTargetDoctor) ||
                  cleanTargetDoctor.contains(cleanDocDoctor))) {
            // Tautkan sesi chat lama ini ke UID pasien yang sekarang login
            doc.reference.update({
              'patientId': uid,
              if (doctorId != null && doctorId.isNotEmpty)
                'doctorId': doctorId,
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((_) {});
            return doc.id;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ChatService] Query chat eksisting: $e');
    }

    // 2. Buat sesi chat baru jika benar-benar belum pernah ada
    final docRef = _db.collection('consultation_chats').doc();
    await docRef.set({
      'patientId': uid,
      'patientName': resolvedPatientName,
      'doctorId': doctorId ?? '',
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty ?? 'Spesialis Penyakit Dalam',
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderRole': '',
      'unreadCountForDoctor': 0,
      'unreadCountForPatient': 0,
      'glucoseNote': glucoseNote ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Stream pesan dalam satu sesi chat
  Stream<List<RealtimeChatMessage>> streamMessages(String chatId) {
    return _db
        .collection('consultation_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => RealtimeChatMessage.fromFirestore(doc)).toList());
  }

  /// Kirim pesan chat (baik oleh pasien maupun dokter)
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderRole, // 'pasien' | 'doctor'
    required String senderName,
    String? senderId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final actualSenderId = senderId ?? currentUid ?? '';

    // 1. Tambah dokumen pesan ke subcollection messages
    await _db
        .collection('consultation_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': trimmed,
      'senderRole': senderRole,
      'senderName': senderName,
      'senderId': actualSenderId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2. Perbarui ringkasan dokumen chat utama
    final updateData = <String, dynamic>{
      'lastMessage': trimmed,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderRole': senderRole,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (senderRole == 'pasien') {
      updateData['unreadCountForDoctor'] = FieldValue.increment(1);
    } else {
      updateData['unreadCountForPatient'] = FieldValue.increment(1);
    }

    await _db
        .collection('consultation_chats')
        .doc(chatId)
        .update(updateData);
  }

  /// Stream daftar percakapan untuk akun dokter (presisten dan tidak hilang saat logout/login)
  Stream<List<RealtimeConsultationChat>> streamDoctorChats({
    String? doctorId,
    String? doctorName,
  }) {
    return _db.collection('consultation_chats').snapshots().map((snap) {
      final chats = snap.docs
          .map((doc) => RealtimeConsultationChat.fromFirestore(doc))
          .toList();

      // Urutkan berdasarkan waktu pesan terakhir terbaru
      chats.sort((a, b) => (b.lastTimestamp ?? DateTime(2000))
          .compareTo(a.lastTimestamp ?? DateTime(2000)));

      if (doctorId != null && doctorId.isNotEmpty) {
        final filteredById = chats.where((c) {
          if (c.doctorId == doctorId) return true;
          // Fallback pencocokan nama jika doctorId di dokumen chat lama belum terisi
          if (c.doctorId.isEmpty && doctorName != null && doctorName.isNotEmpty) {
            final dNameLower = doctorName
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            final cDoctorLower = c.doctorName
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            return cDoctorLower.contains(dNameLower) ||
                dNameLower.contains(cDoctorLower);
          }
          return false;
        }).toList();

        if (filteredById.isNotEmpty) return filteredById;
      }

      if (doctorName != null && doctorName.trim().isNotEmpty) {
        final dNameLower =
            doctorName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        final filtered = chats.where((c) {
          final cDoctorLower = c.doctorName
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          final matchName = cDoctorLower.contains(dNameLower) ||
              dNameLower.contains(cDoctorLower);
          final matchId = (doctorId != null &&
              doctorId.isNotEmpty &&
              c.doctorId == doctorId);
          return matchName || matchId;
        }).toList();

        return filtered.isNotEmpty ? filtered : chats;
      }

      return chats;
    });
  }

  /// Tandai chat telah dibaca oleh dokter
  Future<void> markAsReadByDoctor(String chatId) async {
    try {
      await _db
          .collection('consultation_chats')
          .doc(chatId)
          .update({'unreadCountForDoctor': 0});
    } catch (_) {}
  }

  /// Tandai chat telah dibaca oleh pasien
  Future<void> markAsReadByPatient(String chatId) async {
    try {
      await _db
          .collection('consultation_chats')
          .doc(chatId)
          .update({'unreadCountForPatient': 0});
    } catch (_) {}
  }
}
