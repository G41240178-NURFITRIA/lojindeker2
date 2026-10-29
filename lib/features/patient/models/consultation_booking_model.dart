import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data booking konsultasi dokter real-time
class ConsultationBookingModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientId;
  final String patientName;
  final String date; // Contoh: "Kamis, 24 September 2026"
  final String dateKey; // Contoh: "2026-09-24" (untuk query efisien)
  final String timeSlot; // Contoh: "09:00", "10:30"
  final String complaint; // Keluhan singkat pasien
  final String status; // 'booked', 'completed', 'cancelled'
  final DateTime? createdAt;
  final String? transactionId;
  final String? paymentMethod;
  final int? totalAmount;
  final bool isDoctorRead;

  const ConsultationBookingModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.dateKey,
    required this.timeSlot,
    required this.complaint,
    this.status = 'booked',
    this.createdAt,
    this.transactionId,
    this.paymentMethod,
    this.totalAmount,
    this.isDoctorRead = false,
  });

  ConsultationBookingModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? patientId,
    String? patientName,
    String? date,
    String? dateKey,
    String? timeSlot,
    String? complaint,
    String? status,
    DateTime? createdAt,
    String? transactionId,
    String? paymentMethod,
    int? totalAmount,
    bool? isDoctorRead,
  }) {
    return ConsultationBookingModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      dateKey: dateKey ?? this.dateKey,
      timeSlot: timeSlot ?? this.timeSlot,
      complaint: complaint ?? this.complaint,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      isDoctorRead: isDoctorRead ?? this.isDoctorRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'patientId': patientId,
      'patientName': patientName,
      'date': date,
      'dateKey': dateKey,
      'timeSlot': timeSlot,
      'complaint': complaint,
      'status': status,
      'isDoctorRead': isDoctorRead,
      if (transactionId != null) 'transactionId': transactionId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (totalAmount != null) 'totalAmount': totalAmount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ConsultationBookingModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['createdAt']);
    }

    return ConsultationBookingModel(
      id: id,
      doctorId: map['doctorId']?.toString() ?? '',
      doctorName: map['doctorName']?.toString() ?? 'dr. Yosua',
      doctorSpecialty: map['doctorSpecialty']?.toString() ?? 'Sp.A',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? 'Pasien',
      date: map['date']?.toString() ?? '',
      dateKey: map['dateKey']?.toString() ?? '',
      timeSlot: map['timeSlot']?.toString() ?? '',
      complaint: map['complaint']?.toString() ?? '',
      status: map['status']?.toString() ?? 'booked',
      createdAt: parsedCreatedAt,
      transactionId: map['transactionId']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      totalAmount: map['totalAmount'] is num ? (map['totalAmount'] as num).toInt() : null,
      isDoctorRead: map['isDoctorRead'] == true,
    );
  }

  factory ConsultationBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConsultationBookingModel.fromMap(data, doc.id);
  }
}
