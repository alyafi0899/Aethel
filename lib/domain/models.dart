enum VisitStage {
  registered,
  queued,
  checkedIn,
  screening,
  triage,
  waitingDoctor,
  inConsultation,
  awaitingPayment,
  completed,
  cancelled,
  noShow;

  String get dbValue => switch (this) {
        VisitStage.registered => 'registered',
        VisitStage.queued => 'queued',
        VisitStage.checkedIn => 'checked_in',
        VisitStage.screening => 'screening',
        VisitStage.triage => 'triage',
        VisitStage.waitingDoctor => 'waiting_doctor',
        VisitStage.inConsultation => 'in_consultation',
        VisitStage.awaitingPayment => 'awaiting_payment',
        VisitStage.completed => 'completed',
        VisitStage.cancelled => 'cancelled',
        VisitStage.noShow => 'no_show',
      };

  String get label => switch (this) {
        VisitStage.registered => 'Terdaftar',
        VisitStage.queued => 'Mengantre',
        VisitStage.checkedIn => 'Check-in',
        VisitStage.screening => 'Skrining',
        VisitStage.triage => 'Triase',
        VisitStage.waitingDoctor => 'Menunggu dokter',
        VisitStage.inConsultation => 'Pemeriksaan',
        VisitStage.awaitingPayment => 'Menunggu pembayaran',
        VisitStage.completed => 'Selesai',
        VisitStage.cancelled => 'Dibatalkan',
        VisitStage.noShow => 'Tidak hadir',
      };

  Set<VisitStage> get allowedTransitions => switch (this) {
        VisitStage.registered => {
            VisitStage.queued,
            VisitStage.checkedIn,
            VisitStage.cancelled,
            VisitStage.noShow,
          },
        VisitStage.queued => {
            VisitStage.checkedIn,
            VisitStage.screening,
            VisitStage.cancelled,
            VisitStage.noShow,
          },
        VisitStage.checkedIn => {
            VisitStage.screening,
            VisitStage.triage,
            VisitStage.waitingDoctor,
            VisitStage.cancelled,
          },
        VisitStage.screening => {
            VisitStage.triage,
            VisitStage.waitingDoctor,
            VisitStage.cancelled,
          },
        VisitStage.triage => {VisitStage.waitingDoctor, VisitStage.cancelled},
        VisitStage.waitingDoctor => {
            VisitStage.inConsultation,
            VisitStage.cancelled,
          },
        VisitStage.inConsultation => {VisitStage.awaitingPayment},
        VisitStage.awaitingPayment => {VisitStage.completed},
        VisitStage.completed || VisitStage.cancelled || VisitStage.noShow => {},
      };

  bool canTransitionTo(VisitStage next) => allowedTransitions.contains(next);

  static VisitStage fromDb(String? value) => _enumFromDb(
        values,
        value,
        (stage) => stage.dbValue,
        VisitStage.registered,
      );
}

enum VisitKind {
  inPerson('in_person', 'Kunjungan langsung'),
  onlineScheduled('online_scheduled', 'Online terjadwal'),
  directAsk('direct_ask', 'Tanya Dokter');

  const VisitKind(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static VisitKind fromDb(String? value) =>
      _enumFromDb(values, value, (item) => item.dbValue, VisitKind.inPerson);
}

enum VisitSource {
  patientApp('patient_app'),
  walkIn('walk_in'),
  reception('reception'),
  referral('referral'),
  telehealth('telehealth');

  const VisitSource(this.dbValue);
  final String dbValue;

  static VisitSource fromDb(String? value) =>
      _enumFromDb(values, value, (item) => item.dbValue, VisitSource.reception);
}

enum QueuePriority {
  emergency('emergency', 'Darurat'),
  priority('priority', 'Prioritas'),
  normal('normal', 'Rutin');

  const QueuePriority(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static QueuePriority fromDb(String? value) =>
      _enumFromDb(values, value, (item) => item.dbValue, QueuePriority.normal);
}

enum QueueStation {
  screening('screening', 'Skrining'),
  doctor('doctor', 'Dokter'),
  cashier('cashier', 'Kasir');

