import 'clinic_enums.dart';

class ClinicEquipmentModel {
  const ClinicEquipmentModel({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category = EquipmentCategory.medical,
    this.quantity = 1,
    this.condition,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String name;
  final EquipmentCategory category;
  final int quantity;
  final String? condition;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicEquipmentModel.fromJson(Map<String, dynamic> json) {
    return ClinicEquipmentModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      name: json['name'] as String,
      category: EquipmentCategory.fromDb(json['category'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      condition: json['condition'] as String?,
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
      'category': category.dbValue,
      'quantity': quantity,
      'condition': condition,
      'notes': notes,
    };
  }

  ClinicEquipmentModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    EquipmentCategory? category,
    int? quantity,
    String? condition,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicEquipmentModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
