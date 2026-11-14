import 'models.dart';

class RegisterVisitRequest {
  const RegisterVisitRequest({
    required this.clinicId,
    required this.serviceType,
    required this.source,
    required this.visitKind,
    this.patient,
    this.scheduledAt,
    this.complaint,
    this.takeQueue = true,
    this.priority = QueuePriority.normal,
  });

  final String clinicId;
  final String serviceType;
  final VisitSource source;
  final VisitKind visitKind;
  final Map<String, dynamic>? patient;
  final DateTime? scheduledAt;
  final String? complaint;
  final bool takeQueue;
  final QueuePriority priority;
}

abstract interface class ClinicOperationsRepository {
  Future<List<Visit>> loadVisitBoard(String clinicId);
  Future<Visit> registerVisit(RegisterVisitRequest request);
  Future<Visit> takeQueue(String encounterId);
  Future<Visit> checkIn(String encounterId);
  Future<Visit> cancelVisit(String encounterId, {String? reason});
  Future<Visit> markNoShow(String encounterId);
  Future<QueueTicket?> callNext(
    String clinicId, {
    required QueueStation station,
    String? queueCode,
  });
  Future<QueueTicket> updateTicket(String ticketId, String status);
  Future<IntakeData> submitIntake(String encounterId, IntakeData data);
}

abstract interface class ClinicalRepository {
  Future<TriageRecord> recordTriage(
    String encounterId,
    TriageRecord triage, {
    bool readyForDoctor = false,
  });
  Future<void> startConsultation(String encounterId);
  Future<MedicalRecordVersion> saveMedicalRecord(
    String encounterId,
    MedicalRecordVersion version, {
    List<Map<String, dynamic>> diagnoses = const [],
    String? changeReason,
  });
  Future<void> signMedicalRecord(String encounterId);
  Future<String> issuePrescription(
    String encounterId,
    List<PrescriptionItem> items, {
    String? pharmacyNotes,
  });
  Future<Map<String, dynamic>> completeConsultation(
    String encounterId,
    Discharge discharge,
  );
  Future<IntakeData?> getIntake(String encounterId);
  Future<TriageRecord?> getTriage(String encounterId);
  Future<Vitals?> getLatestVitals(String encounterId);
  Future<MedicalRecord?> getMedicalRecord(String encounterId);
  Future<List<MedicalRecordVersion>> getMedicalRecordVersions(String recordId);
  Future<List<Prescription>> getPrescriptions(String encounterId);
  Future<Discharge?> getDischarge(String encounterId);
}

abstract interface class PatientRepository {
  Future<List<ClinicPatient>> searchPatients(String clinicId, String query,
      {int limit = 20});
  Future<ClinicPatient?> getPatient(String clinicPatientId);
  Future<List<Visit>> getPatientVisits(String clinicPatientId);
}

abstract interface class BillingRepository {
  Future<List<Invoice>> loadInvoices(String clinicId);
  Future<Invoice?> getInvoice(String invoiceId);
  Future<Map<String, dynamic>> updateInvoiceItems(
    String encounterId,
    List<InvoiceItem> items, {
    int? discount,
  });
  Future<Map<String, dynamic>> issueInvoice(String invoiceId);
  Future<Map<String, dynamic>> recordOfflinePayment(
    String invoiceId, {
    required int amount,
    required String method,
    String? note,
  });
  Future<Map<String, dynamic>> voidInvoice(
    String invoiceId, {
    required String reason,
  });
}

abstract interface class InboxRepository {
  Future<List<InboxItem>> loadInbox(String clinicId, {int limit = 50});
  Future<void> markInboxRead(List<String> ids);
}

abstract interface class EmergencyRepository {
  Future<List<EmergencyAlert>> loadEmergencyAlerts(String clinicId);
  Future<EmergencyAlert> triggerEmergencyCall(
    String clinicId, {
    Map<String, dynamic>? location,
    String? message,
  });
  Future<void> updateEmergencyAlert(
    String alertId,
    String status, {
    String? note,
  });
}

abstract interface class ClinicWorkflowRepository
    implements
        ClinicOperationsRepository,
        ClinicalRepository,
        PatientRepository,
        BillingRepository,
        InboxRepository,
        EmergencyRepository {}

class ClinicRepositoryException implements Exception {
  const ClinicRepositoryException(this.code);

  final String code;

  @override
  String toString() => 'ClinicRepositoryException($code)';
}
