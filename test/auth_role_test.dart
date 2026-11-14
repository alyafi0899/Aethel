import 'package:clinic_operations_platform/data/clinic_repository.dart';
import 'package:clinic_operations_platform/data/models.dart';
import 'package:clinic_operations_platform/data/repositories/appointments_repository.dart';
import 'package:clinic_operations_platform/data/supabase_clinic_repository.dart';
import 'package:clinic_operations_platform/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppController navigation and session defaults', () {
    late AppController controller;

    setUp(() async {
      controller = AppController(const MockClinicRepository());
      await controller.load();
    });

    tearDown(() => controller.dispose());

    test('starts unauthenticated and restores all eight navigation groups', () {
      expect(controller.isLoggedIn, isFalse);
      expect(controller.currentUserProfile, isNull);
      expect(controller.navSections, hasLength(8));

      final pages = controller.navSections.expand((section) => section.pages);
      expect(pages, contains(AppPage.workflow));
      expect(pages, contains(AppPage.appointments));
      expect(pages, contains(AppPage.billing));
      expect(pages.toSet(), hasLength(pages.length));
    });

    test('navigation does not redirect an enabled workflow module', () {
      controller.go(AppPage.appointments);
      expect(controller.page, AppPage.appointments);
    });

    test('simulated role login is unavailable without explicit mock mode', () {
      expect(
        () => controller.loginAsRole(UserRole.nurse),
        throwsA(isA<StateError>()),
      );
      expect(controller.isLoggedIn, isFalse);
    });
  });

  test('live repository does not replace missing auth with mock data',
      () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-key');
    final repository = SupabaseClinicRepository(client: client);

    await expectLater(
      repository.load(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Sesi pengguna belum tersedia.',
        ),
      ),
    );
    await client.dispose();
  });

  test('legacy appointment repository fails explicitly instead of fallback',
      () {
    final repository = SupabaseAppointmentsRepository();

    expect(
      repository.fetchAppointments(),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
