import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/patient/models/consultation_booking_model.dart';
import 'patient_activity_service.dart';

/// Service untuk mengelola data booking jadwal konsultasi dokter secara real-time
class ConsultationBookingService {
  ConsultationBookingService._internal();
  static final ConsultationBookingService instance =
      ConsultationBookingService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream real-time semua booking aktif dokter untuk tanggal tertentu (dateKey: YYYY-MM-DD)
  Stream<List<ConsultationBookingModel>> streamBookings({
    required String doctorId,
    required String dateKey,
  }) {
    // Normalisasi query
    return _db
        .collection('consultation_bookings')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateKey', isEqualTo: dateKey)
        .where('status', isEqualTo: 'booked')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ConsultationBookingModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Mengecek apakah suatu slot jam sudah dibooking secara real-time
  Future<bool> isSlotBooked({
    required String doctorId,
    required String dateKey,
    required String timeSlot,
  }) async {
    final query = await _db
        .collection('consultation_bookings')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateKey', isEqualTo: dateKey)
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', isEqualTo: 'booked')
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Membuat booking baru dengan proteksi atomic real-time
  Future<ConsultationBookingModel> createBooking(
      ConsultationBookingModel booking) async {
    // 1. Cek ketersediaan slot terakhir
    final isAlreadyBooked = await isSlotBooked(
      doctorId: booking.doctorId,
      dateKey: booking.dateKey,
      timeSlot: booking.timeSlot,
    );

    if (isAlreadyBooked) {
      throw Exception(
        'Slot jam ${booking.timeSlot} sudah dibooking oleh pasien lain. Silakan pilih jam lain.',
      );
    }

    // 2. Simpan ke koleksi consultation_bookings
    final docRef = _db.collection('consultation_bookings').doc();
    final newBooking = ConsultationBookingModel(
      id: docRef.id,
      doctorId: booking.doctorId,
      doctorName: booking.doctorName,
      doctorSpecialty: booking.doctorSpecialty,
      patientId: booking.patientId,
      patientName: booking.patientName,
      date: booking.date,
      dateKey: booking.dateKey,
      timeSlot: booking.timeSlot,
      complaint: booking.complaint,
      status: 'booked',
      createdAt: DateTime.now(),
    );

    await docRef.set(newBooking.toMap());

    // 3. Catat ke PatientActivityService (Aktivitas Pasien)
    try {
      await PatientActivityService.instance.recordConsultation(
        doctorName: booking.doctorName,
        specialty: booking.doctorSpecialty,
        lastMessage: booking.complaint.isNotEmpty
            ? 'Booking: ${booking.timeSlot} - ${booking.complaint}'
            : 'Booking jadwal konsultasi jam ${booking.timeSlot}',
      );
    } catch (e) {
      debugPrint('ℹ️ [ConsultationBookingService] Sinkron aktivitas pasien: $e');
    }

    return newBooking;
  }

  /// Membatalkan booking konsultasi
  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('consultation_bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Seed slot demo awal (seperti pada gambar: 10:30 & 14:00 sudah dibooking orang lain)
  /// jika tanggal tersebut belum memiliki data booking sama sekali
  Future<void> seedInitialBookingsIfEmpty({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String dateKey,
    required String dateText,
  }) async {
    try {
      final existing = await _db
          .collection('consultation_bookings')
          .where('doctorId', isEqualTo: doctorId)
          .where('dateKey', isEqualTo: dateKey)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        // Buat 2 slot terisi seperti di gambar contoh (10:30 dan 14:00)
        final batch = _db.batch();

        final ref1 = _db.collection('consultation_bookings').doc();
        batch.set(ref1, {
          'id': ref1.id,
          'doctorId': doctorId,
          'doctorName': doctorName,
          'doctorSpecialty': doctorSpecialty,
          'patientId': 'other_patient_1',
          'patientName': 'Pasien Terdaftar',
          'date': dateText,
          'dateKey': dateKey,
          'timeSlot': '10:30',
          'complaint': 'Pemeriksaan rutin berkala',
          'status': 'booked',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final ref2 = _db.collection('consultation_bookings').doc();
        batch.set(ref2, {
          'id': ref2.id,
          'doctorId': doctorId,
          'doctorName': doctorName,
          'doctorSpecialty': doctorSpecialty,
          'patientId': 'other_patient_2',
          'patientName': 'Pasien Terdaftar',
          'date': dateText,
          'dateKey': dateKey,
          'timeSlot': '14:00',
          'complaint': 'Konsultasi lanjutan kadar gula darah',
          'status': 'booked',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        debugPrint(
            '✅ [ConsultationBookingService] Seed awal slot 10:30 & 14:00 berhasil untuk $dateKey');
      }
    } catch (e) {
      debugPrint('ℹ️ [ConsultationBookingService] seedInitialBookingsIfEmpty: $e');
    }
  }
}
