import 'clinic_enums.dart';

class ClinicMediaModel {
  const ClinicMediaModel({
    required this.id,
    required this.clinicId,
    required this.kind,
    required this.filePath,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.altText,
    this.sortOrder = 0,
    this.reviewStatus = DocumentReviewStatus.pending,
    this.reviewNote,
    this.uploadedBy,
    this.publicUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final MediaKind kind;
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? altText;
  final int sortOrder;
  final DocumentReviewStatus reviewStatus;
  final String? reviewNote;
  final String? uploadedBy;
  final String? publicUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicMediaModel.fromJson(Map<String, dynamic> json) {
    return ClinicMediaModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      kind: MediaKind.fromDb(json['kind'] as String?),
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String?,
      mimeType: json['mime_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      altText: json['alt_text'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      reviewStatus:
          DocumentReviewStatus.fromDb(json['review_status'] as String?),
      reviewNote: json['review_note'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      publicUrl: json['public_url'] as String?,
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
      'kind': kind.dbValue,
      'file_path': filePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'alt_text': altText,
      'sort_order': sortOrder,
    };
  }

  ClinicMediaModel copyWith({
    String? id,
    String? clinicId,
    MediaKind? kind,
    String? filePath,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? altText,
    int? sortOrder,
    DocumentReviewStatus? reviewStatus,
    String? reviewNote,
    String? uploadedBy,
    String? publicUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicMediaModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      kind: kind ?? this.kind,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      altText: altText ?? this.altText,
      sortOrder: sortOrder ?? this.sortOrder,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewNote: reviewNote ?? this.reviewNote,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      publicUrl: publicUrl ?? this.publicUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
