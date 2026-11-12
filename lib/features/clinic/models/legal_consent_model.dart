class LegalConsentModel {
  const LegalConsentModel({
    required this.id,
    required this.userId,
    required this.documentType, // 'terms' | 'privacy'
    required this.documentVersion, // e.g. '2026-11'
    this.acceptedAt,
  });

  final String id;
  final String userId;
  final String documentType;
  final String documentVersion;
  final DateTime? acceptedAt;

  factory LegalConsentModel.fromJson(Map<String, dynamic> json) {
    return LegalConsentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      documentVersion: json['document_version'] as String,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_type': documentType,
      'document_version': documentVersion,
    };
  }
}
