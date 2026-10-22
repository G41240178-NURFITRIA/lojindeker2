// ignore_for_file: non_const_argument_for_const_parameter

import 'package:flutter/material.dart';

class MedicationReminder {
  final String id;
  String medicineName;
  String dosage;
  String schedule;
  String time;
  bool isActive;
  bool isTakenToday;
  IconData iconData;

  MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.schedule,
    required this.time,
    this.isActive = true,
    this.isTakenToday = false,
    this.iconData = Icons.medication_rounded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'schedule': schedule,
      'time': time,
      'isActive': isActive,
      'isTakenToday': isTakenToday,
      'iconCodePoint': iconData.codePoint,
      'iconFontFamily': iconData.fontFamily,
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    IconData icon = Icons.medication_rounded;
    if (map['iconCodePoint'] != null) {
      icon = IconData(
        map['iconCodePoint'] as int,
        fontFamily: map['iconFontFamily'] as String? ?? 'MaterialIcons',
      );
    }
    return MedicationReminder(
      id: map['id']?.toString() ?? 'rem-${DateTime.now().millisecondsSinceEpoch}',
      medicineName: map['medicineName']?.toString() ?? 'Obat',
      dosage: map['dosage']?.toString() ?? '1 tablet',
      schedule: map['schedule']?.toString() ?? 'Rutin',
      time: map['time']?.toString() ?? '19.00',
      isActive: map['isActive'] as bool? ?? true,
      isTakenToday: map['isTakenToday'] as bool? ?? false,
      iconData: icon,
    );
  }

  MedicationReminder copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    String? schedule,
    String? time,
    bool? isActive,
    bool? isTakenToday,
    IconData? iconData,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      schedule: schedule ?? this.schedule,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      isTakenToday: isTakenToday ?? this.isTakenToday,
      iconData: iconData ?? this.iconData,
    );
  }
}
