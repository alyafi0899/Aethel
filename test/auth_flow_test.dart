import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/features/auth/data/auth_repository.dart';
import 'package:clinic_operations_platform/features/auth/state/auth_controller.dart';
import 'package:clinic_operations_platform/features/auth/ui/login_page.dart';
import 'package:clinic_operations_platform/features/auth/ui/register_clinic_page.dart';
import 'package:clinic_operations_platform/features/clinic/data/document_repository.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/clinic/widgets/document_upload_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget createTestApp(Widget child,
    {AuthController? authCtrl, ClinicController? clinicCtrl}) {
  final fakeAuth = authCtrl ?? AuthController(repository: FakeAuthRepository());
  final fakeClinic = clinicCtrl ?? ClinicController();
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
  });
}
