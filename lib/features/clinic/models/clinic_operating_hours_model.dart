class ClinicOperatingHoursModel {
  const ClinicOperatingHoursModel({
    required this.id,
    required this.clinicId,
    required this.dayOfWeek, // 1 = Senin, 7 = Minggu
    this.isOpen = false,
    this.openTime = '08:00',
    this.closeTime = '17:00',
    this.breakStart,
    this.breakEnd,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final int dayOfWeek;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? breakStart;
  final String? breakEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  String get dayName => (dayOfWeek >= 1 && dayOfWeek <= 7)
      ? dayNames[dayOfWeek - 1]
      : 'Hari $dayOfWeek';

  factory ClinicOperatingHoursModel.fromJson(Map<String, dynamic> json) {
    return ClinicOperatingHoursModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      isOpen: (json['is_open'] as bool?) ?? false,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      breakStart: json['break_start'] as String?,
      breakEnd: json['break_end'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'day_of_week': dayOfWeek,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
      'break_start': breakStart,
      'break_end': breakEnd,
    };
  }

  ClinicOperatingHoursModel copyWith({
    String? id,
    String? clinicId,
    int? dayOfWeek,
    bool? isOpen,
    String? openTime,
    String? closeTime,
    String? breakStart,
    String? breakEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicOperatingHoursModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
