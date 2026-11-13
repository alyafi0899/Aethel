import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
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
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/health_worker_models.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/clinic/ui/onboarding_wizard_page.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _WizardFixture {
  _WizardFixture({
    required this.clinicController,
    required this.themeController,
  });

  final ClinicController clinicController;
  final ThemeController themeController;

  void dispose() {
    clinicController.dispose();
    themeController.dispose();
  }
}

Future<_WizardFixture> _pumpWizard(
  WidgetTester tester, {
  required int step,
  List<HealthWorkerModel> workers = const [],
}) async {
  final profileRepository = FakeClinicProfileRepository()
    ..mockClinic = const ClinicModel(
      id: 'clinic-1',
      ownerId: 'owner-1',
      status: ClinicStatus.draft,
      clinicName: 'Klinik Contoh',
    );
  final catalogRepository = FakeClinicCatalogRepository();
  final staffRepository = FakeStaffRepository()..workers = workers;
  final clinicController = ClinicController(
    profileRepo: profileRepository,
    catalogRepo: catalogRepository,
    staffRepo: staffRepository,
    documentRepo: FakeDocumentRepository(),
    operationsRepo: FakeOperationsRepository(),
    mediaRepo: FakeMediaRepository(),
    complianceRepo: FakeComplianceRepository(),
    reviewsRepo: FakeReviewsRepository(),
    feedbackRepo: FakeFeedbackRepository(),
    legalRepo: FakeLegalConsentRepository(),
  );
  await clinicController.loadClinicData('clinic-1');
  final themeController = ThemeController();
  final fixture = _WizardFixture(
    clinicController: clinicController,
    themeController: themeController,
  );

  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(fixture.dispose);

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
        home: OnboardingWizardPage(initialStep: step),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}

Future<void> _setTimeWithKeyboard(
  WidgetTester tester,
  String buttonLabel,
  int hour,
  int minute,
) async {
  await tester.tap(find.text(buttonLabel).first);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Switch to text input mode'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), hour.toString().padLeft(2, '0'));
  await tester.enterText(fields.at(1), minute.toString().padLeft(2, '0'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('alat memvalidasi jumlah dan menyimpan kondisi serta catatan',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 2);
    await tester.ensureVisible(find.text('Tambah Alat'));
    await tester.tap(find.text('Tambah Alat'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Stetoskop');
    await tester.enterText(fields.at(1), '0');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Jumlah harus berupa bilangan bulat minimal 1.'),
      findsOneWidget,
    );
    expect(fixture.clinicController.equipment, isEmpty);

    await tester.enterText(fields.at(1), '2');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perlu Kalibrasi').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), 'Merek contoh');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final saved = fixture.clinicController.equipment.single;
    expect(saved.quantity, 2);
    expect(saved.condition, 'Perlu Kalibrasi');
    expect(saved.notes, 'Merek contoh');
  });

  testWidgets('fasilitas menyimpan kapasitas, status, dan catatan',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 2);
    await tester.ensureVisible(find.text('Tambah Ruang'));
    await tester.tap(find.text('Tambah Ruang'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ruang Periksa');
    await tester.enterText(fields.at(1), '0');
    await tester.enterText(fields.at(2), 'Akses kursi roda');

    await tester.tap(find.byType(DropdownButtonFormField<FacilityUnitStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terpakai').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final saved = fixture.clinicController.facilities.single;
    expect(saved.capacity, 0);
    expect(saved.status, FacilityUnitStatus.occupied);
    expect(saved.notes, 'Akses kursi roda');
  });

  testWidgets('obat menyimpan bentuk sediaan dan kekuatan dosis',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 2);
    await tester.ensureVisible(find.text('Tambah Obat'));
    await tester.tap(find.text('Tambah Obat'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Parasetamol');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaplet').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '500 mg');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final saved = fixture.clinicController.medicines.single;
    expect(saved.dosageForm, 'Kaplet');
    expect(saved.strength, '500 mg');
  });

  testWidgets('jabatan dapat ditautkan ke tenaga kesehatan dan diurutkan',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 3,
      workers: const [
        HealthWorkerModel(
          id: 'worker-1',
          clinicId: 'clinic-1',
          fullName: 'dr. Andi',
        ),
      ],
    );
    await tester.ensureVisible(find.text('Tambah Jabatan'));
    await tester.tap(find.text('Tambah Jabatan'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'dr. Andi');
    await tester.enterText(fields.at(1), 'Penanggung Jawab');
    await tester.enterText(fields.at(2), '3');
    await tester.tap(
      find.byType(DropdownButtonFormField<String>).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('dr. Andi • Dokter').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final saved = fixture.clinicController.orgStructure.single;
    expect(saved.personName, 'dr. Andi');
    expect(saved.healthWorkerId, 'worker-1');
    expect(saved.sortOrder, 3);
  });

  testWidgets('jam operasional menyimpan jam dalam format database',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 2);
    await tester.ensureVisible(find.text('5. Jam Operasional 7 Hari'));

    expect(find.text('Jam buka: 08:00'), findsWidgets);
    expect(find.text('Jam tutup: 17:00'), findsWidgets);
    expect(find.text('Istirahat mulai'), findsWidgets);

    await _setTimeWithKeyboard(tester, 'Jam tutup: 17:00', 7, 0);

    expect(fixture.clinicController.operatingHours.first.closeTime, '17:00');
    expect(
      find.text('Jam tutup harus lebih akhir daripada jam buka.'),
      findsOneWidget,
    );

    await _setTimeWithKeyboard(tester, 'Istirahat mulai', 12, 0);
    await _setTimeWithKeyboard(tester, 'Istirahat selesai', 11, 0);
    expect(
      fixture.clinicController.operatingHours.first.breakStart,
      '12:00:00',
    );
    expect(fixture.clinicController.operatingHours.first.breakEnd, isNull);
    expect(
      find.text(
          'Jam selesai istirahat harus lebih akhir daripada jam mulainya.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).at(5));
    await tester.pumpAndSettle();

    final saturday = fixture.clinicController.operatingHours[5];
    expect(saturday.isOpen, isTrue);
    expect(saturday.toJson()['open_time'], '08:00:00');
    expect(saturday.toJson()['close_time'], '17:00:00');
  });
}
