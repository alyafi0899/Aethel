import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/clinic_repositories.dart';
import '../../domain/models.dart';

class SupabaseClinicalRepository implements ClinicWorkflowRepository {
  SupabaseClinicalRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<dynamic> _rpc(
    String function, [
    Map<String, dynamic> params = const {},
  ]) async {
    try {
      return await _client.rpc(function, params: params);
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  String _safeErrorCode(PostgrestException error) {
    const allowed = {
      'not_authenticated',
      'not_authorized',
      'clinic_not_found',
      'visit_not_found',
      'patient_required',
      'patient_not_found',
      'patient_name_required',
      'service_type_required',
      'invalid_visit_kind',
      'invalid_priority',
      'invalid_source',
      'clinic_not_available',
      'queue_closed',
      'active_visit_exists',
      'invalid_stage_transition',
      'cannot_cancel_now',
      'visit_closed',
      'invalid_station',
      'ticket_not_found',
      'invalid_ticket_transition',
      'practitioner_not_linked',
      'invalid_stage_for_record',
      'diagnoses_must_be_array',
      'change_reason_required',
      'record_required',
      'record_not_signed',
      'items_required',
      'medicine_name_required',
      'invalid_stage_for_prescription',
      'immutable_record',
      'invoice_not_found',
      'invoice_not_editable',
      'invoice_not_payable',
      'invoice_not_voidable',
      'invoice_has_payments',
      'invalid_amount',
      'overpayment',
      'items_must_be_array',
      'item_description_required',
      'reason_required',
      'invalid_status',
      'too_many_alerts',
      'alert_not_found',
      'alert_closed',
    };
    final message = error.message.trim();
    return allowed.contains(message) ? message : 'operation_failed';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return const {};
  }

  List<Map<String, dynamic>> _asRows(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Visit _visit(dynamic value) => Visit.fromJson(_asMap(value));

  @override
  Future<List<Visit>> loadVisitBoard(String clinicId) async {
    try {
      final rows = await _client
          .from('clinic_visit_board')
          .select()
          .eq('clinic_id', clinicId)
          .order('registered_at', ascending: false);
      return _asRows(rows).map((row) {
        final ticketStatus = row.remove('ticket_status');
        final ticketCode = row.remove('ticket_code');
        final ticketStation = row.remove('ticket_station');
        final ticketPriority = row.remove('ticket_priority');
        if (ticketCode != null) {
          row['ticket'] = {
            'display_code': ticketCode,
            'status': ticketStatus,
            'station': ticketStation,
            'priority': ticketPriority,
          };
        }
        return Visit.fromJson(row);
      }).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<Visit> registerVisit(RegisterVisitRequest request) async => _visit(
        await _rpc('register_visit', {
          'p_clinic_id': request.clinicId,
          'p_service_type': request.serviceType,
          'p_patient': request.patient,
          'p_source': request.source.dbValue,
          'p_visit_kind': request.visitKind.dbValue,
          'p_scheduled_at': request.scheduledAt?.toIso8601String(),
          'p_complaint': request.complaint,
          'p_take_queue': request.takeQueue,
          'p_priority': request.priority.dbValue,
        }),
      );

  @override
  Future<Visit> takeQueue(String encounterId) async =>
      _visit(await _rpc('take_queue', {'p_encounter_id': encounterId}));

  @override
  Future<Visit> checkIn(String encounterId) async =>
      _visit(await _rpc('check_in_visit', {'p_encounter_id': encounterId}));

  @override
  Future<Visit> cancelVisit(String encounterId, {String? reason}) async =>
      _visit(await _rpc('cancel_visit', {
        'p_encounter_id': encounterId,
        'p_reason': reason,
      }));

  @override
  Future<Visit> markNoShow(String encounterId) async =>
      _visit(await _rpc('mark_no_show', {'p_encounter_id': encounterId}));

  @override
  Future<QueueTicket?> callNext(
    String clinicId, {
    required QueueStation station,
    String? queueCode,
  }) async {
    final result = await _rpc('queue_call_next', {
      'p_clinic_id': clinicId,
      'p_station': station.dbValue,
      'p_queue_code': queueCode,
    });
    final map = _asMap(result);
    return map.isEmpty ? null : QueueTicket.fromJson(map);
  }

  @override
  Future<QueueTicket> updateTicket(String ticketId, String status) async =>
      QueueTicket.fromJson(_asMap(await _rpc('queue_update_ticket', {
        'p_ticket_id': ticketId,
        'p_status': status,
      })));

  @override
  Future<IntakeData> submitIntake(String encounterId, IntakeData data) async {
    final result = await _rpc('submit_intake', {
      'p_encounter_id': encounterId,
      'p_data': data.toJson(),
    });
    return IntakeData.fromJson(_asMap(result));
  }

  @override
  Future<TriageRecord> recordTriage(
    String encounterId,
    TriageRecord triage, {
    bool readyForDoctor = false,
  }) async {
    await _rpc('record_triage', {
      'p_encounter_id': encounterId,
      'p_priority': triage.priority.dbValue,
      'p_notes': triage.notes,
      'p_vitals': triage.vitals?.toJson(),
      'p_red_flag': triage.redFlag,
      'p_ready_for_doctor': readyForDoctor,
    });
    return triage;
  }

  @override
  Future<void> startConsultation(String encounterId) async {
    await _rpc('consultation_start', {'p_encounter_id': encounterId});
  }

  @override
  Future<MedicalRecordVersion> saveMedicalRecord(
    String encounterId,
    MedicalRecordVersion version, {
    List<Map<String, dynamic>> diagnoses = const [],
    String? changeReason,
  }) async {
    final content = version.toJson()
      ..remove('record_id')
      ..remove('version')
      ..remove('authored_by')
      ..remove('change_reason')
      ..remove('created_at');
    final result = _asMap(await _rpc('save_medical_record', {
      'p_encounter_id': encounterId,
      'p_content': content,
      'p_diagnoses': diagnoses,
      'p_change_reason': changeReason,
    }));
    return MedicalRecordVersion(
      recordId: result['record_id']?.toString() ?? '',
      version: (result['version'] as num?)?.toInt() ?? 0,
      subjective: version.subjective,
      objective: version.objective,
      assessment: version.assessment,
      plan: version.plan,
      diagnoses: diagnoses,
      supportingTests: version.supportingTests,
      doctorNotes: version.doctorNotes,
      changeReason: changeReason,
    );
  }

  @override
  Future<void> signMedicalRecord(String encounterId) async {
    await _rpc('sign_medical_record', {'p_encounter_id': encounterId});
  }

  @override
  Future<String> issuePrescription(
    String encounterId,
    List<PrescriptionItem> items, {
    String? pharmacyNotes,
  }) async {
    final result = _asMap(await _rpc('issue_prescription', {
      'p_encounter_id': encounterId,
      'p_items': items.map((item) => item.toJson()).toList(),
      'p_pharmacy_notes': pharmacyNotes,
    }));
    return result['prescription_id']?.toString() ?? '';
  }

  @override
  Future<Map<String, dynamic>> completeConsultation(
    String encounterId,
    Discharge discharge,
  ) async =>
      _asMap(await _rpc('complete_consultation', {
        'p_encounter_id': encounterId,
        'p_discharge': discharge.toJson(),
      }));

  Future<dynamic> _singleRow(
      String table, String encounterId, String columns) async {
    try {
      return await _client
          .from(table)
          .select(columns)
          .eq('encounter_id', encounterId)
          .maybeSingle();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<IntakeData?> getIntake(String encounterId) async {
    final row = await _singleRow(
      'visit_intakes',
      encounterId,
      'chief_complaint,symptom_category,duration_text,onset,pain_assessment,medical_history,medication_allergies,additional_notes',
    );
    return row == null ? null : IntakeData.fromJson(row);
  }

  @override
  Future<TriageRecord?> getTriage(String encounterId) async {
    final row = await _singleRow(
      'visit_triage',
      encounterId,
      'priority,red_flag,red_flag_reasons,notes,disposition',
    );
    if (row == null) return null;
    final vitals = await getLatestVitals(encounterId);
    return TriageRecord.fromJson({...row, 'vitals': vitals?.toJson()});
  }

  @override
  Future<Vitals?> getLatestVitals(String encounterId) async {
    try {
      final row = await _client
          .from('visit_vitals')
          .select(
              'bp_systolic,bp_diastolic,heart_rate,spo2,temperature_c,resp_rate,weight_kg,height_cm')
          .eq('encounter_id', encounterId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : Vitals.fromJson(row);
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<MedicalRecord?> getMedicalRecord(String encounterId) async {
    final row = await _singleRow('medical_records', encounterId,
        'id,encounter_id,status,current_version,signed_version,signed_by,signed_at');
    return row == null ? null : MedicalRecord.fromJson(row);
  }

  @override
  Future<List<MedicalRecordVersion>> getMedicalRecordVersions(
      String recordId) async {
    try {
      final rows = await _client
          .from('medical_record_versions')
          .select()
          .eq('record_id', recordId)
          .order('version');
      return _asRows(rows).map(MedicalRecordVersion.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<List<Prescription>> getPrescriptions(String encounterId) async {
    try {
      final rows = await _client
          .from('prescriptions')
          .select('*,prescription_items(*)')
          .eq('encounter_id', encounterId)
          .order('issued_at', ascending: false);
      return _asRows(rows).map(Prescription.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<Discharge?> getDischarge(String encounterId) async {
    final row = await _singleRow(
      'visit_discharges',
      encounterId,
      'encounter_id,summary,follow_up_at,follow_up_note,emergency_contact_info',
    );
    return row == null ? null : Discharge.fromJson(row);
  }

  @override
  Future<List<ClinicPatient>> searchPatients(
    String clinicId,
    String query, {
    int limit = 20,
  }) async {
    try {
      var request = _client
          .from('clinic_patients')
          .select(
              'id,clinic_id,user_id,medical_record_no,full_name,gender,birth_date,phone,registration_status,created_at')
          .eq('clinic_id', clinicId);
      final normalized = query.trim();
      final boundedLimit = limit.clamp(1, 100).toInt();
      final rows = normalized.isEmpty
          ? await request.order('full_name').limit(boundedLimit)
          : await _searchPatientRows(request, normalized, boundedLimit);
      return _asRows(rows).map(ClinicPatient.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  Future<List<Map<String, dynamic>>> _searchPatientRows(
    dynamic query,
    String term,
    int limit,
  ) async {
    final escaped = term.replaceAll('%', r'\%').replaceAll('_', r'\_');
    final byName = await query
        .ilike('full_name', '%$escaped%')
        .order('full_name')
        .limit(limit);
    final byMedicalRecord = await query
        .ilike('medical_record_no', '%$escaped%')
        .order('full_name')
        .limit(limit);
    final results = <String, Map<String, dynamic>>{};
    for (final row in [..._asRows(byName), ..._asRows(byMedicalRecord)]) {
      results[row['id'].toString()] = row;
    }
    return results.values.take(limit).toList();
  }

  @override
  Future<ClinicPatient?> getPatient(String clinicPatientId) async {
    try {
      final row = await _client
          .from('clinic_patients')
          .select(
              'id,clinic_id,user_id,medical_record_no,full_name,gender,birth_date,phone,registration_status,created_at')
          .eq('id', clinicPatientId)
          .maybeSingle();
      return row == null ? null : ClinicPatient.fromJson(row);
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<List<Visit>> getPatientVisits(String clinicPatientId) async {
    try {
      final rows = await _client
          .from('clinic_visit_board')
          .select()
          .eq('clinic_patient_id', clinicPatientId)
          .order('registered_at', ascending: false);
      return _asRows(rows).map(Visit.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<List<Invoice>> loadInvoices(String clinicId) async {
    try {
      final rows = await _client
          .from('visit_invoices')
          .select('*,visit_invoice_items(*),visit_payments(*)')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false);
      return _asRows(rows).map(Invoice.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<Invoice?> getInvoice(String invoiceId) async {
    try {
      final row = await _client
          .from('visit_invoices')
          .select('*,visit_invoice_items(*),visit_payments(*)')
          .eq('id', invoiceId)
          .maybeSingle();
      return row == null ? null : Invoice.fromJson(row);
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<Map<String, dynamic>> updateInvoiceItems(
    String encounterId,
    List<InvoiceItem> items, {
    int? discount,
  }) async =>
      _asMap(await _rpc('update_invoice_items', {
        'p_encounter_id': encounterId,
        'p_items': items.map((item) => item.toJson()).toList(),
        'p_discount': discount,
      }));

  @override
  Future<Map<String, dynamic>> issueInvoice(String invoiceId) async =>
      _asMap(await _rpc('issue_invoice', {'p_invoice_id': invoiceId}));

  @override
  Future<Map<String, dynamic>> recordOfflinePayment(
    String invoiceId, {
    required int amount,
    required String method,
    String? note,
  }) async =>
      _asMap(await _rpc('record_offline_payment', {
        'p_invoice_id': invoiceId,
        'p_amount': amount,
        'p_method': method,
        'p_note': note,
      }));

  @override
  Future<Map<String, dynamic>> voidInvoice(
    String invoiceId, {
    required String reason,
  }) async =>
      _asMap(await _rpc('void_invoice', {
        'p_invoice_id': invoiceId,
        'p_reason': reason,
      }));

  @override
  Future<List<InboxItem>> loadInbox(String clinicId, {int limit = 50}) async {
    try {
      final rows = await _client
          .from('clinic_inbox')
          .select(
              'id,clinic_id,kind,severity,title,body,encounter_id,is_read,created_at')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false)
          .limit(limit.clamp(1, 200));
      return _asRows(rows).map(InboxItem.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<void> markInboxRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _rpc('inbox_mark_read', {'p_ids': ids});
  }

  @override
  Future<List<EmergencyAlert>> loadEmergencyAlerts(String clinicId) async {
    try {
      final rows = await _client
          .from('emergency_alerts')
          .select()
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false);
      return _asRows(rows).map(EmergencyAlert.fromJson).toList();
    } on PostgrestException catch (error) {
      throw ClinicRepositoryException(_safeErrorCode(error));
    }
  }

  @override
  Future<EmergencyAlert> triggerEmergencyCall(
    String clinicId, {
    Map<String, dynamic>? location,
    String? message,
  }) async {
    final response = _asMap(await _rpc('trigger_emergency_call', {
      'p_clinic_id': clinicId,
      'p_location': location,
      'p_message': message,
    }));
    return EmergencyAlert.fromJson({
      ...response,
      'id': response['alert_id'],
      'clinic_id': clinicId,
    });
  }

  @override
  Future<void> updateEmergencyAlert(
    String alertId,
    String status, {
    String? note,
  }) async {
    await _rpc('emergency_update', {
      'p_alert_id': alertId,
      'p_status': status,
      'p_note': note,
    });
  }
}
