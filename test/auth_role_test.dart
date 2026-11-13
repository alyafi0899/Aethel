import 'package:clinic_operations_platform/data/clinic_repository.dart';
import 'package:clinic_operations_platform/data/models.dart';
import 'package:clinic_operations_platform/data/supabase_clinic_repository.dart';
import 'package:clinic_operations_platform/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppController Authentication & Role Tests', () {
    late AppController controller;

    setUp(() async {
      controller = AppController(const MockClinicRepository());
      await controller.load();
    });

    test('Initial auth state defaults to logged in Admin', () {
      expect(controller.isLoggedIn, isTrue);
      expect(controller.currentRole, equals(UserRole.admin));
      expect(controller.activeUserName, equals('Elena Cruz'));
      expect(controller.activeUserRole, equals('Clinic Administrator'));
    });

    test('Login as Nurse keeps the focused clinic navigation', () {
      controller.loginAsRole(UserRole.nurse);

      expect(controller.isLoggedIn, isTrue);
      expect(controller.currentRole, equals(UserRole.nurse));
      expect(controller.activeUserName, equals('Nurse Olivia Park'));
      expect(controller.activeUserRole, equals('Charge Nurse'));

      final pages = controller.navSections.expand((s) => s.pages).toList();
      expect(pages, [
        AppPage.dashboard,
        AppPage.clinicOperationsInternal,
        AppPage.clinicStaff,
        AppPage.clinicReviews,
        AppPage.clinicProfile,
        AppPage.settings,
      ]);
    });

    test('Login as Admin keeps the focused clinic navigation', () {
      controller.loginAsRole(UserRole.nurse);
      controller.loginAsRole(UserRole.admin);

      expect(controller.currentRole, equals(UserRole.admin));
      final pages = controller.navSections.expand((s) => s.pages).toList();
      expect(pages, hasLength(6));
      expect(pages.toSet(), hasLength(6));
    });

    test('Logout clears session state', () async {
      await controller.logout();
      expect(controller.isLoggedIn, isFalse);
      expect(controller.currentUserProfile, isNull);
    });
  });

  group('SupabaseClinicRepository Tests', () {
    test('SupabaseClinicRepository loads snapshot baseline without crashing',
        () async {
      final repo = SupabaseClinicRepository();
      final data = await repo.load();

      expect(data.facilityName, isNotEmpty);
      expect(data.appointments, isNotEmpty);
      expect(data.screenings, isNotEmpty);
      expect(data.doctors, isNotEmpty);
      expect(data.patients, isNotEmpty);
    });
  });
}
