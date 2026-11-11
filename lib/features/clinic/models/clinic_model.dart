import 'clinic_enums.dart';

class ClinicModel {
  const ClinicModel({
    required this.id,
    required this.ownerId,
    this.status = ClinicStatus.draft,
    this.isPublished = false,
    this.onboardingStep = 1,
    this.clinicName,
    this.legalEntityType,
    this.addressFull,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.sioNumber,
    this.sioExpiry,
    this.npwp,
    this.fasyankesCode,
    this.deedNumber,
    this.bpjsRegistered = false,
    this.bpjsFacilityCode,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final ClinicStatus status;
  final bool isPublished;
  final int onboardingStep;

  // Data Dasar
  final String? clinicName;
  final LegalEntityType? legalEntityType;
  final String? addressFull;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? sioNumber;
  final DateTime? sioExpiry;
  final String? npwp;
  final String? fasyankesCode;
  final String? deedNumber;

  // Administrasi & Legal
  final bool bpjsRegistered;
  final String? bpjsFacilityCode;

  // Verifikasi
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      status: ClinicStatus.fromDb(json['status'] as String?),
      isPublished: (json['is_published'] as bool?) ?? false,
      onboardingStep: (json['onboarding_step'] as num?)?.toInt() ?? 1,
      clinicName: json['clinic_name'] as String?,
      legalEntityType: LegalEntityType.fromDb(json['legal_entity_type'] as String?),
      addressFull: json['address_full'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      sioNumber: json['sio_number'] as String?,
      sioExpiry: json['sio_expiry'] != null ? DateTime.tryParse(json['sio_expiry'] as String) : null,
      npwp: json['npwp'] as String?,
      fasyankesCode: json['fasyankes_code'] as String?,
      deedNumber: json['deed_number'] as String?,
      bpjsRegistered: (json['bpjs_registered'] as bool?) ?? false,
      bpjsFacilityCode: json['bpjs_facility_code'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      reviewedBy: json['reviewed_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'status': status.dbValue,
      'is_published': isPublished,
      'onboarding_step': onboardingStep,
      'clinic_name': clinicName,
      'legal_entity_type': legalEntityType?.dbValue,
      'address_full': addressFull,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'sio_number': sioNumber,
      'sio_expiry': sioExpiry?.toIso8601String().split('T').first,
      'npwp': npwp,
      'fasyankes_code': fasyankesCode,
      'deed_number': deedNumber,
      'bpjs_registered': bpjsRegistered,
      'bpjs_facility_code': bpjsFacilityCode,
    };
  }

  ClinicModel copyWith({
    String? id,
    String? ownerId,
    ClinicStatus? status,
    bool? isPublished,
    int? onboardingStep,
    String? clinicName,
    LegalEntityType? legalEntityType,
    String? addressFull,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? sioNumber,
    DateTime? sioExpiry,
    String? npwp,
    String? fasyankesCode,
    String? deedNumber,
    bool? bpjsRegistered,
    String? bpjsFacilityCode,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      clinicName: clinicName ?? this.clinicName,
      legalEntityType: legalEntityType ?? this.legalEntityType,
      addressFull: addressFull ?? this.addressFull,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      sioNumber: sioNumber ?? this.sioNumber,
      sioExpiry: sioExpiry ?? this.sioExpiry,
      npwp: npwp ?? this.npwp,
      fasyankesCode: fasyankesCode ?? this.fasyankesCode,
      deedNumber: deedNumber ?? this.deedNumber,
      bpjsRegistered: bpjsRegistered ?? this.bpjsRegistered,
      bpjsFacilityCode: bpjsFacilityCode ?? this.bpjsFacilityCode,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
