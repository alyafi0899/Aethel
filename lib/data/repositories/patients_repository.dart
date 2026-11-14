import '../models.dart';

@Deprecated('Use PatientRepository with clinic_patients.')
abstract class PatientsRepository {
  Future<List<PatientRecord>> fetchPatients({String? searchQuery});
  Future<void> registerPatient(
      {required String name, String? phone, String? dob});
}

@Deprecated('Use SupabaseClinicalRepository and register_visit RPC.')
class SupabasePatientsRepository implements PatientsRepository {
  SupabasePatientsRepository({Object? client});

  @override
  Future<List<PatientRecord>> fetchPatients({String? searchQuery}) =>
      Future.error(UnsupportedError(
        'Legacy patients API is disabled. Use the clinic patient workflow.',
      ));

  @override
  Future<void> registerPatient(
          {required String name, String? phone, String? dob}) =>
      Future.error(UnsupportedError(
        'Register patients through the register_visit RPC.',
      ));
}
