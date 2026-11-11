import 'clinic_enums.dart';

class ClinicMemberModel {
  const ClinicMemberModel({
    required this.clinicId,
    required this.userId,
    this.role = ClinicRole.admin,
    this.createdAt,
  });

  final String clinicId;
  final String userId;
  final ClinicRole role;
  final DateTime? createdAt;

  factory ClinicMemberModel.fromJson(Map<String, dynamic> json) {
    return ClinicMemberModel(
      clinicId: json['clinic_id'] as String,
      userId: json['user_id'] as String,
      role: ClinicRole.fromDb(json['role'] as String?),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'user_id': userId,
      'role': role.dbValue,
    };
  }
}
