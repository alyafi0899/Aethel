import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/compliance_model.dart';

abstract class ComplianceRepository {
  Future<ComplianceStatusModel> fetchComplianceStatus(String clinicId);
  Future<void> refreshComplianceAlerts(String clinicId);
}

class SupabaseComplianceRepository implements ComplianceRepository {
  SupabaseComplianceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ComplianceStatusModel> fetchComplianceStatus(String clinicId) async {
    final res = await _client.rpc(
      'clinic_compliance_status',
      params: {'p_clinic_id': clinicId},
    );
    return ComplianceStatusModel.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<void> refreshComplianceAlerts(String clinicId) async {
    await _client.rpc(
      'refresh_compliance_alerts',
      params: {'p_clinic_id': clinicId},
    );
  }
}

class FakeComplianceRepository implements ComplianceRepository {
  ComplianceStatusModel mockCompliance = const ComplianceStatusModel();

  @override
  Future<ComplianceStatusModel> fetchComplianceStatus(String clinicId) async =>
      mockCompliance;

  @override
  Future<void> refreshComplianceAlerts(String clinicId) async {}
}
