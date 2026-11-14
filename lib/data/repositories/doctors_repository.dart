import '../models.dart';

@Deprecated('Use ClinicController health-worker repository.')
abstract class DoctorsRepository {
  Future<List<Doctor>> fetchDoctors();
  Future<void> updateDoctorStatus(String doctorId, String newStatus);
  Future<void> saveDoctor(Doctor doctor);
}

@Deprecated('Use the active health_workers repository.')
class SupabaseDoctorsRepository implements DoctorsRepository {
  SupabaseDoctorsRepository({Object? client});

  @override
  Future<List<Doctor>> fetchDoctors() => Future.error(UnsupportedError(
        'Legacy doctors API is disabled. Use the health-worker module.',
      ));

  @override
  Future<void> updateDoctorStatus(String doctorId, String newStatus) =>
      Future.error(UnsupportedError(
        'Manage health-worker status through the clinic staff module.',
      ));

  @override
  Future<void> saveDoctor(Doctor doctor) => Future.error(UnsupportedError(
        'Manage health workers through the clinic staff module.',
      ));
}
