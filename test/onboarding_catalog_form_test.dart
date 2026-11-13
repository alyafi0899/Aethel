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
import 'package:clinic_operations_platform/features/clinic/models/clinic_equipment_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_facility_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_media_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/health_worker_models.dart';
import 'package:clinic_operations_platform/features/clinic/models/onboarding_status_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/clinic/ui/onboarding_wizard_page.dart';
import 'package:clinic_operations_platform/features/clinic/widgets/public_media_uploader.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:clinic_operations_platform/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _WizardFixture {
  _WizardFixture({
    required this.clinicController,
    required this.profileRepository,
    required this.mediaRepository,
    required this.themeController,
  });

  final ClinicController clinicController;
  final FakeClinicProfileRepository profileRepository;
  final FakeMediaRepository mediaRepository;
  final ThemeController themeController;

  void dispose() {
    clinicController.dispose();
    themeController.dispose();
  }
}

Future<_WizardFixture> _pumpWizard(
  WidgetTester tester, {
  required int step,
  ClinicStatus clinicStatus = ClinicStatus.draft,
  List<HealthWorkerModel> workers = const [],
  List<ClinicMediaModel> media = const [],
  OnboardingStatusModel? onboardingStatus,
  bool showRmeSettings = false,
}) async {
  final profileRepository = FakeClinicProfileRepository()
    ..mockClinic = ClinicModel(
      id: 'clinic-1',
      ownerId: 'owner-1',
      status: clinicStatus,
      clinicName: 'Klinik Contoh',
    );
  if (onboardingStatus != null) {
    profileRepository.mockOnboardingStatus = onboardingStatus;
  }
  final catalogRepository = FakeClinicCatalogRepository();
  final staffRepository = FakeStaffRepository()..workers = workers;
  final mediaRepository = FakeMediaRepository()..mediaList = media;
  final clinicController = ClinicController(
    profileRepo: profileRepository,
    catalogRepo: catalogRepository,
    staffRepo: staffRepository,
    documentRepo: FakeDocumentRepository(),
    operationsRepo: FakeOperationsRepository(),
    mediaRepo: mediaRepository,
    complianceRepo: FakeComplianceRepository(),
    reviewsRepo: FakeReviewsRepository(),
    feedbackRepo: FakeFeedbackRepository(),
    legalRepo: FakeLegalConsentRepository(),
  );
  await clinicController.loadClinicData('clinic-1');
  final themeController = ThemeController();
  final fixture = _WizardFixture(
    clinicController: clinicController,
    profileRepository: profileRepository,
    mediaRepository: mediaRepository,
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
        home: OnboardingWizardPage(
          initialStep: step,
          showRmeSettings: showRmeSettings,
        ),
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

  testWidgets('langkah RME dilewati dan diatur otomatis ke Prometheon',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 4);

    expect(
      find.text('Langkah 4: Penanggung Jawab & Tenaga Kesehatan'),
      findsOneWidget,
    );
    expect(find.text('Rekam Medis (RME)'), findsNothing);
    expect(find.text('Sistem rekam medis apa yang dipakai klinik Anda?'),
        findsNothing);
    expect(
        fixture.clinicController.emrSettings?.emrAppType, EmrAppType.internal);
    expect(
      fixture.clinicController.emrSettings?.emrAppName,
      'Prometheon Clinic OS',
    );
    expect(fixture.clinicController.emrSettings?.emrChoiceConfirmed, isTrue);
  });

  testWidgets('navigasi dari administrasi langsung ke tenaga kesehatan',
      (tester) async {
    await _pumpWizard(tester, step: 3);
    await tester.tap(find.text('Simpan & Lanjut'));
    await tester.pumpAndSettle();

    expect(
      find.text('Langkah 4: Penanggung Jawab & Tenaga Kesehatan'),
      findsOneWidget,
    );
  });

  testWidgets('tinjau menampilkan saran tanpa memblokir kirim', (tester) async {
    await _pumpWizard(
      tester,
      step: 6,
      media: const [
        ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'clinic-1',
          kind: MediaKind.logo,
          filePath: 'clinic-1/logo/logo.jpg',
        ),
        ClinicMediaModel(
          id: 'cover-1',
          clinicId: 'clinic-1',
          kind: MediaKind.cover,
          filePath: 'clinic-1/cover/cover.jpg',
        ),
      ],
      onboardingStatus: const OnboardingStatusModel(
        status: ClinicStatus.draft,
        basicData: OnboardingSectionStatus(complete: true),
        servicesFacilities: OnboardingSectionStatus(complete: true),
        adminLegal: OnboardingSectionStatus(complete: true),
        healthWorkers: OnboardingSectionStatus(complete: true),
        publicMedia: OnboardingSectionStatus(complete: true),
        recommendations: [
          'emr_choice',
          'doc:service_sop',
          'media:gallery',
        ],
      ),
    );

    expect(
        find.text('Prometheon Clinic OS · Dikelola otomatis'), findsOneWidget);
    expect(find.text('Saran sebelum mengirim'), findsOneWidget);
    expect(find.text('Pilih sistem rekam medis klinik'), findsNothing);
    expect(find.text('Unggah SOP layanan'), findsOneWidget);
    expect(find.text('Tambah foto galeri'), findsOneWidget);

    final sendButton = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Kirim Pendaftaran untuk Verifikasi'),
        matching: find.byType(AppButton),
      ),
    );
    expect(sendButton.onPressed, isNotNull);
  });

  testWidgets('integrasi SATUSEHAT tersedia setelah klinik terverifikasi',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 4,
      clinicStatus: ClinicStatus.verified,
      showRmeSettings: true,
    );
    expect(find.text('Terhubung ✓'), findsNothing);
    await tester.tap(find.text('Hubungkan'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Kode ini disimpan di server dan tidak dapat dilihat kembali. Jangan bagikan kepada siapa pun.',
      ),
      findsOneWidget,
    );
    const secret = 'temporary-test-secret';
    await tester.enterText(find.byType(TextFormField).last, secret);
    await tester.tap(find.text('Simpan kode'));
    await tester.pumpAndSettle();

    expect(fixture.profileRepository.integrationSecretSaveCount, 1);
    expect(fixture.profileRepository.lastIntegrationProvider, 'satusehat');
    expect(fixture.clinicController.emrSettings?.satusehatConnected, isTrue);
    expect(fixture.clinicController.toString(), isNot(contains(secret)));
    expect(
      fixture.clinicController.emrSettings.toString(),
      isNot(contains(secret)),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == secret,
      ),
      findsNothing,
    );
  });

  testWidgets(
      'integrasi belum tersedia sebelum verifikasi dan merahasiakan kode',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 4,
      showRmeSettings: true,
    );
    expect(
      find.text('Tersedia setelah klinik terverifikasi.'),
      findsOneWidget,
    );
    expect(find.text('Hubungkan'), findsNothing);

    const secret = 'temporary-test-secret';
    final blocked = await fixture.clinicController.saveSatusehatSecret(secret);
    expect(blocked, isFalse);
    expect(
      fixture.clinicController.errorMessage,
      'Kode API hanya dapat disimpan setelah klinik terverifikasi.',
    );

    fixture.profileRepository.integrationSecretFailure =
        'server error containing $secret';
    final saved = await fixture.clinicController.saveSatusehatSecret(secret);

    expect(saved, isFalse);
    expect(
      fixture.clinicController.errorMessage,
      isNot(contains(secret)),
    );
    expect(fixture.profileRepository.integrationSecretSaveCount, 2);
  });

  testWidgets('dialog integrasi menjelaskan jika verifikasi belum terpenuhi',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 4,
      clinicStatus: ClinicStatus.verified,
      showRmeSettings: true,
    );
    fixture.profileRepository.integrationSecretFailure = 'clinic_not_verified';
    await tester.tap(find.text('Hubungkan'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'temporary-test-secret',
    );
    await tester.tap(find.text('Simpan kode'));
    await tester.pumpAndSettle();

    expect(
      find.text('Kode API hanya dapat disimpan setelah klinik terverifikasi.'),
      findsOneWidget,
    );
    expect(
      fixture.clinicController.errorMessage,
      isNot(contains('temporary-test-secret')),
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.controller?.text == 'temporary-test-secret',
      ),
      findsNothing,
    );
    expect(find.text('temporary-test-secret'), findsNothing);
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

  testWidgets('fasilitas yang ada dapat diedit tanpa membuat item baru',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 2);
    await fixture.clinicController.saveFacility(
      const ClinicFacilityModel(
        id: 'facility-1',
        clinicId: 'clinic-1',
        name: 'Ruang Periksa',
        capacity: 1,
        notes: 'Catatan lama',
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edit Ruang Periksa'));
    await tester.tap(find.byTooltip('Edit Ruang Periksa'));
    await tester.pumpAndSettle();

    expect(find.text('Edit fasilitas atau ruangan'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ruang Tindakan');
    await tester.enterText(fields.at(1), '4');
    await tester.enterText(fields.at(2), 'Dekat ruang tunggu');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(fixture.clinicController.facilities, hasLength(1));
    final saved = fixture.clinicController.facilities.single;
    expect(saved.id, 'facility-1');
    expect(saved.name, 'Ruang Tindakan');
    expect(saved.capacity, 4);
    expect(saved.notes, 'Dekat ruang tunggu');
  });

  testWidgets('peralatan yang ada dapat diedit tanpa membuat item baru',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 2);
    await fixture.clinicController.saveEquipment(
      const ClinicEquipmentModel(
        id: 'equipment-1',
        clinicId: 'clinic-1',
        name: 'Timbangan',
        category: EquipmentCategory.non_medical,
        quantity: 2,
        condition: 'Baik',
        notes: 'Catatan lama',
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edit Timbangan'));
    await tester.tap(find.byTooltip('Edit Timbangan'));
    await tester.pumpAndSettle();

    expect(find.text('Edit peralatan'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Timbangan Digital');
    await tester.enterText(fields.at(1), '3');
    await tester.enterText(fields.at(2), 'Merek contoh');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perlu Kalibrasi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(fixture.clinicController.equipment, hasLength(1));
    final saved = fixture.clinicController.equipment.single;
    expect(saved.id, 'equipment-1');
    expect(saved.name, 'Timbangan Digital');
    expect(saved.category, EquipmentCategory.non_medical);
    expect(saved.quantity, 3);
    expect(saved.condition, 'Perlu Kalibrasi');
    expect(saved.notes, 'Merek contoh');
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

  testWidgets('tinjau menahan kirim dan merinci logo serta sampul yang hilang',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 6,
      onboardingStatus: const OnboardingStatusModel(
        status: ClinicStatus.draft,
        basicData: OnboardingSectionStatus(complete: true),
        servicesFacilities: OnboardingSectionStatus(complete: true),
        adminLegal: OnboardingSectionStatus(complete: true),
        healthWorkers: OnboardingSectionStatus(complete: true),
      ),
    );

    expect(
      fixture.clinicController.onboardingStatus.publicMedia.missing,
      ['media:logo', 'media:cover'],
    );
    expect(find.text('Identitas Visual Publik'), findsOneWidget);
    expect(
      find.textContaining('Unggah Logo Klinik (Identitas Visual)'),
      findsNWidgets(2),
    );
    expect(
      find.textContaining('Unggah Sampul Klinik (Identitas Visual)'),
      findsOneWidget,
    );
    final sendButton = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Kirim Pendaftaran untuk Verifikasi'),
        matching: find.byType(AppButton),
      ),
    );
    expect(sendButton.onPressed, isNull);
    final submitted = await fixture.clinicController.submitClinicForReview();
    expect(submitted, isFalse);
    expect(fixture.profileRepository.submitClinicForReviewCount, 0);
    expect(fixture.clinicController.errorMessage, contains('Logo Klinik'));
  });

  testWidgets(
      'media pending dari server menyelaraskan status tinjau dan mengizinkan kirim',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 6,
      media: const [
        ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'clinic-1',
          kind: MediaKind.logo,
          filePath: 'clinic-1/logo/logo.jpg',
          reviewStatus: DocumentReviewStatus.pending,
        ),
        ClinicMediaModel(
          id: 'cover-1',
          clinicId: 'clinic-1',
          kind: MediaKind.cover,
          filePath: 'clinic-1/cover/cover.jpg',
          reviewStatus: DocumentReviewStatus.pending,
        ),
      ],
      onboardingStatus: const OnboardingStatusModel(
        status: ClinicStatus.draft,
        basicData: OnboardingSectionStatus(complete: true),
        servicesFacilities: OnboardingSectionStatus(complete: true),
        adminLegal: OnboardingSectionStatus(complete: true),
        healthWorkers: OnboardingSectionStatus(complete: true),
        publicMedia: OnboardingSectionStatus(
          missing: ['media:logo', 'media:cover'],
        ),
      ),
    );

    expect(
        fixture.clinicController.onboardingStatus.publicMedia.complete, isTrue);
    expect(find.text('Identitas Visual Publik'), findsOneWidget);
    expect(find.text('Item yang belum lengkap:'), findsNothing);

    fixture.profileRepository.mockOnboardingStatus =
        const OnboardingStatusModel(
      status: ClinicStatus.draft,
      basicData: OnboardingSectionStatus(complete: true),
      servicesFacilities: OnboardingSectionStatus(complete: true),
      adminLegal: OnboardingSectionStatus(complete: true),
      healthWorkers: OnboardingSectionStatus(complete: true),
      publicMedia: OnboardingSectionStatus(
        missing: ['media:logo', 'media:cover'],
      ),
    );
    final refreshed = await fixture.clinicController.refreshOnboardingStatus();
    expect(refreshed, isTrue);
    expect(
        fixture.clinicController.onboardingStatus.publicMedia.complete, isTrue);

    final sendButton = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Kirim Pendaftaran untuk Verifikasi'),
        matching: find.byType(AppButton),
      ),
    );
    expect(sendButton.onPressed, isNotNull);

    await tester.tap(find.text('Kirim Pendaftaran untuk Verifikasi'));
    await tester.pumpAndSettle();
    expect(fixture.profileRepository.submitClinicForReviewCount, 1);
    expect(
      fixture.clinicController.onboardingStatus.status,
      ClinicStatus.submitted,
    );
  });

  testWidgets('kegagalan RPC pengiriman ditampilkan kepada pengguna',
      (tester) async {
    final fixture = await _pumpWizard(
      tester,
      step: 6,
      media: const [
        ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'clinic-1',
          kind: MediaKind.logo,
          filePath: 'clinic-1/logo/logo.jpg',
        ),
        ClinicMediaModel(
          id: 'cover-1',
          clinicId: 'clinic-1',
          kind: MediaKind.cover,
          filePath: 'clinic-1/cover/cover.jpg',
        ),
      ],
      onboardingStatus: const OnboardingStatusModel(
        status: ClinicStatus.draft,
        basicData: OnboardingSectionStatus(complete: true),
        servicesFacilities: OnboardingSectionStatus(complete: true),
        adminLegal: OnboardingSectionStatus(complete: true),
        healthWorkers: OnboardingSectionStatus(complete: true),
      ),
    );
    fixture.profileRepository.submissionFailure =
        'Gagal mengirim untuk verifikasi.';

    await tester.tap(find.text('Kirim Pendaftaran untuk Verifikasi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Gagal mengirim untuk verifikasi.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'status media yang gagal disegarkan dilaporkan, bukan dianggap sukses',
      (tester) async {
    final fixture = await _pumpWizard(tester, step: 1);
    fixture.profileRepository.onboardingStatusFailure = 'status endpoint gagal';

    final refreshed = await fixture.clinicController.refreshMedia();

    expect(refreshed, isFalse);
    expect(
      fixture.clinicController.errorMessage,
      contains('status endpoint gagal'),
    );
  });

  testWidgets('perubahan media menunggu sinkronisasi dan menampilkan kegagalan',
      (tester) async {
    final themeController = ThemeController();
    addTearDown(themeController.dispose);
    final mediaRepository = FakeMediaRepository()
      ..mediaList = [
        const ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'clinic-1',
          kind: MediaKind.logo,
          filePath: 'clinic-1/logo/logo.jpg',
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(themeController.config, Brightness.light),
        home: Scaffold(
          body: PublicMediaUploader(
            clinicId: 'clinic-1',
            kind: MediaKind.logo,
            title: 'Logo',
            subtitle: 'Logo klinik',
            existingMedia: mediaRepository.mediaList,
            mediaRepo: mediaRepository,
            onChanged: () async => false,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.delete_outline).first);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus Media Publik?'), findsOneWidget);
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Perubahan tersimpan, tetapi status kelengkapan belum dapat diperbarui. Segarkan progres lalu coba kembali.',
      ),
      findsOneWidget,
    );
    expect(mediaRepository.mediaList, isEmpty);
  });
}
