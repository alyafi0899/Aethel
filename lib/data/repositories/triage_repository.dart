import '../models.dart';

@Deprecated('Use ClinicalRepository with visit_triage and RPCs.')
abstract class TriageRepository {
  Future<List<Screening>> fetchScreenings();
  Future<void> startReview(String screeningId);
  Future<void> escalateScreening(String screeningId, {String? notes});
  Future<void> completeReview(String screeningId,
      {String? disposition, String? notes});
  Future<void> recordVitals(String screeningId,
      {int? bpSys, int? bpDia, int? hr, int? spo2, double? temp, int? rr});
}

@Deprecated('Use SupabaseClinicalRepository; legacy screening tables removed.')
class SupabaseTriageRepository implements TriageRepository {
  SupabaseTriageRepository({Object? client});

  Never _legacySchemaRemoved() => throw UnsupportedError(
        'Legacy screening API is disabled. Use the clinical encounter workflow.',
      );

  @override
  Future<List<Screening>> fetchScreenings() async => _legacySchemaRemoved();

  @override
  Future<void> startReview(String screeningId) async => _legacySchemaRemoved();

  @override
  Future<void> escalateScreening(String screeningId, {String? notes}) async =>
      _legacySchemaRemoved();

  @override
  Future<void> completeReview(String screeningId,
          {String? disposition, String? notes}) async =>
      _legacySchemaRemoved();

  @override
  Future<void> recordVitals(String screeningId,
          {int? bpSys,
          int? bpDia,
          int? hr,
          int? spo2,
          double? temp,
          int? rr}) async =>
      _legacySchemaRemoved();
}
