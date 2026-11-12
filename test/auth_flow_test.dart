import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/features/auth/data/auth_repository.dart';
import 'package:clinic_operations_platform/features/auth/state/auth_controller.dart';
import 'package:clinic_operations_platform/features/auth/ui/auth_gate.dart';
import 'package:clinic_operations_platform/features/auth/ui/login_page.dart';
import 'package:clinic_operations_platform/features/auth/ui/pending_verification_page.dart';
import 'package:clinic_operations_platform/features/auth/ui/register_clinic_page.dart';
import 'package:clinic_operations_platform/features/clinic/data/clinic_catalog_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/clinic_profile_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/document_repository.dart';
import 'package:clinic_operations_platform/features/clinic/data/staff_repository.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_member_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/profile_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/clinic/ui/onboarding_wizard_page.dart';
import 'package:clinic_operations_platform/features/clinic/widgets/document_upload_tile.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget createTestApp(Widget child,
    {AuthController? authCtrl, ClinicController? clinicCtrl}) {
  final fakeAuth = authCtrl ?? AuthController(repository: FakeAuthRepository());
  final fakeClinic = clinicCtrl ??
      ClinicController(
        profileRepo: FakeClinicProfileRepository(),
        catalogRepo: FakeClinicCatalogRepository(),
        staffRepo: FakeStaffRepository(),
        documentRepo: FakeDocumentRepository(),
        operationsRepo: FakeOperationsRepository(),
      );
  final themeCtrl = ThemeController();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeCtrl),
      ChangeNotifierProvider.value(value: fakeAuth),
      ChangeNotifierProvider.value(value: fakeClinic),
    ],
    child: MaterialApp(
      theme: AppTheme.build(themeCtrl.config, Brightness.light),
      home: child,
    ),
  );
}

