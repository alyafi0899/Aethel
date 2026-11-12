import 'clinic_enums.dart';

class ClinicEmrSettingsModel {
  const ClinicEmrSettingsModel({
    required this.clinicId,
    this.emrAppName,
    this.emrAppType = EmrAppType.none,
    this.satusehatOrganizationId,
    this.satusehatConnected = false,
    this.createdAt,
    this.updatedAt,
  });

  final String clinicId;
  final String? emrAppName;
  final EmrAppType emrAppType;
  final String? satusehatOrganizationId;
  final bool satusehatConnected;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicEmrSettingsModel.fromJson(Map<String, dynamic> json) {
    return ClinicEmrSettingsModel(
      clinicId: json['clinic_id'] as String,
      emrAppName: json['emr_app_name'] as String?,
      emrAppType: EmrAppType.fromDb(json['emr_app_type'] as String?),
      satusehatOrganizationId: json['satusehat_organization_id'] as String?,
      satusehatConnected: (json['satusehat_connected'] as bool?) ?? false,
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
      'clinic_id': clinicId,
      'emr_app_name': emrAppName,
      'emr_app_type': emrAppType.dbValue,
      'satusehat_organization_id': satusehatOrganizationId,
    };
  }

  ClinicEmrSettingsModel copyWith({
    String? clinicId,
    String? emrAppName,
    EmrAppType? emrAppType,
    String? satusehatOrganizationId,
    bool? satusehatConnected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicEmrSettingsModel(
      clinicId: clinicId ?? this.clinicId,
      emrAppName: emrAppName ?? this.emrAppName,
      emrAppType: emrAppType ?? this.emrAppType,
      satusehatOrganizationId:
          satusehatOrganizationId ?? this.satusehatOrganizationId,
      satusehatConnected: satusehatConnected ?? this.satusehatConnected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
