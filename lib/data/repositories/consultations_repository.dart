import '../models.dart';

@Deprecated('Use ClinicalRepository with visit_consultations and RPCs.')
abstract class ConsultationsRepository {
  Future<List<ConsultationItem>> fetchConsultations();
}

@Deprecated(
    'Use SupabaseClinicalRepository; legacy consultations table removed.')
class SupabaseConsultationsRepository implements ConsultationsRepository {
  SupabaseConsultationsRepository({Object? client});

  @override
  Future<List<ConsultationItem>> fetchConsultations() =>
      Future.error(UnsupportedError(
        'Legacy consultation API is disabled. Use the clinical encounter workflow.',
      ));
}
