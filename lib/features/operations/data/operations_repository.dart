import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_operations_models.dart';

abstract class OperationsRepository {
  Future<ClinicOperationsInternalModel> fetchInternalOperations(
      String clinicId);
  Future<ClinicOperationsInternalModel> updateInternalOperations(
      ClinicOperationsInternalModel ops);
  Future<ClinicOperationsPublicModel> fetchPublicPreview(String clinicId);
  Future<void> refreshClinicOperations(String clinicId);
}

class SupabaseOperationsRepository implements OperationsRepository {
  SupabaseOperationsRepository({SupabaseClient? client})
      : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<ClinicOperationsInternalModel> fetchInternalOperations(
      String clinicId) async {
    final res = await _client
        .from('clinic_operations_internal')
        .select()
        .eq('clinic_id', clinicId)
        .single();
    return ClinicOperationsInternalModel.fromJson(res);
  }

  @override
  Future<ClinicOperationsInternalModel> updateInternalOperations(
          ClinicOperationsInternalModel ops) async =>
      ClinicOperationsInternalModel.fromJson(
        await _client.rpc(
          'update_clinic_operational_status',
          params: {
            'p_clinic_id': ops.clinicId,
            'p_facility_status': ops.facilityStatus.dbValue,
            'p_queue_process_status': ops.queueProcessStatus.dbValue,
          },
        ) as Map<String, dynamic>,
      );

  @override
  Future<ClinicOperationsPublicModel> fetchPublicPreview(
      String clinicId) async {
    final res = await _client.rpc(
      'clinic_public_preview',
      params: {'p_clinic_id': clinicId},
    );
    return ClinicOperationsPublicModel.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<void> refreshClinicOperations(String clinicId) async {
    await _client.rpc(
      'refresh_clinic_operations',
      params: {'p_clinic_id': clinicId},
    );
  }
}

class FakeOperationsRepository implements OperationsRepository {
  int updateCount = 0;
  ClinicOperationsInternalModel internalOps =
      const ClinicOperationsInternalModel(
    clinicId: 'c1',
    clinicName: 'Klinik Sehat Prometheon',
  );

  @override
  Future<ClinicOperationsInternalModel> fetchInternalOperations(
          String clinicId) async =>
      internalOps;

  @override
  Future<ClinicOperationsInternalModel> updateInternalOperations(
      ClinicOperationsInternalModel ops) async {
    updateCount++;
    internalOps = ops;
    return ops;
  }

  @override
  Future<ClinicOperationsPublicModel> fetchPublicPreview(
          String clinicId) async =>
      ClinicOperationsPublicModel(
        clinicId: clinicId,
        clinicName: internalOps.clinicName,
        currentQueueNumber: internalOps.currentQueueNumber,
        estimatedWaitTime: internalOps.averageWaitTime,
        clinicStatus: internalOps.facilityStatus.dbValue,
      );

  @override
  Future<void> refreshClinicOperations(String clinicId) async {}
}
