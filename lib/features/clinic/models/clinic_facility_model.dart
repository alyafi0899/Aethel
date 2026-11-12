import 'clinic_enums.dart';

class ClinicFacilityModel {
  const ClinicFacilityModel({
    required this.id,
    required this.clinicId,
    required this.name,
    this.kind = FacilityKind.consultation_room,
    this.isRoom = true,
    this.capacity,
    this.status = FacilityUnitStatus.available,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String name;
  final FacilityKind kind;
  final bool isRoom;
  final int? capacity;
  final FacilityUnitStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicFacilityModel.fromJson(Map<String, dynamic> json) {
    return ClinicFacilityModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      name: json['name'] as String,
      kind: FacilityKind.fromDb(json['kind'] as String?),
      isRoom: (json['is_room'] as bool?) ?? true,
      capacity: (json['capacity'] as num?)?.toInt(),
      status: FacilityUnitStatus.fromDb(json['status'] as String?),
      notes: json['notes'] as String?,
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
      'name': name,
      'kind': kind.dbValue,
      'is_room': isRoom,
      'capacity': capacity,
      'status': status.dbValue,
      'notes': notes,
    };
  }

  ClinicFacilityModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    FacilityKind? kind,
    bool? isRoom,
    int? capacity,
    FacilityUnitStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicFacilityModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isRoom: isRoom ?? this.isRoom,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
