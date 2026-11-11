import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class DoctorsRepository {
  Future<List<Doctor>> fetchDoctors();
  Future<void> updateDoctorStatus(String doctorId, String newStatus);
  Future<void> saveDoctor(Doctor doctor);
}

class SupabaseDoctorsRepository implements DoctorsRepository {
  SupabaseDoctorsRepository({SupabaseClient? client})
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
  Future<List<Doctor>> fetchDoctors() async {
    final client = _client;
    if (client == null) return MockData.doctors;

    try {
      final response = await client.from('doctors').select().order('full_name');
      if ((response as List).isEmpty) return MockData.doctors;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        final name =
            map['full_name']?.toString() ?? map['name']?.toString() ?? 'Doctor';
        final initials = name
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((p) => p[0])
            .join()
            .toUpperCase();

        return Doctor(
          initials: initials.length > 2 ? initials.substring(0, 2) : initials,
          name: name,
          specialty: map['specialty']?.toString() ?? 'General Medicine',
          registration: map['registration_no']?.toString() ?? 'REG-0000',
          status: map['status']?.toString() ?? 'Available',
          todayCount: (map['today_count'] as num?)?.toInt() ?? 0,
          tone: badgeTone(map['status']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseDoctorsRepository fetch error: $e');
      return MockData.doctors;
    }
  }

  @override
  Future<void> updateDoctorStatus(String doctorId, String newStatus) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .from('doctors')
          .update({'status': newStatus.toLowerCase().replaceAll(' ', '_')}).eq(
              'id', doctorId);
    } catch (e) {
      debugPrint('updateDoctorStatus error: $e');
    }
  }

  @override
  Future<void> saveDoctor(Doctor doctor) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('doctors').upsert({
        'full_name': doctor.name,
        'specialty': doctor.specialty,
        'registration_no': doctor.registration,
        'status': doctor.status.toLowerCase().replaceAll(' ', '_'),
      });
    } catch (e) {
      debugPrint('saveDoctor error: $e');
    }
  }
}
