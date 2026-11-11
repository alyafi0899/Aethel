import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_enums.dart';
import '../models/health_worker_models.dart';

abstract class StaffRepository {
  Future<List<HealthWorkerModel>> fetchHealthWorkers(String clinicId);
  Future<HealthWorkerModel?> fetchHealthWorkerById(String workerId, String clinicId);
  Future<HealthWorkerModel> saveHealthWorker({
    required HealthWorkerModel worker,
    HealthWorkerPrivateModel? privateData,
  });
  Future<void> updateDutyStatus({
    required String workerId,
    required String clinicId,
    required DutyStatus status,
  });
  Future<void> toggleActiveStatus({
    required String workerId,
    required String clinicId,
    required bool isActive,
  });
  Future<void> saveEducation(HealthWorkerEducationModel edu);
  Future<void> deleteEducation(String id);
  Future<void> saveExperience(HealthWorkerExperienceModel exp);
  Future<void> deleteExperience(String id);
  Future<void> saveCertificate(HealthWorkerCertificateModel cert);
  Future<void> deleteCertificate(String id);
}

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<HealthWorkerModel>> fetchHealthWorkers(String clinicId) async {
    final res = await _client
        .from('health_workers')
        .select('''
          *,
          health_worker_private (*),
          health_worker_educations (*),
          health_worker_experiences (*),
          health_worker_certificates (*),
          health_worker_documents (*)
        ''')
        .eq('clinic_id', clinicId)
        .order('is_person_in_charge', ascending: false)
        .order('full_name', ascending: true);

    return (res as List)
        .map((e) => HealthWorkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthWorkerModel?> fetchHealthWorkerById(
      String workerId, String clinicId) async {
    final res = await _client
        .from('health_workers')
        .select('''
          *,
          health_worker_private (*),
          health_worker_educations (*),
          health_worker_experiences (*),
          health_worker_certificates (*),
          health_worker_documents (*)
        ''')
        .eq('id', workerId)
        .eq('clinic_id', clinicId)
        .maybeSingle();

    if (res == null) return null;
    return HealthWorkerModel.fromJson(res);
  }

  @override
  Future<HealthWorkerModel> saveHealthWorker({
    required HealthWorkerModel worker,
    HealthWorkerPrivateModel? privateData,
  }) async {
    final Map<String, dynamic> workerPayload = worker.toJson();
    if (worker.id.isEmpty) workerPayload.remove('id');

    // 1. If person in charge is true, reset any previous person in charge in this clinic first
    if (worker.isPersonInCharge) {
      await _client
          .from('health_workers')
          .update({'is_person_in_charge': false})
          .eq('clinic_id', worker.clinicId);
    }

    // 2. Upsert health worker main record
    final savedWorkerJson = await _client
        .from('health_workers')
        .upsert(workerPayload)
        .select()
        .single();
    final savedWorkerId = savedWorkerJson['id'] as String;

    // 3. Upsert sensitive private record if provided
    if (privateData != null) {
      final privatePayload = privateData
          .copyWith(workerId: savedWorkerId, clinicId: worker.clinicId)
          .toJson();
      await _client.from('health_worker_private').upsert(privatePayload);
    }

    // 4. Return full model with relations
    final full = await fetchHealthWorkerById(savedWorkerId, worker.clinicId);
    return full ?? HealthWorkerModel.fromJson(savedWorkerJson);
  }

  @override
  Future<void> updateDutyStatus({
    required String workerId,
    required String clinicId,
    required DutyStatus status,
  }) async {
    await _client
        .from('health_workers')
        .update({'on_duty_status': status.dbValue})
        .eq('id', workerId)
        .eq('clinic_id', clinicId);
  }

  @override
  Future<void> toggleActiveStatus({
    required String workerId,
    required String clinicId,
    required bool isActive,
  }) async {
    await _client
        .from('health_workers')
        .update({'is_active': isActive})
        .eq('id', workerId)
        .eq('clinic_id', clinicId);
  }

  @override
  Future<void> saveEducation(HealthWorkerEducationModel edu) async {
    final payload = edu.toJson();
    if (edu.id.isEmpty) payload.remove('id');
    await _client.from('health_worker_educations').upsert(payload);
  }

  @override
  Future<void> deleteEducation(String id) async {
    await _client.from('health_worker_educations').delete().eq('id', id);
  }

  @override
  Future<void> saveExperience(HealthWorkerExperienceModel exp) async {
    final payload = exp.toJson();
    if (exp.id.isEmpty) payload.remove('id');
    await _client.from('health_worker_experiences').upsert(payload);
  }

  @override
  Future<void> deleteExperience(String id) async {
    await _client.from('health_worker_experiences').delete().eq('id', id);
  }

  @override
  Future<void> saveCertificate(HealthWorkerCertificateModel cert) async {
    final payload = cert.toJson();
    if (cert.id.isEmpty) payload.remove('id');
    await _client.from('health_worker_certificates').upsert(payload);
  }

  @override
  Future<void> deleteCertificate(String id) async {
    await _client.from('health_worker_certificates').delete().eq('id', id);
  }
}

class FakeStaffRepository implements StaffRepository {
  List<HealthWorkerModel> workers = [];

  @override
  Future<List<HealthWorkerModel>> fetchHealthWorkers(String clinicId) async =>
      workers;

  @override
  Future<HealthWorkerModel?> fetchHealthWorkerById(
      String workerId, String clinicId) async {
    try {
      return workers.firstWhere((w) => w.id == workerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HealthWorkerModel> saveHealthWorker({
    required HealthWorkerModel worker,
    HealthWorkerPrivateModel? privateData,
  }) async {
    final updated = worker.copyWith(privateData: privateData);
    workers.removeWhere((w) => w.id == worker.id && worker.id.isNotEmpty);
    workers.add(updated);
    return updated;
  }

  @override
  Future<void> updateDutyStatus({
    required String workerId,
    required String clinicId,
    required DutyStatus status,
  }) async {
    final index = workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      workers[index] = workers[index].copyWith(onDutyStatus: status);
    }
  }

  @override
  Future<void> toggleActiveStatus({
    required String workerId,
    required String clinicId,
    required bool isActive,
  }) async {
    final index = workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      workers[index] = workers[index].copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> saveEducation(HealthWorkerEducationModel edu) async {}

  @override
  Future<void> deleteEducation(String id) async {}

  @override
  Future<void> saveExperience(HealthWorkerExperienceModel exp) async {}

  @override
  Future<void> deleteExperience(String id) async {}

  @override
  Future<void> saveCertificate(HealthWorkerCertificateModel cert) async {}

  @override
  Future<void> deleteCertificate(String id) async {}
}
