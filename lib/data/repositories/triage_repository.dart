import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class TriageRepository {
  Future<List<Screening>> fetchScreenings();
  Future<void> startReview(String screeningId);
  Future<void> escalateScreening(String screeningId, {String? notes});
  Future<void> completeReview(String screeningId,
      {String? disposition, String? notes});
  Future<void> recordVitals(String screeningId,
      {int? bpSys, int? bpDia, int? hr, int? spo2, double? temp, int? rr});
}

class SupabaseTriageRepository implements TriageRepository {
  SupabaseTriageRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Screening>> fetchScreenings() async {
    final client = _client;
    if (client == null) return MockData.screenings;

    try {
      final response = await client
          .from('screening_sessions')
          .select()
          .order('submitted_at', ascending: false);
      if ((response as List).isEmpty) return MockData.screenings;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Screening(
          id: map['id']?.toString() ?? '',
          appointment: map['reference']?.toString() ??
              map['appointment_id']?.toString() ??
              '',
          patient: map['patient_name']?.toString() ?? 'Pasien',
          initials: map['initials']?.toString() ?? 'PT',
          complaint: map['primary_complaint']?.toString() ?? 'Routine check',
          duration: map['duration']?.toString() ?? 'Recently',
          completion: (map['completion_pct'] as num?)?.toInt() ?? 100,
          priority: map['priority']?.toString() ?? 'Routine',
          reviewer: map['reviewer_name']?.toString() ?? 'Unassigned',
          submitted: map['submitted_at'] != null
              ? map['submitted_at'].toString().substring(11, 16)
              : '09:00 AM',
          status: map['status']?.toString() ?? 'New Screening',
          source: map['source']?.toString() ?? 'Patient self-reported',
          redFlag: map['red_flag'] == true,
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseTriageRepository fetch error: $e');
      return MockData.screenings;
    }
  }

  @override
  Future<void> startReview(String screeningId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('triage_action', params: {
        'p_screening_id': screeningId,
        'p_action': 'start_review',
      });
    } catch (e) {
      debugPrint('startReview error: $e');
    }
  }

  @override
  Future<void> escalateScreening(String screeningId, {String? notes}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('triage_action', params: {
        'p_screening_id': screeningId,
        'p_action': 'escalate',
        'p_notes': notes,
      });
    } catch (e) {
      debugPrint('escalateScreening error: $e');
    }
  }

  @override
  Future<void> completeReview(String screeningId,
      {String? disposition, String? notes}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('triage_action', params: {
        'p_screening_id': screeningId,
        'p_action': 'complete',
        'p_disposition': disposition,
        'p_notes': notes,
      });
    } catch (e) {
      debugPrint('completeReview error: $e');
    }
  }

  @override
  Future<void> recordVitals(String screeningId,
      {int? bpSys,
      int? bpDia,
      int? hr,
      int? spo2,
      double? temp,
      int? rr}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('record_vitals', params: {
        'p_screening_id': screeningId,
        'p_bp_sys': bpSys ?? 120,
        'p_bp_dia': bpDia ?? 80,
        'p_hr': hr ?? 72,
        'p_spo2': spo2 ?? 98,
        'p_temp': temp ?? 36.6,
        'p_rr': rr ?? 16,
      });
    } catch (e) {
      debugPrint('recordVitals error: $e');
    }
  }
}
