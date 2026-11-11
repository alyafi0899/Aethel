class ClinicMedicineModel {
  const ClinicMedicineModel({
    required this.id,
    required this.clinicId,
    required this.name,
    this.dosageForm,
    this.strength,
    this.isAvailable = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String name;
  final String? dosageForm;
  final String? strength;
  final bool isAvailable;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicMedicineModel.fromJson(Map<String, dynamic> json) {
    return ClinicMedicineModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      name: json['name'] as String,
      dosageForm: json['dosage_form'] as String?,
      strength: json['strength'] as String?,
      isAvailable: (json['is_available'] as bool?) ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'name': name,
      'dosage_form': dosageForm,
      'strength': strength,
      'is_available': isAvailable,
      'notes': notes,
    };
  }

  ClinicMedicineModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? dosageForm,
    String? strength,
    bool? isAvailable,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicMedicineModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      dosageForm: dosageForm ?? this.dosageForm,
      strength: strength ?? this.strength,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