void main() {
  group('Auth & Onboarding UI Tests', () {
    testWidgets('LoginPage renders form elements and validates empty input',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(const LoginPage()));
      await tester.pumpAndSettle();

      expect(find.text('Prometheon Clinic OS'), findsOneWidget);
      expect(find.text('Email Klinik / Pengelola'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);

      // Tap submit with empty fields
      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Email tidak boleh kosong.'), findsOneWidget);
      expect(find.text('Kata sandi tidak boleh kosong.'), findsOneWidget);
    });

    testWidgets('RegisterClinicPage renders clinic registration fields',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(const RegisterClinicPage()));
      await tester.pumpAndSettle();

      expect(find.text('Registrasi Operasional Klinik'), findsOneWidget);
      expect(find.text('Nama Resmi Klinik'), findsOneWidget);
      expect(find.text('Nama Lengkap Pendaftar / Penanggung Jawab'),
          findsOneWidget);
      expect(find.text('Daftarkan Klinik Sekarang'), findsOneWidget);
    });

    testWidgets('DocumentUploadTile renders correctly with fake repo',
        (tester) async {
      final fakeDocRepo = FakeDocumentRepository();

      await tester.pumpWidget(createTestApp(
        DocumentUploadTile(
          title: 'Unggah Surat Izin Operasional',
          subtitle: 'Scan SIO asli',
          clinicId: 'c1',
          docType: DocumentType.sio,
          isRequired: true,
          documentRepo: fakeDocRepo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Unggah Surat Izin Operasional'), findsOneWidget);
      expect(find.text('Wajib'), findsOneWidget);
      expect(find.text('Pilih & Unggah Berkas'), findsOneWidget);
    });

    testWidgets('AuthGate routes non-clinic account type correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final fakeAuthRepo = FakeAuthRepository();
      final user = User(
        id: 'u1',
        appMetadata: {},
        userMetadata: {'account_type': 'patient'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      fakeAuthRepo.setMockState(
        user: user,
        session: Session(accessToken: 'token', tokenType: 'bearer', user: user),
        profile: const ProfileModel(
          id: 'u1',
          fullName: 'Pasien Test',
          accountType: 'patient',
        ),
      );

      final authCtrl = AuthController(repository: fakeAuthRepo);
      await authCtrl.initSession();

      await tester
          .pumpWidget(createTestApp(const AuthGate(), authCtrl: authCtrl));
      await tester.pumpAndSettle();

      expect(find.text('Akun Ini Bukan Akun Pengelola Klinik'), findsOneWidget);
      expect(find.text('Keluar Akun'), findsOneWidget);
    });

    testWidgets('AuthGate routes draft clinic to OnboardingWizardPage',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
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
      fakeAuthRepo.setMockState(
        user: user,
        session: Session(accessToken: 'token', tokenType: 'bearer', user: user),
        profile: const ProfileModel(
          id: 'u1',
          fullName: 'Pengelola Klinik',
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
        status: ClinicStatus.draft,
        clinicName: 'Klinik Sehat Draf',
      );

      final authCtrl = AuthController(repository: fakeAuthRepo);
      await authCtrl.initSession();

      final clinicCtrl = ClinicController(
        profileRepo: fakeProfileRepo,
        catalogRepo: FakeClinicCatalogRepository(),
        staffRepo: FakeStaffRepository(),
        documentRepo: FakeDocumentRepository(),
        operationsRepo: FakeOperationsRepository(),
      );

      await tester.pumpWidget(
        createTestApp(const AuthGate(),
            authCtrl: authCtrl, clinicCtrl: clinicCtrl),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingWizardPage), findsOneWidget);
      expect(find.text('Langkah 1: Data Dasar Klinik'), findsOneWidget);
    });

    testWidgets('AuthGate routes submitted clinic to PendingVerificationPage',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
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
      fakeAuthRepo.setMockState(
        user: user,
        session: Session(accessToken: 'token', tokenType: 'bearer', user: user),
        profile: const ProfileModel(
          id: 'u1',
          fullName: 'Pengelola Klinik',
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
        status: ClinicStatus.submitted,
        clinicName: 'Klinik Menunggu Verifikasi',
      );

      final authCtrl = AuthController(repository: fakeAuthRepo);
      await authCtrl.initSession();

      final clinicCtrl = ClinicController(
        profileRepo: fakeProfileRepo,
        catalogRepo: FakeClinicCatalogRepository(),
        staffRepo: FakeStaffRepository(),
        documentRepo: FakeDocumentRepository(),
        operationsRepo: FakeOperationsRepository(),
      );

      await tester.pumpWidget(
        createTestApp(const AuthGate(),
            authCtrl: authCtrl, clinicCtrl: clinicCtrl),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PendingVerificationPage), findsOneWidget);
      expect(find.text('Pengajuan Berhasil Dikirim'), findsOneWidget);
    });

    testWidgets('AuthGate routes suspended clinic to suspended screen',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
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
      fakeAuthRepo.setMockState(
        user: user,
        session: Session(accessToken: 'token', tokenType: 'bearer', user: user),
        profile: const ProfileModel(
          id: 'u1',
          fullName: 'Pengelola Klinik',
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
        status: ClinicStatus.suspended,
        clinicName: 'Klinik Suspended',
      );

      final authCtrl = AuthController(repository: fakeAuthRepo);
      await authCtrl.initSession();

      final clinicCtrl = ClinicController(
        profileRepo: fakeProfileRepo,
        catalogRepo: FakeClinicCatalogRepository(),
        staffRepo: FakeStaffRepository(),
        documentRepo: FakeDocumentRepository(),
        operationsRepo: FakeOperationsRepository(),
      );

      await tester.pumpWidget(
        createTestApp(const AuthGate(),
            authCtrl: authCtrl, clinicCtrl: clinicCtrl),
      );
      await tester.pumpAndSettle();

      expect(find.text('Akun Klinik Ditangguhkan'), findsOneWidget);
      expect(find.text('Keluar Akun'), findsOneWidget);
    });
  });
}
