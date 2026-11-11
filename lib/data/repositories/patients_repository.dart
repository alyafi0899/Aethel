import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class PatientsRepository {
  Future<List<PatientRecord>> fetchPatients({String? searchQuery});
  Future<void> registerPatient(
      {required String name, String? phone, String? dob});
}

class SupabasePatientsRepository implements PatientsRepository {
  SupabasePatientsRepository({SupabaseClient? client})
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
  Future<List<PatientRecord>> fetchPatients({String? searchQuery}) async {
    final client = _client;
    if (client == null) return MockData.patients;

    try {
      var query = client.from('patients').select().eq('is_deleted', false);
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('full_name', '%$searchQuery%');
      }

      final response = await query.order('full_name');
      if ((response as List).isEmpty) return MockData.patients;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        final name = map['full_name']?.toString() ?? 'Patient';
        final initials = name
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((p) => p[0])
            .join()
            .toUpperCase();

        return PatientRecord(
          initials: initials.length > 2 ? initials.substring(0, 2) : initials,
          name: name,
          globalId: map['global_patient_id']?.toString() ??
              map['id']?.toString() ??
              'PT-000000',
          mrn: map['mrn']?.toString() ?? 'MRN-PC-00000',
          registration: map['registration_status']?.toString() ?? 'Registered',
          lastVisit: map['last_visit_at'] != null
              ? map['last_visit_at'].toString().substring(0, 10)
              : 'Jun 17, 2025',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabasePatientsRepository fetch error: $e');
      return MockData.patients;
    }
  }

  @override
  Future<void> registerPatient(
      {required String name, String? phone, String? dob}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('patients').insert({
        'global_patient_id': 'PT-${(100000 + (name.hashCode.abs() % 899999))}',
        'mrn': 'MRN-PC-${(10000 + (name.hashCode.abs() % 89999))}',
        'full_name': name,
        'phone': phone,
        'registration_status': 'registered',
        'last_visit_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('registerPatient error: $e');
    }
  }
}
