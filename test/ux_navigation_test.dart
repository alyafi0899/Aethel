import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/data/clinic_repository.dart';
import 'package:clinic_operations_platform/data/models.dart';
import 'package:clinic_operations_platform/data/mock_data.dart';
import 'package:clinic_operations_platform/features/auth/data/auth_repository.dart';
import 'package:clinic_operations_platform/features/auth/state/auth_controller.dart';
import 'package:clinic_operations_platform/features/auth/state/current_staff_controller.dart';
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
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/clinic/ui/onboarding_wizard_page.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:clinic_operations_platform/shell/app_shell.dart';
import 'package:clinic_operations_platform/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ImmediateClinicRepository implements ClinicRepository {
  @override
  Future<ClinicData> load() async => MockData.snapshot();
}

Widget _app({required AppController appController}) {
  final themeController = ThemeController();
  final authController = AuthController(repository: FakeAuthRepository());
  final clinicController = ClinicController(
    profileRepo: FakeClinicProfileRepository(),
    catalogRepo: FakeClinicCatalogRepository(),
    staffRepo: FakeStaffRepository(),
    documentRepo: FakeDocumentRepository(),
    operationsRepo: FakeOperationsRepository(),
    mediaRepo: FakeMediaRepository(),
    complianceRepo: FakeComplianceRepository(),
    reviewsRepo: FakeReviewsRepository(),
    feedbackRepo: FakeFeedbackRepository(),
    legalRepo: FakeLegalConsentRepository(),
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeController),
      ChangeNotifierProvider.value(value: appController),
      ChangeNotifierProvider.value(value: authController),
      ChangeNotifierProvider.value(value: CurrentStaffController()),
      ChangeNotifierProvider.value(value: clinicController),
    ],
    child: MaterialApp(
      theme: AppTheme.build(themeController.config, Brightness.light),
      home: const AppShell(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menu desktop menampilkan delapan grup operasional',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final appController = AppController(_ImmediateClinicRepository());
    await tester.pumpWidget(_app(appController: appController));
    await tester.pumpAndSettle();

    expect(appController.navSections, hasLength(8));
    expect(
      appController.navSections.map((section) => section.title),
      [
        'RINGKASAN',
        'ALUR PASIEN',
        'MANAJEMEN SDM',
        'LAYANAN & FASILITAS',
        'PROFIL PUBLIK',
        'KEUANGAN',
        'KOMUNIKASI',
        'ADMINISTRASI KLINIK',
      ],
    );
    expect(find.text('Beranda'), findsWidgets);

    appController.dispose();
  });

  testWidgets('layar sempit memakai navigasi bawah lima tujuan',
      (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final appController = AppController(_ImmediateClinicRepository());
    await tester.pumpWidget(_app(appController: appController));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Operasional'), findsWidgets);
    expect(find.text('Tenaga'), findsOneWidget);
    expect(find.text('Ulasan'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);

    appController.dispose();
  });

  test('navigasi langsung ke alur kunjungan tidak dialihkan', () async {
    final appController = AppController(_ImmediateClinicRepository());
    appController.go(AppPage.appointments);
    expect(appController.page, AppPage.appointments);
    await appController.load();
    appController.dispose();
  });

  test('halaman layanan dan ruangan masuk ke tab profil dengan batas tinggi',
      () async {
    final appController = AppController(_ImmediateClinicRepository());

    appController.go(AppPage.rooms);
    expect(appController.page, AppPage.clinicProfile);
    expect(appController.profileTab, 1);

    appController.go(AppPage.services);
    expect(appController.page, AppPage.clinicProfile);
    expect(appController.profileTab, 1);
    await appController.load();
    appController.dispose();
  });

  testWidgets('wizard menyimpan otomatis data dasar yang belum lengkap',
      (tester) async {
    final profileRepository = FakeClinicProfileRepository()
      ..mockClinic = const ClinicModel(
        id: 'clinic-autosave',
        ownerId: 'owner',
        status: ClinicStatus.draft,
        clinicName: 'Nama sebelumnya',
      );
    final clinicController = ClinicController(
      profileRepo: profileRepository,
      catalogRepo: FakeClinicCatalogRepository(),
      staffRepo: FakeStaffRepository(),
      documentRepo: FakeDocumentRepository(),
      operationsRepo: FakeOperationsRepository(),
      mediaRepo: FakeMediaRepository(),
      complianceRepo: FakeComplianceRepository(),
      reviewsRepo: FakeReviewsRepository(),
      feedbackRepo: FakeFeedbackRepository(),
      legalRepo: FakeLegalConsentRepository(),
    );
    addTearDown(clinicController.dispose);
    await clinicController.loadClinicData('clinic-autosave');
    final themeController = ThemeController();
    addTearDown(themeController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeController),
          ChangeNotifierProvider.value(value: clinicController),
          ChangeNotifierProvider(
            create: (_) => AuthController(repository: FakeAuthRepository()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(themeController.config, Brightness.light),
          home: const OnboardingWizardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final clinicNameField = find.byType(TextFormField).first;
    await tester.enterText(clinicNameField, 'Klinik Baru');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(profileRepository.mockClinic?.clinicName, 'Klinik Baru');
  });
}
