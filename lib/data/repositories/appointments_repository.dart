import '../models.dart';

@Deprecated('Use ClinicOperationsRepository with encounters and RPCs.')
abstract class AppointmentsRepository {
  Future<List<Appointment>> fetchAppointments(
      {int page = 1, int pageSize = 25, String? statusFilter});
  Future<void> updateStatus(String appointmentId, String newStatus);
  Future<void> createAppointment(
      {required String patientName,
      String? doctorId,
      String? serviceId,
      String? complaint});
  Future<void> reassignDoctor(String appointmentId, String doctorId);
  Future<void> reallocateRoom(String appointmentId, String roomId);
  Future<void> cancelAppointment(String appointmentId, String reason);
}

@Deprecated(
    'Use SupabaseClinicalRepository; legacy appointments table removed.')
class SupabaseAppointmentsRepository implements AppointmentsRepository {
  SupabaseAppointmentsRepository({Object? client});

  Never _legacySchemaRemoved() => throw UnsupportedError(
        'Legacy appointments API is disabled. Use the encounter workflow.',
      );

  @override
  Future<List<Appointment>> fetchAppointments(
          {int page = 1, int pageSize = 25, String? statusFilter}) async =>
      _legacySchemaRemoved();

  @override
  Future<void> updateStatus(String appointmentId, String newStatus) async =>
      _legacySchemaRemoved();

  @override
  Future<void> createAppointment(
          {required String patientName,
          String? doctorId,
          String? serviceId,
          String? complaint}) async =>
      _legacySchemaRemoved();

  @override
  Future<void> reassignDoctor(String appointmentId, String doctorId) async =>
      _legacySchemaRemoved();

  @override
  Future<void> reallocateRoom(String appointmentId, String roomId) async =>
      _legacySchemaRemoved();

  @override
  Future<void> cancelAppointment(String appointmentId, String reason) async =>
      _legacySchemaRemoved();
}
