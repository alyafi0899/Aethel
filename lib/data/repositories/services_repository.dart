import '../models.dart';

@Deprecated('Use ClinicController clinic catalog repository.')
abstract class ServicesRepository {
  Future<List<ServiceItem>> fetchServices();
  Future<void> saveService(ServiceItem service);
}

@Deprecated('Use clinic_services and the clinic catalog repository.')
class SupabaseServicesRepository implements ServicesRepository {
  SupabaseServicesRepository({Object? client});

  @override
  Future<List<ServiceItem>> fetchServices() => Future.error(UnsupportedError(
        'Legacy services API is disabled. Use the clinic catalog module.',
      ));

  @override
  Future<void> saveService(ServiceItem service) => Future.error(
        UnsupportedError(
          'Manage services through the clinic catalog module.',
        ),
      );
}