  const QueueStation(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static QueueStation fromDb(String? value) => _enumFromDb(
      values, value, (item) => item.dbValue, QueueStation.screening);
}

enum TriageLevel {
  urgent('urgent', 'Segera'),
  priority('priority', 'Prioritas'),
  routine('routine', 'Rutin');

  const TriageLevel(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static TriageLevel fromDb(String? value) =>
      _enumFromDb(values, value, (item) => item.dbValue, TriageLevel.routine);
}

enum InvoiceState {
  draft('draft', 'Draf'),
  issued('issued', 'Terbit'),
  processing('processing', 'Menunggu konfirmasi penyedia'),
  paid('paid', 'Lunas'),
  failed('failed', 'Gagal'),
  voided('void', 'Dibatalkan'),
  refunded('refunded', 'Dikembalikan');

  const InvoiceState(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static InvoiceState fromDb(String? value) =>
      _enumFromDb(values, value, (item) => item.dbValue, InvoiceState.draft);
}

T _enumFromDb<T>(
  List<T> values,
  String? value,
  String Function(T item) dbValue,
  T fallback,
) {
  for (final item in values) {
    if (dbValue(item) == value) return item;
  }
  return fallback;
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

class Visit {
  const Visit({
    required this.encounterId,
    required this.clinicId,
    required this.stage,
    this.reference,
    this.status,
    this.serviceType,
    this.source = VisitSource.reception,
    this.kind = VisitKind.inPerson,
    this.triagePriority,
    this.hasRedFlag = false,
    this.ticket,
    this.clinicPatientId,
    this.patientName,
    this.medicalRecordNo,
    this.scheduledAt,
    this.registeredAt,
    this.stageChangedAt,
    this.minutesInStage = 0,
    this.practitionerName,
    this.invoiceStatus,
    this.invoiceTotal,
  });

  final String encounterId;
  final String clinicId;
  final String? reference;
  final VisitStage stage;
  final String? status;
  final String? serviceType;
  final VisitSource source;
  final VisitKind kind;
  final TriageLevel? triagePriority;
  final bool hasRedFlag;
  final QueueTicket? ticket;
  final String? clinicPatientId;
  final String? patientName;
  final String? medicalRecordNo;
  final DateTime? scheduledAt;
  final DateTime? registeredAt;
  final DateTime? stageChangedAt;
  final int minutesInStage;
  final String? practitionerName;
  final InvoiceState? invoiceStatus;
  final int? invoiceTotal;

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        encounterId:
            json['encounter_id']?.toString() ?? json['id']?.toString() ?? '',
        clinicId: json['clinic_id']?.toString() ?? '',
        reference: json['reference']?.toString(),
        stage: VisitStage.fromDb(json['stage']?.toString()),
        status: json['status']?.toString(),
        serviceType: json['service_type']?.toString(),
        source: VisitSource.fromDb(json['source']?.toString()),
        kind: VisitKind.fromDb(
          (json['visit_kind'] ?? json['kind'])?.toString(),
        ),
        triagePriority: json['triage_priority'] == null
            ? null
            : TriageLevel.fromDb(json['triage_priority'].toString()),
        hasRedFlag: json['has_red_flag'] == true,
        ticket: json['ticket'] is Map
            ? QueueTicket.fromJson(_map(json['ticket']))
            : null,
        clinicPatientId: json['clinic_patient_id']?.toString(),
        patientName: json['patient_name']?.toString(),
        medicalRecordNo: json['medical_record_no']?.toString(),
        scheduledAt: _dateTime(json['scheduled_at']),
        registeredAt: _dateTime(json['registered_at'] ?? json['created_at']),
        stageChangedAt: _dateTime(json['stage_changed_at']),
        minutesInStage: (json['minutes_in_stage'] as num?)?.toInt() ?? 0,
        practitionerName: json['practitioner_name']?.toString(),
        invoiceStatus: json['invoice_status'] == null
            ? null
            : InvoiceState.fromDb(json['invoice_status'].toString()),
        invoiceTotal: (json['invoice_total'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'encounter_id': encounterId,
        'clinic_id': clinicId,
        'reference': reference,
        'stage': stage.dbValue,
        'status': status,
        'service_type': serviceType,
        'source': source.dbValue,
        'visit_kind': kind.dbValue,
        'triage_priority': triagePriority?.dbValue,
        'has_red_flag': hasRedFlag,
        'ticket': ticket?.toJson(),
        'clinic_patient_id': clinicPatientId,
        'patient_name': patientName,
        'medical_record_no': medicalRecordNo,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'registered_at': registeredAt?.toIso8601String(),
        'stage_changed_at': stageChangedAt?.toIso8601String(),
        'minutes_in_stage': minutesInStage,
        'practitioner_name': practitionerName,
        'invoice_status': invoiceStatus?.dbValue,
        'invoice_total': invoiceTotal,
      };
}

class QueueTicket {
  const QueueTicket({
    required this.ticketId,
    required this.displayCode,
    required this.number,
    required this.station,
    required this.status,
    required this.priority,
    this.aheadCount = 0,
    this.estimatedWaitMin = 0,
    this.nowServing,
    this.encounterId,
  });

  final String ticketId;
  final String displayCode;
  final int number;
  final QueueStation station;
  final String status;
  final QueuePriority priority;
  final int aheadCount;
  final int estimatedWaitMin;
  final String? nowServing;
  final String? encounterId;

  factory QueueTicket.fromJson(Map<String, dynamic> json) => QueueTicket(
        ticketId: (json['ticket_id'] ?? json['id'])?.toString() ?? '',
        displayCode:
            (json['display_code'] ?? json['ticket_code'])?.toString() ?? '',
        number: (json['number'] as num?)?.toInt() ?? 0,
        station: QueueStation.fromDb(
          (json['station'] ?? json['ticket_station'])?.toString(),
        ),
        status: (json['status'] ?? json['ticket_status'])?.toString() ?? '',
        priority: QueuePriority.fromDb(
          (json['priority'] ?? json['ticket_priority'])?.toString(),
        ),
        aheadCount: (json['ahead_count'] as num?)?.toInt() ?? 0,
        estimatedWaitMin: (json['estimated_wait_min'] as num?)?.toInt() ?? 0,
        nowServing: json['now_serving']?.toString(),
        encounterId: json['encounter_id']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'ticket_id': ticketId,
        'display_code': displayCode,
        'number': number,
        'station': station.dbValue,
        'status': status,
        'priority': priority.dbValue,
        'ahead_count': aheadCount,
        'estimated_wait_min': estimatedWaitMin,
        'now_serving': nowServing,
        'encounter_id': encounterId,
      };
}

class ClinicPatient {
  const ClinicPatient({
    required this.id,
    required this.clinicId,
    required this.medicalRecordNo,
    required this.fullName,
    this.userId,
    this.gender,
    this.birthDate,
    this.phone,
    this.registrationStatus = 'registered',
    this.createdAt,
  });

  final String id;
  final String clinicId;
  final String medicalRecordNo;
  final String fullName;
  final String? userId;
  final String? gender;
  final DateTime? birthDate;
  final String? phone;
  final String registrationStatus;
  final DateTime? createdAt;

  factory ClinicPatient.fromJson(Map<String, dynamic> json) => ClinicPatient(
        id: json['id']?.toString() ?? '',
        clinicId: json['clinic_id']?.toString() ?? '',
        medicalRecordNo: json['medical_record_no']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        userId: json['user_id']?.toString(),
        gender: json['gender']?.toString(),
        birthDate: _dateTime(json['birth_date']),
        phone: json['phone']?.toString(),
        registrationStatus:
            json['registration_status']?.toString() ?? 'registered',
        createdAt: _dateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinic_id': clinicId,
        'medical_record_no': medicalRecordNo,
        'full_name': fullName,
        'user_id': userId,
        'gender': gender,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'phone': phone,
        'registration_status': registrationStatus,
        'created_at': createdAt?.toIso8601String(),
      };
}

class IntakeData {
  const IntakeData({
    this.chiefComplaint,
    this.symptomCategory,
    this.durationText,
    this.onset,
    this.painAssessment = const {},
    this.medicalHistory,
    this.medicationAllergies,
    this.additionalNotes,
  });

  final String? chiefComplaint;
  final String? symptomCategory;
  final String? durationText;
  final String? onset;
  final Map<String, dynamic> painAssessment;
  final String? medicalHistory;
  final String? medicationAllergies;
  final String? additionalNotes;

  factory IntakeData.fromJson(Map<String, dynamic> json) => IntakeData(
        chiefComplaint: json['chief_complaint']?.toString(),
        symptomCategory: json['symptom_category']?.toString(),
        durationText: json['duration_text']?.toString(),
        onset: json['onset']?.toString(),
        painAssessment: _map(json['pain_assessment']),
        medicalHistory: json['medical_history']?.toString(),
        medicationAllergies: json['medication_allergies']?.toString(),
        additionalNotes: json['additional_notes']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'chief_complaint': chiefComplaint,
        'symptom_category': symptomCategory,
        'duration_text': durationText,
        'onset': onset,
        'pain_assessment': painAssessment,
        'medical_history': medicalHistory,
        'medication_allergies': medicationAllergies,
        'additional_notes': additionalNotes,
      };
}

class Vitals {
  const Vitals({
    this.bpSystolic,
    this.bpDiastolic,
    this.heartRate,
    this.spo2,
    this.temperatureC,
    this.respRate,
    this.weightKg,
    this.heightCm,
  });

  final int? bpSystolic;
  final int? bpDiastolic;
  final int? heartRate;
  final int? spo2;
  final double? temperatureC;
  final int? respRate;
  final double? weightKg;
  final double? heightCm;

  factory Vitals.fromJson(Map<String, dynamic> json) => Vitals(
        bpSystolic: (json['bp_systolic'] as num?)?.toInt(),
        bpDiastolic: (json['bp_diastolic'] as num?)?.toInt(),
        heartRate: (json['heart_rate'] as num?)?.toInt(),
        spo2: (json['spo2'] as num?)?.toInt(),
        temperatureC: (json['temperature_c'] as num?)?.toDouble(),
        respRate: (json['resp_rate'] as num?)?.toInt(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'heart_rate': heartRate,
        'spo2': spo2,
        'temperature_c': temperatureC,
        'resp_rate': respRate,
        'weight_kg': weightKg,
        'height_cm': heightCm,
      };
}

class TriageRecord {
  const TriageRecord({
    required this.priority,
    this.redFlag = false,
    this.redFlagReasons = const [],
    this.notes,
    this.disposition,
    this.vitals,
  });

  final TriageLevel priority;
  final bool redFlag;
  final List<String> redFlagReasons;
  final String? notes;
  final String? disposition;
  final Vitals? vitals;

  factory TriageRecord.fromJson(Map<String, dynamic> json) => TriageRecord(
        priority: TriageLevel.fromDb(json['priority']?.toString()),
        redFlag: json['red_flag'] == true,
        redFlagReasons: (json['red_flag_reasons'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
        notes: json['notes']?.toString(),
        disposition: json['disposition']?.toString(),
        vitals: json['vitals'] is Map
            ? Vitals.fromJson(_map(json['vitals']))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'priority': priority.dbValue,
        'red_flag': redFlag,
        'red_flag_reasons': redFlagReasons,
        'notes': notes,
        'disposition': disposition,
        'vitals': vitals?.toJson(),
      };
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.encounterId,
    this.status = 'draft',
    this.currentVersion = 0,
    this.signedVersion,
    this.signedBy,
    this.signedAt,
  });

  final String id;
  final String encounterId;
  final String status;
  final int currentVersion;
  final int? signedVersion;
  final String? signedBy;
  final DateTime? signedAt;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
        id: json['id']?.toString() ?? '',
        encounterId: json['encounter_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'draft',
        currentVersion: (json['current_version'] as num?)?.toInt() ?? 0,
        signedVersion: (json['signed_version'] as num?)?.toInt(),
        signedBy: json['signed_by']?.toString(),
        signedAt: _dateTime(json['signed_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'encounter_id': encounterId,
        'status': status,
        'current_version': currentVersion,
        'signed_version': signedVersion,
        'signed_by': signedBy,
        'signed_at': signedAt?.toIso8601String(),
      };
}

class MedicalRecordVersion {
  const MedicalRecordVersion({
    required this.recordId,
    required this.version,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.diagnoses = const [],
    this.supportingTests = const [],
    this.doctorNotes,
    this.authoredBy,
    this.changeReason,
    this.createdAt,
  });

  final String recordId;
  final int version;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final List<Map<String, dynamic>> diagnoses;
  final List<dynamic> supportingTests;
  final String? doctorNotes;
  final String? authoredBy;
  final String? changeReason;
  final DateTime? createdAt;

  factory MedicalRecordVersion.fromJson(Map<String, dynamic> json) =>
      MedicalRecordVersion(
        recordId: json['record_id']?.toString() ?? '',
        version: (json['version'] as num?)?.toInt() ?? 0,
        subjective: json['subjective']?.toString(),
        objective: json['objective']?.toString(),
        assessment: json['assessment']?.toString(),
        plan: json['plan']?.toString(),
        diagnoses: (json['diagnoses'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        supportingTests: json['supporting_tests'] as List? ?? const [],
        doctorNotes: json['doctor_notes']?.toString(),
        authoredBy: json['authored_by']?.toString(),
        changeReason: json['change_reason']?.toString(),
        createdAt: _dateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'record_id': recordId,
        'version': version,
        'subjective': subjective,
        'objective': objective,
        'assessment': assessment,
        'plan': plan,
        'diagnoses': diagnoses,
        'supporting_tests': supportingTests,
        'doctor_notes': doctorNotes,
        'authored_by': authoredBy,
        'change_reason': changeReason,
        'created_at': createdAt?.toIso8601String(),
      };
}

class PrescriptionItem {
  const PrescriptionItem({
    this.medicineId,
    required this.medicineName,
    this.dose,
    this.frequency,
    this.durationDays,
    this.quantity,
    this.instructions,
  });

  final String? medicineId;
  final String medicineName;
  final String? dose;
  final String? frequency;
  final int? durationDays;
  final int? quantity;
  final String? instructions;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        medicineId: json['medicine_id']?.toString(),
        medicineName: json['medicine_name']?.toString() ?? '',
        dose: json['dose']?.toString(),
        frequency: json['frequency']?.toString(),
        durationDays: (json['duration_days'] as num?)?.toInt(),
        quantity: (json['quantity'] as num?)?.toInt(),
        instructions: json['instructions']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'dose': dose,
        'frequency': frequency,
        'duration_days': durationDays,
        'quantity': quantity,
        'instructions': instructions,
      };
}

class Prescription {
  const Prescription({
    required this.id,
    required this.encounterId,
    this.status = 'issued',
    this.pharmacyNotes,
    this.items = const [],
    this.issuedAt,
  });

  final String id;
  final String encounterId;
  final String status;
  final String? pharmacyNotes;
  final List<PrescriptionItem> items;
  final DateTime? issuedAt;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id']?.toString() ?? '',
        encounterId: json['encounter_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'issued',
        pharmacyNotes: json['pharmacy_notes']?.toString(),
        items: (json['prescription_items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PrescriptionItem.fromJson)
            .toList(),
        issuedAt: _dateTime(json['issued_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'encounter_id': encounterId,
        'status': status,
        'pharmacy_notes': pharmacyNotes,
        'prescription_items': items.map((item) => item.toJson()).toList(),
        'issued_at': issuedAt?.toIso8601String(),
      };
}

class Discharge {
  const Discharge({
    required this.encounterId,
    this.summary,
    this.followUpAt,
    this.followUpNote,
    this.emergencyContactInfo,
  });

  final String encounterId;
  final String? summary;
  final DateTime? followUpAt;
  final String? followUpNote;
  final String? emergencyContactInfo;

  factory Discharge.fromJson(Map<String, dynamic> json) => Discharge(
        encounterId: json['encounter_id']?.toString() ?? '',
        summary: json['summary']?.toString(),
        followUpAt: _dateTime(json['follow_up_at']),
        followUpNote: json['follow_up_note']?.toString(),
        emergencyContactInfo: json['emergency_contact_info']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'encounter_id': encounterId,
        'summary': summary,
        'follow_up_at': followUpAt?.toIso8601String(),
        'follow_up_note': followUpNote,
        'emergency_contact_info': emergencyContactInfo,
      };
}

class InvoiceItem {
  const InvoiceItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.itemType = 'manual',
  });

  final String description;
  final int quantity;
  final int unitPrice;
  final String itemType;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: json['description']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
        itemType: json['item_type']?.toString() ?? 'manual',
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'item_type': itemType,
      };
}

class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    this.status = 'succeeded',
    this.provider = 'manual',
    this.providerRef,
    this.paidAt,
  });

  final String id;
  final String invoiceId;
  final int amount;
  final String method;
  final String status;
  final String provider;
  final String? providerRef;
  final DateTime? paidAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id']?.toString() ?? '',
        invoiceId: json['invoice_id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        method: json['method']?.toString() ?? '',
        status: json['status']?.toString() ?? 'succeeded',
        provider: json['provider']?.toString() ?? 'manual',
        providerRef: json['provider_ref']?.toString(),
        paidAt: _dateTime(json['paid_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoice_id': invoiceId,
        'amount': amount,
        'method': method,
        'status': status,
        'provider': provider,
        'provider_ref': providerRef,
        'paid_at': paidAt?.toIso8601String(),
      };
}

class Invoice {
  const Invoice({
    required this.id,
    required this.clinicId,
    required this.encounterId,
    required this.reference,
    this.status = InvoiceState.draft,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.items = const [],
    this.payments = const [],
  });

  final String id;
  final String clinicId;
  final String encounterId;
  final String reference;
  final InvoiceState status;
  final int subtotal;
  final int discount;
  final int total;
  final List<InvoiceItem> items;
  final List<Payment> payments;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id']?.toString() ?? '',
        clinicId: json['clinic_id']?.toString() ?? '',
        encounterId: json['encounter_id']?.toString() ?? '',
        reference: json['reference']?.toString() ?? '',
        status: InvoiceState.fromDb(json['status']?.toString()),
        subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        items: (json['visit_invoice_items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(InvoiceItem.fromJson)
            .toList(),
        payments: (json['visit_payments'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Payment.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinic_id': clinicId,
        'encounter_id': encounterId,
        'reference': reference,
        'status': status.dbValue,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'visit_invoice_items': items.map((item) => item.toJson()).toList(),
        'visit_payments': payments.map((payment) => payment.toJson()).toList(),
      };
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.clinicId,
    required this.kind,
    required this.severity,
    required this.title,
    this.body,
    this.encounterId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String clinicId;
  final String kind;
  final String severity;
  final String title;
  final String? body;
  final String? encounterId;
  final bool isRead;
  final DateTime? createdAt;

  factory InboxItem.fromJson(Map<String, dynamic> json) => InboxItem(
        id: json['id']?.toString() ?? '',
        clinicId: json['clinic_id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        severity: json['severity']?.toString() ?? 'info',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString(),
        encounterId: json['encounter_id']?.toString(),
        isRead: json['is_read'] == true,
        createdAt: _dateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinic_id': clinicId,
        'kind': kind,
        'severity': severity,
        'title': title,
        'body': body,
        'encounter_id': encounterId,
        'is_read': isRead,
        'created_at': createdAt?.toIso8601String(),
      };
}

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.clinicId,
    required this.status,
    this.patientName,
    this.patientPhone,
    this.location,
    this.message,
    this.createdAt,
  });

  final String id;
  final String clinicId;
  final String status;
  final String? patientName;
  final String? patientPhone;
  final Map<String, dynamic>? location;
  final String? message;
  final DateTime? createdAt;

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => EmergencyAlert(
        id: json['id']?.toString() ?? '',
        clinicId: json['clinic_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'open',
        patientName: json['patient_name']?.toString(),
        patientPhone: json['patient_phone']?.toString(),
        location: json['location'] is Map ? _map(json['location']) : null,
        message: json['message']?.toString(),
        createdAt: _dateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinic_id': clinicId,
        'status': status,
        'patient_name': patientName,
        'patient_phone': patientPhone,
        'location': location,
        'message': message,
        'created_at': createdAt?.toIso8601String(),
      };
}
