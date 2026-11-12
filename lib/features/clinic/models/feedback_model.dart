import 'clinic_enums.dart';

class ClinicFeedbackPrivateModel {
  const ClinicFeedbackPrivateModel({
    required this.id,
    required this.clinicId,
    required this.encounterId,
    this.patientUserId,
    this.category = FeedbackCategory.other,
    required this.message,
    this.status = FeedbackStatus.newStatus,
    this.internalNote,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String encounterId;
  final String? patientUserId;
  final FeedbackCategory category;
  final String message;
  final FeedbackStatus status;
  final String? internalNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicFeedbackPrivateModel.fromJson(Map<String, dynamic> json) {
    return ClinicFeedbackPrivateModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      encounterId: json['encounter_id'] as String,
      patientUserId: json['patient_user_id'] as String?,
      category: FeedbackCategory.fromDb(json['category'] as String?),
      message: json['message'] as String,
      status: FeedbackStatus.fromDb(json['status'] as String?),
      internalNote: json['internal_note'] as String?,
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
      'encounter_id': encounterId,
      'patient_user_id': patientUserId,
      'category': category.dbValue,
      'message': message,
      'status': status.dbValue,
      'internal_note': internalNote,
    };
  }

  ClinicFeedbackPrivateModel copyWith({
    String? id,
    String? clinicId,
    String? encounterId,
    String? patientUserId,
    FeedbackCategory? category,
    String? message,
    FeedbackStatus? status,
    String? internalNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicFeedbackPrivateModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      encounterId: encounterId ?? this.encounterId,
      patientUserId: patientUserId ?? this.patientUserId,
      category: category ?? this.category,
      message: message ?? this.message,
      status: status ?? this.status,
      internalNote: internalNote ?? this.internalNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
