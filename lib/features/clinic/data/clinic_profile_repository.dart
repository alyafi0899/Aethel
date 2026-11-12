import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_emr_settings_model.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_model.dart';
import '../models/clinic_org_structure_model.dart';
import '../models/onboarding_status_model.dart';

abstract class ClinicProfileRepository {
  Future<ClinicModel?> fetchClinicById(String clinicId);
  Future<ClinicModel?> fetchClinicByOwnerId(String ownerId);
  Future<ClinicModel> updateClinicBasicData(ClinicModel clinic);
  Future<OnboardingStatusModel> getOnboardingStatus(String clinicId);
  Future<OnboardingStatusModel> submitClinicForReview(String clinicId);
  Future<void> setClinicPublished(
      {required String clinicId, required bool published});
  Future<void> saveIntegrationSecret({
    required String clinicId,
    required String provider,
    required String secret,
  });
  Future<ClinicEmrSettingsModel> fetchEmrSettings(String clinicId);
  Future<ClinicEmrSettingsModel> updateEmrSettings(
      ClinicEmrSettingsModel settings);
  Future<List<ClinicOrgStructureModel>> fetchOrgStructure(String clinicId);
  Future<ClinicOrgStructureModel> saveOrgStructureNode(
      ClinicOrgStructureModel node);
  Future<void> deleteOrgStructureNode(String nodeId);
}

class SupabaseClinicProfileRepository implements ClinicProfileRepository {
  SupabaseClinicProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ClinicModel?> fetchClinicById(String clinicId) async {
    final res =
        await _client.from('clinics').select().eq('id', clinicId).maybeSingle();
    if (res == null) return null;
    return ClinicModel.fromJson(res);
  }

  @override
  Future<ClinicModel?> fetchClinicByOwnerId(String ownerId) async {
    final res = await _client
        .from('clinics')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (res == null) return null;
    return ClinicModel.fromJson(res);
  }

  @override
  Future<ClinicModel> updateClinicBasicData(ClinicModel clinic) async {
    final payload = clinic.toJson();
    final res = await _client
        .from('clinics')
        .update(payload)
        .eq('id', clinic.id)
        .select()
        .single();
    return ClinicModel.fromJson(res);
  }

  @override
  Future<OnboardingStatusModel> getOnboardingStatus(String clinicId) async {
    final res = await _client.rpc(
      'clinic_onboarding_status',
      params: {'p_clinic_id': clinicId},
    );
    return OnboardingStatusModel.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<OnboardingStatusModel> submitClinicForReview(String clinicId) async {
    final res = await _client.rpc(
      'submit_clinic_for_review',
      params: {'p_clinic_id': clinicId},
    );
    return OnboardingStatusModel.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<void> setClinicPublished({
    required String clinicId,
    required bool published,
  }) async {
    await _client.rpc(
      'set_clinic_published',
      params: {
        'p_clinic_id': clinicId,
        'p_published': published,
      },
    );
  }

  @override
  Future<void> saveIntegrationSecret({
    required String clinicId,
    required String provider,
    required String secret,
  }) async {
    await _client.rpc(
      'save_clinic_integration_secret',
      params: {
        'p_clinic_id': clinicId,
        'p_provider': provider,
        'p_secret': secret,
      },
    );
  }

  @override
  Future<ClinicEmrSettingsModel> fetchEmrSettings(String clinicId) async {
    final res = await _client
        .from('clinic_emr_settings')
        .select()
        .eq('clinic_id', clinicId)
        .single();
    return ClinicEmrSettingsModel.fromJson(res);
  }

  @override
  Future<ClinicEmrSettingsModel> updateEmrSettings(
      ClinicEmrSettingsModel settings) async {
    final res = await _client
        .from('clinic_emr_settings')
        .update(settings.toJson())
        .eq('clinic_id', settings.clinicId)
        .select()
        .single();
    return ClinicEmrSettingsModel.fromJson(res);
  }

  @override
  Future<List<ClinicOrgStructureModel>> fetchOrgStructure(
      String clinicId) async {
    final res = await _client
        .from('clinic_org_structure')
        .select()
        .eq('clinic_id', clinicId)
        .order('sort_order', ascending: true);
    return (res as List)
        .map((e) => ClinicOrgStructureModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicOrgStructureModel> saveOrgStructureNode(
      ClinicOrgStructureModel node) async {
    final Map<String, dynamic> payload = node.toJson();
    if (node.id.isEmpty) payload.remove('id');
    final res = await _client
        .from('clinic_org_structure')
        .upsert(payload)
        .select()
        .single();
    return ClinicOrgStructureModel.fromJson(res);
  }

  @override
  Future<void> deleteOrgStructureNode(String nodeId) async {
    await _client.from('clinic_org_structure').delete().eq('id', nodeId);
  }
}

class FakeClinicProfileRepository implements ClinicProfileRepository {
  ClinicModel? mockClinic;
  OnboardingStatusModel mockOnboardingStatus = const OnboardingStatusModel(
    status: ClinicStatus.draft,
  );
  ClinicEmrSettingsModel mockEmrSettings = const ClinicEmrSettingsModel(
    clinicId: 'c1',
  );
  List<ClinicOrgStructureModel> mockOrgStructure = [];

  @override
  Future<ClinicModel?> fetchClinicById(String clinicId) async => mockClinic;

  @override
  Future<ClinicModel?> fetchClinicByOwnerId(String ownerId) async => mockClinic;

  @override
  Future<ClinicModel> updateClinicBasicData(ClinicModel clinic) async {
    mockClinic = clinic;
    return clinic;
  }

  @override
  Future<OnboardingStatusModel> getOnboardingStatus(String clinicId) async =>
      mockOnboardingStatus;

  @override
  Future<OnboardingStatusModel> submitClinicForReview(String clinicId) async {
    mockOnboardingStatus = OnboardingStatusModel(
      status: ClinicStatus.submitted,
      basicData: mockOnboardingStatus.basicData,
      servicesFacilities: mockOnboardingStatus.servicesFacilities,
      adminLegal: mockOnboardingStatus.adminLegal,
      emrSystem: mockOnboardingStatus.emrSystem,
      healthWorkers: mockOnboardingStatus.healthWorkers,
      readyToSubmit: true,
    );
    return mockOnboardingStatus;
  }

  @override
  Future<void> setClinicPublished({
    required String clinicId,
    required bool published,
  }) async {
    if (mockClinic != null) {
      mockClinic = mockClinic!.copyWith(isPublished: published);
    }
  }

  @override
  Future<void> saveIntegrationSecret({
    required String clinicId,
    required String provider,
    required String secret,
  }) async {
    mockEmrSettings = mockEmrSettings.copyWith(satusehatConnected: true);
  }

  @override
  Future<ClinicEmrSettingsModel> fetchEmrSettings(String clinicId) async =>
      mockEmrSettings;

  @override
  Future<ClinicEmrSettingsModel> updateEmrSettings(
      ClinicEmrSettingsModel settings) async {
    mockEmrSettings = settings;
    return settings;
  }

  @override
  Future<List<ClinicOrgStructureModel>> fetchOrgStructure(
          String clinicId) async =>
      mockOrgStructure;

  @override
  Future<ClinicOrgStructureModel> saveOrgStructureNode(
      ClinicOrgStructureModel node) async {
    mockOrgStructure.add(node);
    return node;
  }

  @override
  Future<void> deleteOrgStructureNode(String nodeId) async {
    mockOrgStructure.removeWhere((e) => e.id == nodeId);
  }
}
