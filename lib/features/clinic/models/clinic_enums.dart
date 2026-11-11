enum ClinicStatus {
  draft('draft', 'Draf'),
  submitted('submitted', 'Telah Dikirim'),
  under_review('under_review', 'Dalam Peninjauan'),
  verified('verified', 'Terverifikasi'),
  rejected('rejected', 'Ditolak'),
  suspended('suspended', 'Ditangguhkan');

  const ClinicStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static ClinicStatus fromDb(String? value) {
    return ClinicStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ClinicStatus.draft,
    );
  }
}

enum ClinicRole {
  owner('owner', 'Pemilik Utama'),
  admin('admin', 'Administrator Klinik');

  const ClinicRole(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static ClinicRole fromDb(String? value) {
    return ClinicRole.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ClinicRole.admin,
    );
  }
}

enum LegalEntityType {
  individual('individual', 'Perorangan / Dokter Mandiri'),
  pt('pt', 'Perseroan Terbatas (PT)'),
  foundation('foundation', 'Yayasan'),
  other('other', 'Lainnya');

  const LegalEntityType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static LegalEntityType? fromDb(String? value) {
    if (value == null) return null;
    return LegalEntityType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => LegalEntityType.other,
    );
  }
}

enum FacilityKind {
  waiting_room('waiting_room', 'Ruang Tunggu'),
  treatment_room('treatment_room', 'Ruang Tindakan'),
  consultation_room('consultation_room', 'Ruang Konsultasi'),
  laboratory('laboratory', 'Laboratorium'),
  pharmacy('pharmacy', 'Apotek / Farmasi'),
  registration('registration', 'Pendaftaran / Kasir'),
  other('other', 'Fasilitas Lain');

  const FacilityKind(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static FacilityKind fromDb(String? value) {
    return FacilityKind.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => FacilityKind.consultation_room,
    );
  }
}

enum FacilityUnitStatus {
  available('available', 'Tersedia'),
  occupied('occupied', 'Terpakai'),
  maintenance('maintenance', 'Pemeliharaan');

  const FacilityUnitStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static FacilityUnitStatus fromDb(String? value) {
    return FacilityUnitStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => FacilityUnitStatus.available,
    );
  }
}

enum EquipmentCategory {
  medical('medical', 'Peralatan Medis'),
  non_medical('non_medical', 'Peralatan Non-Medis');

  const EquipmentCategory(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static EquipmentCategory fromDb(String? value) {
    return EquipmentCategory.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => EquipmentCategory.medical,
    );
  }
}

enum DocumentType {
  sio('sio', 'Surat Izin Operasional (SIO)'),
  npwp('npwp', 'NPWP Klinik'),
  fasyankes_registration('fasyankes_registration', 'Bukti Registrasi Fasyankes'),
  deed_of_establishment('deed_of_establishment', 'Akta Pendirian (PT/Yayasan)'),
  registration_request_letter('registration_request_letter', 'Surat Permohonan Registrasi'),
  quality_commitment_statement('quality_commitment_statement', 'Surat Komitmen Mutu'),
  bpjs_cooperation_proof('bpjs_cooperation_proof', 'Bukti Kerjasama BPJS'),
  org_structure('org_structure', 'Dokumen Struktur Organisasi'),
  service_sop('service_sop', 'SOP Layanan Klinik'),
  clinic_photo('clinic_photo', 'Foto Fisik Klinik'),
  educational_poster('educational_poster', 'Poster Edukasi Kesehatan'),
  other('other', 'Dokumen Pendukung Lain');

  const DocumentType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static DocumentType fromDb(String? value) {
    return DocumentType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => DocumentType.other,
    );
  }
}

enum WorkerDocumentType {
  profile_photo('profile_photo', 'Foto Formal Pasfoto'),
  ktp_scan('ktp_scan', 'Scan KTP'),
  str_scan('str_scan', 'Scan STR Aktif'),
  sip_scan('sip_scan', 'Scan SIP Aktif'),
  diploma_scan('diploma_scan', 'Scan Ijazah Kedokteran/Keperawatan'),
  competency_certificate_scan('competency_certificate_scan', 'Sertifikat Kompetensi'),
  other('other', 'Dokumen Lain');

  const WorkerDocumentType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static WorkerDocumentType fromDb(String? value) {
    return WorkerDocumentType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => WorkerDocumentType.other,
    );
  }
}

enum DocumentReviewStatus {
  pending('pending', 'Menunggu Peninjauan'),
  approved('approved', 'Disetujui'),
  rejected('rejected', 'Ditolak');

  const DocumentReviewStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static DocumentReviewStatus fromDb(String? value) {
    return DocumentReviewStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => DocumentReviewStatus.pending,
    );
  }
}

enum HealthWorkerType {
  doctor('doctor', 'Dokter'),
  nurse('nurse', 'Perawat / Bidan');

  const HealthWorkerType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static HealthWorkerType fromDb(String? value) {
    return HealthWorkerType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => HealthWorkerType.doctor,
    );
  }
}

enum DutyStatus {
  available('available', 'Tersedia bertugas'),
  busy('busy', 'Sedang melayani pasien'),
  off('off', 'Tidak bertugas / Libur');

  const DutyStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static DutyStatus fromDb(String? value) {
    return DutyStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => DutyStatus.off,
    );
  }
}

enum QueueProcessStatus {
  active('active', 'Aktif Memproses'),
  paused('paused', 'Diistirahatkan (Jeda)'),
  closed('closed', 'Antrean Ditutup');

  const QueueProcessStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static QueueProcessStatus fromDb(String? value) {
    return QueueProcessStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => QueueProcessStatus.closed,
    );
  }
}

enum FacilityOperatingStatus {
  open('open', 'Buka Operasional'),
  closed('closed', 'Tutup'),
  maintenance('maintenance', 'Pemeliharaan / Maintenance');

  const FacilityOperatingStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static FacilityOperatingStatus fromDb(String? value) {
    return FacilityOperatingStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => FacilityOperatingStatus.closed,
    );
  }
}

enum EmrAppType {
  internal('internal', 'Sistem Prometheon RME Internal'),
  third_party('third_party', 'Aplikasi RME Pihak Ketiga'),
  none('none', 'Belum Ada Aplikasi RME');

  const EmrAppType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static EmrAppType fromDb(String? value) {
    return EmrAppType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => EmrAppType.none,
    );
  }
}
