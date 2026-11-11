import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class ConsultationsRepository {
  Future<List<ConsultationItem>> fetchConsultations();
}

class SupabaseConsultationsRepository implements ConsultationsRepository {
  SupabaseConsultationsRepository({SupabaseClient? client})
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
  Future<List<ConsultationItem>> fetchConsultations() async {
    final client = _client;
    if (client == null) return MockData.consultations;

    try {
      final response = await client
          .from('consultations')
          .select()
          .order('start_time', ascending: false);
      if ((response as List).isEmpty) return MockData.consultations;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return ConsultationItem(
          id: map['reference']?.toString() ??
              map['id']?.toString() ??
              'CON-000',
          appointmentId: map['appointment_id']?.toString() ?? '',
          patient: map['patient_name']?.toString() ?? 'Pasien',
          doctor: map['doctor_name']?.toString() ?? 'Dr. Maya Chen',
          type: map['type']?.toString() ?? 'In-person',
          startTime: map['start_time'] != null
              ? map['start_time'].toString().substring(11, 16)
              : '09:00 AM',
          status: map['status']?.toString() ?? 'In Consultation',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseConsultationsRepository fetch error: $e');
      return MockData.consultations;
    }
  }
}
