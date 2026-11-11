class ClinicServiceModel {
  const ClinicServiceModel({
    required this.id,
    required this.clinicId,
    required this.serviceType,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String serviceType;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicServiceModel.fromJson(Map<String, dynamic> json) {
    return ClinicServiceModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      serviceType: json['service_type'] as String,
      description: json['description'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'service_type': serviceType,
      'description': description,
      'is_active': isActive,
    };
  }

  ClinicServiceModel copyWith({
    String? id,
    String? clinicId,
    String? serviceType,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicServiceModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
