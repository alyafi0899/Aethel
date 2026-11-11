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

    test('Login as Nurse updates role and navigation sections', () {
      controller.loginAsRole(UserRole.nurse);

      expect(controller.isLoggedIn, isTrue);
      expect(controller.currentRole, equals(UserRole.nurse));
      expect(controller.activeUserName, equals('Nurse Olivia Park'));
      expect(controller.activeUserRole, equals('Charge Nurse'));

      // Check role-based navigation sections
      final titles = controller.navSections.map((s) => s.title).toList();
      expect(titles, contains('CLINICAL CARE'));
      expect(titles, contains('STAFF & RESOURCES'));
      expect(titles, contains('COMMUNICATION'));
      expect(titles, isNot(contains('ADMINISTRATION')));
      expect(titles, isNot(contains('FINANCE')));
    });

    test('Login as Admin restores full navigation access', () {
      controller.loginAsRole(UserRole.nurse);
      controller.loginAsRole(UserRole.admin);

      expect(controller.currentRole, equals(UserRole.admin));
      final titles = controller.navSections.map((s) => s.title).toList();
      expect(titles, contains('ADMINISTRATION'));
      expect(titles, contains('FINANCE'));
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
