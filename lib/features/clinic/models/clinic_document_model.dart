import 'clinic_enums.dart';

class ClinicDocumentModel {
  const ClinicDocumentModel({
    required this.id,
    required this.clinicId,
    required this.docType,
    required this.filePath,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.reviewStatus = DocumentReviewStatus.pending,
    this.reviewNote,
    this.uploadedBy,
    this.signedUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final DocumentType docType;
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final DocumentReviewStatus reviewStatus;
  final String? reviewNote;
  final String? uploadedBy;
  final String? signedUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicDocumentModel.fromJson(Map<String, dynamic> json) {
    return ClinicDocumentModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      docType: DocumentType.fromDb(json['doc_type'] as String?),
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String?,
      mimeType: json['mime_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      reviewStatus: DocumentReviewStatus.fromDb(json['review_status'] as String?),
      reviewNote: json['review_note'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      signedUrl: json['signed_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'doc_type': docType.dbValue,
      'file_path': filePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
    };
  }

  ClinicDocumentModel copyWith({
    String? id,
    String? clinicId,
    DocumentType? docType,
    String? filePath,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    DocumentReviewStatus? reviewStatus,
    String? reviewNote,
    String? uploadedBy,
    String? signedUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicDocumentModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      docType: docType ?? this.docType,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewNote: reviewNote ?? this.reviewNote,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      signedUrl: signedUrl ?? this.signedUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
