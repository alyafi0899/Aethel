import 'package:supabase_flutter/supabase_flutter.dart';

import 'clinic_repository.dart';
import 'models.dart';

class SupabaseClinicRepository implements ClinicRepository {
  SupabaseClinicRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ClinicData> load() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sesi pengguna belum tersedia.');
    }

    final membership = await _client
        .from('clinic_members')
        .select('clinic_id,role,clinics!inner(clinic_name)')
        .eq('user_id', user.id)
        .maybeSingle();
    if (membership == null) {
      throw StateError('Keanggotaan klinik tidak ditemukan.');
    }

    final clinics = membership['clinics'];
    final clinic = clinics is Map<String, dynamic> ? clinics : const {};
    final clinicName = clinic['clinic_name']?.toString();
    if (clinicName == null || clinicName.isEmpty) {
      throw StateError('Profil klinik tidak memiliki nama.');
    }

    final name = user.userMetadata?['full_name']?.toString() ??
        user.email?.split('@').first ??
        'Pengguna Klinik';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1))
        .take(2)
        .join()
        .toUpperCase();

    return ClinicData.empty(
      facilityName: clinicName,
      userName: name,
      userInitials: initials.isEmpty ? 'PK' : initials,
      userRole: membership['role']?.toString() ?? 'Anggota Klinik',
    );
  }
}
