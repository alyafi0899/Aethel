class ClinicOrgStructureModel {
  const ClinicOrgStructureModel({
    required this.id,
    required this.clinicId,
    required this.personName,
    required this.position,
    this.healthWorkerId,
    this.parentId,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String personName;
  final String position;
  final String? healthWorkerId;
  final String? parentId;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicOrgStructureModel.fromJson(Map<String, dynamic> json) {
    return ClinicOrgStructureModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      personName: json['person_name'] as String,
      position: json['position'] as String,
      healthWorkerId: json['health_worker_id'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
      'person_name': personName,
      'position': position,
      'health_worker_id': healthWorkerId,
      'parent_id': parentId,
      'sort_order': sortOrder,
    };
  }

  ClinicOrgStructureModel copyWith({
    String? id,
    String? clinicId,
    String? personName,
    String? position,
    String? healthWorkerId,
    String? parentId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicOrgStructureModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      personName: personName ?? this.personName,
      position: position ?? this.position,
      healthWorkerId: healthWorkerId ?? this.healthWorkerId,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
