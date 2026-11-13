import 'package:clinic_operations_platform/app.dart';
import 'package:clinic_operations_platform/core/theme/theme_config.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/data/clinic_repository.dart';
import 'package:clinic_operations_platform/features/auth/data/auth_repository.dart';
import 'package:clinic_operations_platform/features/auth/state/auth_controller.dart';
import 'package:clinic_operations_platform/features/clinic/data/clinic_catalog_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/clinic_profile_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/document_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/staff_repository.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_member_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/profile_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:clinic_operations_platform/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('clinic home renders with mock data', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fakeAuthRepo = FakeAuthRepository();
    final user = User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {'account_type': 'clinic'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    final session = Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: user,
    );
    fakeAuthRepo.setMockState(
      user: user,
      session: session,
      profile: const ProfileModel(
        id: 'u1',
        fullName: 'Dr. Elena',
        accountType: 'clinic',
      ),
      membership: const ClinicMemberModel(
        clinicId: 'c1',
        userId: 'u1',
        role: ClinicRole.owner,
      ),
    );

    final fakeProfileRepo = FakeClinicProfileRepository();
    fakeProfileRepo.mockClinic = const ClinicModel(
      id: 'c1',
      ownerId: 'u1',
      status: ClinicStatus.verified,
      clinicName: 'Prometheon Central Clinic',
    );

    final authCtrl = AuthController(repository: fakeAuthRepo);
    final clinicCtrl = ClinicController(
      profileRepo: fakeProfileRepo,
      catalogRepo: FakeClinicCatalogRepository(),
      staffRepo: FakeStaffRepository(),
      documentRepo: FakeDocumentRepository(),
      operationsRepo: FakeOperationsRepository(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeController(
              kInitialThemeConfig.copyWith(useGoogleFonts: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AppController(const MockClinicRepository()),
          ),
          ChangeNotifierProvider.value(value: authCtrl),
          ChangeNotifierProvider.value(value: clinicCtrl),
        ],
        child: const ClinicApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Prometheon Central Clinic'), findsWidgets);
  });
}
