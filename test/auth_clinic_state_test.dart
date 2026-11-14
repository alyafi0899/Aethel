import 'package:clinic_operations_platform/features/auth/data/auth_repository.dart';
import 'package:clinic_operations_platform/features/auth/state/auth_controller.dart';
import 'package:clinic_operations_platform/features/clinic/data/clinic_catalog_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/clinic_profile_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/compliance_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/document_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/feedback_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/legal_consent_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/media_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/reviews_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/staff_repository.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_member_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_service_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/profile_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.utc(2025).toIso8601String(),
    );

void main() {
  test('refreshing auth for another user clears the previous profile',
      () async {
    final repository = FakeAuthRepository();
    final firstUser = _user('user-1');
    repository.setMockState(
      user: firstUser,
      session: Session(
        accessToken: 'token-1',
        tokenType: 'bearer',
        user: firstUser,
      ),
      profile: const ProfileModel(
        id: 'user-1',
        fullName: 'Pengguna Pertama',
        accountType: 'clinic',
      ),
      membership: const ClinicMemberModel(
        clinicId: 'clinic-1',
        userId: 'user-1',
        role: ClinicRole.owner,
      ),
    );
    final controller = AuthController(repository: repository);
    addTearDown(controller.dispose);
    await controller.initSession();
    expect(controller.profile?.id, 'user-1');
    expect(controller.membership?.clinicId, 'clinic-1');

    final secondUser = _user('user-2');
    repository.setMockState(
      user: secondUser,
      session: Session(
        accessToken: 'token-2',
        tokenType: 'bearer',
        user: secondUser,
      ),
    );
    await controller.refreshProfile();

    expect(controller.profile, isNull);
    expect(controller.membership, isNull);
    expect(controller.loading, isFalse);
  });

  test('loading a user without a clinic clears the previous clinic snapshot',
      () async {
    final profileRepository = FakeClinicProfileRepository()
      ..mockClinic = const ClinicModel(
        id: 'clinic-1',
        ownerId: 'user-1',
        clinicName: 'Klinik Pertama',
      );
    final catalogRepository = FakeClinicCatalogRepository()
      ..services = const [
        ClinicServiceModel(
          id: 'service-1',
          clinicId: 'clinic-1',
          serviceType: 'Umum',
        ),
      ];
    final controller = ClinicController(
      profileRepo: profileRepository,
      catalogRepo: catalogRepository,
      staffRepo: FakeStaffRepository(),
      documentRepo: FakeDocumentRepository(),
      operationsRepo: FakeOperationsRepository(),
      mediaRepo: FakeMediaRepository(),
      complianceRepo: FakeComplianceRepository(),
      reviewsRepo: FakeReviewsRepository(),
      feedbackRepo: FakeFeedbackRepository(),
      legalRepo: FakeLegalConsentRepository(),
    );
    addTearDown(controller.dispose);
    await controller.loadClinicData('clinic-1');
    expect(controller.clinic?.id, 'clinic-1');
    expect(controller.services, hasLength(1));

    profileRepository.mockClinic = null;
    await controller.loadClinicForUser('user-2');

    expect(controller.clinic, isNull);
    expect(controller.services, isEmpty);
    expect(controller.healthWorkers, isEmpty);
    expect(controller.clinicDocuments, isEmpty);
    expect(controller.mediaList, isEmpty);
    expect(controller.loading, isFalse);
  });
}
