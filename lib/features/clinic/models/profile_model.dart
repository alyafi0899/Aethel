class ProfileModel {
  const ProfileModel({
    required this.id,
    this.fullName,
    this.phone,
    this.accountType = 'clinic',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String accountType; // 'clinic', 'patient', 'health_worker'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isClinicAccount => accountType == 'clinic';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      accountType: (json['account_type'] as String?) ?? 'clinic',
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
      'full_name': fullName,
      'phone': phone,
      'account_type': accountType,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
