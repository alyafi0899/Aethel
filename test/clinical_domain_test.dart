import 'package:clinic_operations_platform/data/models.dart' as app;
import 'package:clinic_operations_platform/domain/models.dart';
import 'package:clinic_operations_platform/domain/staff_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Visit state machine', () {
    test('allows only documented forward transitions and terminal outcomes',
        () {
      expect(
          VisitStage.registered.canTransitionTo(VisitStage.checkedIn), isTrue);
      expect(
          VisitStage.registered.canTransitionTo(VisitStage.cancelled), isTrue);
      expect(
          VisitStage.inConsultation.canTransitionTo(VisitStage.awaitingPayment),
          isTrue);
      expect(VisitStage.awaitingPayment.canTransitionTo(VisitStage.completed),
          isTrue);
      expect(VisitStage.inConsultation.canTransitionTo(VisitStage.completed),
          isFalse);
      expect(VisitStage.completed.allowedTransitions, isEmpty);
      expect(VisitStage.cancelled.allowedTransitions, isEmpty);
    });

    test('parses visit-board fields and queue ticket without clinical payloads',
        () {
      final visit = Visit.fromJson({
        'encounter_id': 'enc-1',
        'clinic_id': 'clinic-1',
        'reference': 'VIS-1001',
        'stage': 'waiting_doctor',
        'status': 'in_progress',
        'visit_kind': 'in_person',
        'source': 'reception',
        'service_type': 'Konsultasi Umum',
        'triage_priority': 'priority',
        'has_red_flag': true,
        'patient_name': 'Pasien Contoh',
        'medical_record_no': 'RM-000001',
        'minutes_in_stage': 8,
        'ticket': {
          'ticket_id': 'ticket-1',
          'display_code': 'U-001',
          'number': 1,
          'station': 'doctor',
          'status': 'called',
          'priority': 'priority',
        },
      });

      expect(visit.encounterId, 'enc-1');
      expect(visit.stage, VisitStage.waitingDoctor);
      expect(visit.triagePriority, TriageLevel.priority);
      expect(visit.ticket?.displayCode, 'U-001');
      expect(visit.toJson()['stage'], 'waiting_doctor');
      expect(visit.toJson()['ticket']['station'], 'doctor');
    });

    test('unknown enum values use documented safe defaults', () {
      expect(VisitStage.fromDb('unknown'), VisitStage.registered);
      expect(VisitKind.fromDb('unknown'), VisitKind.inPerson);
      expect(QueueStation.fromDb('unknown'), QueueStation.screening);
      expect(InvoiceState.fromDb('unknown'), InvoiceState.draft);
    });
  });

  group('Clinical and billing mappers', () {
    test('round-trips intake, vitals, and triage data', () {
      final intake = IntakeData.fromJson({
        'chief_complaint': 'Sakit kepala',
        'symptom_category': 'neurologi',
        'duration_text': '2 hari',
        'onset': 'bertahap',
        'pain_assessment': {'severity': 4},
        'medical_history': 'Migrain',
        'medication_allergies': 'Tidak ada',
        'additional_notes': 'Catatan',
      });
      final triage = TriageRecord.fromJson({
        'priority': 'urgent',
        'red_flag': true,
        'red_flag_reasons': ['Nyeri berat'],
        'notes': 'Perlu diperiksa',
        'disposition': 'doctor',
        'vitals': {
          'bp_systolic': 120,
          'bp_diastolic': 80,
          'heart_rate': 72,
          'spo2': 98,
          'temperature_c': 36.6,
        },
      });

      expect(
          IntakeData.fromJson(intake.toJson()).chiefComplaint, 'Sakit kepala');
      expect(triage.priority, TriageLevel.urgent);
      expect(triage.redFlagReasons, ['Nyeri berat']);
      expect(triage.vitals?.temperatureC, 36.6);
      expect(Vitals.fromJson(triage.vitals!.toJson()).spo2, 98);
    });

    test('maps invoices and nested payment records', () {
      final invoice = Invoice.fromJson({
        'id': 'invoice-1',
        'clinic_id': 'clinic-1',
        'encounter_id': 'enc-1',
        'reference': 'INV-1001',
        'status': 'issued',
        'subtotal': 120000,
        'discount': 10000,
        'total': 110000,
        'visit_invoice_items': [
          {
            'description': 'Konsultasi',
            'quantity': 1,
            'unit_price': 120000,
            'item_type': 'service',
          }
        ],
        'visit_payments': [
          {
            'id': 'payment-1',
            'invoice_id': 'invoice-1',
            'amount': 50000,
            'method': 'cash',
            'status': 'succeeded',
            'provider': 'manual',
          }
        ],
      });

      expect(invoice.status, InvoiceState.issued);
      expect(invoice.total, 110000);
      expect(invoice.items.single.description, 'Konsultasi');
      expect(invoice.payments.single.amount, 50000);
      expect(invoice.toJson()['visit_payments'], hasLength(1));
    });
  });

  group('Staff access policy', () {
    test('separates clinical read, doctor, queue, and billing permissions', () {
      const nurse = StaffAccess(
        clinicId: 'clinic-1',
        userId: 'user-1',
        role: 'nurse',
        clinicalAccess: false,
      );
      const restrictedAdmin = StaffAccess(
        clinicId: 'clinic-1',
        userId: 'user-2',
        role: 'admin',
        clinicalAccess: false,
      );
      const clinicalAdmin = StaffAccess(
        clinicId: 'clinic-1',
        userId: 'user-3',
        role: 'admin',
        clinicalAccess: true,
      );
      const cashier = StaffAccess(
        clinicId: 'clinic-1',
        userId: 'user-4',
        role: 'cashier',
        clinicalAccess: false,
      );

      expect(nurse.canViewClinical, isTrue);
      expect(nurse.canRecordTriage, isTrue);
      expect(nurse.canActAsDoctor, isFalse);
      expect(restrictedAdmin.canViewClinical, isFalse);
      expect(clinicalAdmin.canActAsDoctor, isTrue);
      expect(cashier.canManageBilling, isTrue);
      expect(cashier.canViewClinical, isFalse);
    });
  });

  test('empty live data has no demonstration patient or clinic records', () {
    final data = app.ClinicData.empty(
      facilityName: 'Klinik Uji',
      userName: 'Pengguna Uji',
      userInitials: 'PU',
      userRole: 'owner',
    );

    expect(data.appointments, isEmpty);
    expect(data.screenings, isEmpty);
    expect(data.patients, isEmpty);
    expect(data.invoices, isEmpty);
    expect(data.facilityName, 'Klinik Uji');
  });
}
