import 'clinic_enums.dart';

class HealthWorkerModel {
  const HealthWorkerModel({
    required this.id,
    required this.clinicId,
    this.userId,
    this.workerType = HealthWorkerType.doctor,
    this.isPersonInCharge = false,
    this.isActive = true,
    this.onDutyStatus = DutyStatus.off,
    required this.fullName,
    this.titleDegree,
    this.specialization,
    this.strNumber,
    this.strExpiry,
    this.sipNumber,
    this.sipExpiry,
    this.privateData,
    this.educations = const [],
    this.experiences = const [],
    this.certificates = const [],
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String? userId;
  final HealthWorkerType workerType;
  final bool isPersonInCharge;
  final bool isActive;
  final DutyStatus onDutyStatus;

  // Professional Data
  final String fullName;
  final String? titleDegree;
  final String? specialization;
  final String? strNumber;
  final DateTime? strExpiry;
  final String? sipNumber;
  final DateTime? sipExpiry;

  // Joined Child Data
  final HealthWorkerPrivateModel? privateData;
  final List<HealthWorkerEducationModel> educations;
  final List<HealthWorkerExperienceModel> experiences;
  final List<HealthWorkerCertificateModel> certificates;
  final List<HealthWorkerDocumentModel> documents;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isStrExpired => strExpiry != null && strExpiry!.isBefore(DateTime.now());
  bool get isStrExpiringSoon {
    if (strExpiry == null) return false;
    final diff = strExpiry!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 90;
  }

  bool get isSipExpired => sipExpiry != null && sipExpiry!.isBefore(DateTime.now());
  bool get isSipExpiringSoon {
    if (sipExpiry == null) return false;
    final diff = sipExpiry!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 90;
  }

  factory HealthWorkerModel.fromJson(Map<String, dynamic> json) {
    return HealthWorkerModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      userId: json['user_id'] as String?,
      workerType: HealthWorkerType.fromDb(json['worker_type'] as String?),
      isPersonInCharge: (json['is_person_in_charge'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? true,
      onDutyStatus: DutyStatus.fromDb(json['on_duty_status'] as String?),
      fullName: json['full_name'] as String? ?? 'N/A',
      titleDegree: json['title_degree'] as String?,
      specialization: json['specialization'] as String?,
      strNumber: json['str_number'] as String?,
      strExpiry: json['str_expiry'] != null ? DateTime.tryParse(json['str_expiry'] as String) : null,
      sipNumber: json['sip_number'] as String?,
      sipExpiry: json['sip_expiry'] != null ? DateTime.tryParse(json['sip_expiry'] as String) : null,
      privateData: json['health_worker_private'] != null
          ? HealthWorkerPrivateModel.fromJson(json['health_worker_private'] as Map<String, dynamic>)
          : null,
      educations: json['health_worker_educations'] != null
          ? (json['health_worker_educations'] as List)
              .map((e) => HealthWorkerEducationModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      experiences: json['health_worker_experiences'] != null
          ? (json['health_worker_experiences'] as List)
              .map((e) => HealthWorkerExperienceModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      certificates: json['health_worker_certificates'] != null
          ? (json['health_worker_certificates'] as List)
              .map((e) => HealthWorkerCertificateModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      documents: json['health_worker_documents'] != null
          ? (json['health_worker_documents'] as List)
              .map((e) => HealthWorkerDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'user_id': userId,
      'worker_type': workerType.dbValue,
      'is_person_in_charge': isPersonInCharge,
      'is_active': isActive,
      'on_duty_status': onDutyStatus.dbValue,
      'full_name': fullName,
      'title_degree': titleDegree,
      'specialization': specialization,
      'str_number': strNumber,
      'str_expiry': strExpiry?.toIso8601String().split('T').first,
      'sip_number': sipNumber,
      'sip_expiry': sipExpiry?.toIso8601String().split('T').first,
    };
  }

  HealthWorkerModel copyWith({
    String? id,
    String? clinicId,
    String? userId,
    HealthWorkerType? workerType,
    bool? isPersonInCharge,
    bool? isActive,
    DutyStatus? onDutyStatus,
    String? fullName,
    String? titleDegree,
    String? specialization,
    String? strNumber,
    DateTime? strExpiry,
    String? sipNumber,
    DateTime? sipExpiry,
    HealthWorkerPrivateModel? privateData,
    List<HealthWorkerEducationModel>? educations,
    List<HealthWorkerExperienceModel>? experiences,
    List<HealthWorkerCertificateModel>? certificates,
    List<HealthWorkerDocumentModel>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthWorkerModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      workerType: workerType ?? this.workerType,
      isPersonInCharge: isPersonInCharge ?? this.isPersonInCharge,
      isActive: isActive ?? this.isActive,
      onDutyStatus: onDutyStatus ?? this.onDutyStatus,
      fullName: fullName ?? this.fullName,
      titleDegree: titleDegree ?? this.titleDegree,
      specialization: specialization ?? this.specialization,
      strNumber: strNumber ?? this.strNumber,
      strExpiry: strExpiry ?? this.strExpiry,
      sipNumber: sipNumber ?? this.sipNumber,
      sipExpiry: sipExpiry ?? this.sipExpiry,
      privateData: privateData ?? this.privateData,
      educations: educations ?? this.educations,
      experiences: experiences ?? this.experiences,
      certificates: certificates ?? this.certificates,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HealthWorkerPrivateModel {
  const HealthWorkerPrivateModel({
    required this.workerId,
    required this.clinicId,
    this.phone,
    this.email,
    this.nik,
    this.npwp,
    this.homeAddress,
    this.birthDate,
    this.createdAt,
    this.updatedAt,
  });

  final String workerId;
  final String clinicId;
  final String? phone;
  final String? email;
  final String? nik;
  final String? npwp;
  final String? homeAddress;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HealthWorkerPrivateModel.fromJson(Map<String, dynamic> json) {
    return HealthWorkerPrivateModel(
      workerId: json['worker_id'] as String,
      clinicId: json['clinic_id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      nik: json['nik'] as String?,
      npwp: json['npwp'] as String?,
      homeAddress: json['home_address'] as String?,
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worker_id': workerId,
      'clinic_id': clinicId,
      'phone': phone,
      'email': email,
      'nik': nik,
      'npwp': npwp,
      'home_address': homeAddress,
      'birth_date': birthDate?.toIso8601String().split('T').first,
    };
  }

  HealthWorkerPrivateModel copyWith({
    String? workerId,
    String? clinicId,
    String? phone,
    String? email,
    String? nik,
    String? npwp,
    String? homeAddress,
    DateTime? birthDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthWorkerPrivateModel(
      workerId: workerId ?? this.workerId,
      clinicId: clinicId ?? this.clinicId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nik: nik ?? this.nik,
      npwp: npwp ?? this.npwp,
      homeAddress: homeAddress ?? this.homeAddress,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HealthWorkerEducationModel {
  const HealthWorkerEducationModel({
    required this.id,
    required this.workerId,
    required this.clinicId,
    required this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startYear,
    this.endYear,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workerId;
  final String clinicId;
  final String institution;
  final String? degree;
  final String? fieldOfStudy;
  final int? startYear;
  final int? endYear;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HealthWorkerEducationModel.fromJson(Map<String, dynamic> json) {
    return HealthWorkerEducationModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      clinicId: json['clinic_id'] as String,
      institution: json['institution'] as String,
      degree: json['degree'] as String?,
      fieldOfStudy: json['field_of_study'] as String?,
      startYear: (json['start_year'] as num?)?.toInt(),
      endYear: (json['end_year'] as num?)?.toInt(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'clinic_id': clinicId,
      'institution': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_year': startYear,
      'end_year': endYear,
    };
  }
}

class HealthWorkerExperienceModel {
  const HealthWorkerExperienceModel({
    required this.id,
    required this.workerId,
    required this.clinicId,
    required this.workplace,
    this.position,
    this.startDate,
    this.endDate,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workerId;
  final String clinicId;
  final String workplace;
  final String? position;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HealthWorkerExperienceModel.fromJson(Map<String, dynamic> json) {
    return HealthWorkerExperienceModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      clinicId: json['clinic_id'] as String,
      workplace: json['workplace'] as String,
      position: json['position'] as String?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'clinic_id': clinicId,
      'workplace': workplace,
      'position': position,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'description': description,
    };
  }
}

class HealthWorkerCertificateModel {
  const HealthWorkerCertificateModel({
    required this.id,
    required this.workerId,
    required this.clinicId,
    required this.name,
    this.issuer,
    this.issuedDate,
    this.expiryDate,
    this.filePath,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workerId;
  final String clinicId;
  final String name;
  final String? issuer;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String? filePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HealthWorkerCertificateModel.fromJson(Map<String, dynamic> json) {
    return HealthWorkerCertificateModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      clinicId: json['clinic_id'] as String,
      name: json['name'] as String,
      issuer: json['issuer'] as String?,
      issuedDate: json['issued_date'] != null ? DateTime.tryParse(json['issued_date'] as String) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'] as String) : null,
      filePath: json['file_path'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'clinic_id': clinicId,
      'name': name,
      'issuer': issuer,
      'issued_date': issuedDate?.toIso8601String().split('T').first,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'file_path': filePath,
    };
  }
}

class HealthWorkerDocumentModel {
  const HealthWorkerDocumentModel({
    required this.id,
    required this.workerId,
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
  final String workerId;
  final String clinicId;
  final WorkerDocumentType docType;
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

  factory HealthWorkerDocumentModel.fromJson(Map<String, dynamic> json) {
    return HealthWorkerDocumentModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      clinicId: json['clinic_id'] as String,
      docType: WorkerDocumentType.fromDb(json['doc_type'] as String?),
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
      'worker_id': workerId,
      'clinic_id': clinicId,
      'doc_type': docType.dbValue,
      'file_path': filePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
    };
  }
}
