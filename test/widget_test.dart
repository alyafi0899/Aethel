import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_config.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/data/clinic_repository.dart';
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
import 'package:clinic_operations_platform/features/clinic/models/onboarding_status_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/clinic/ui/home_page.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:clinic_operations_platform/state/app_controller.dart';
import 'package:clinic_operations_platform/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AppCard provides Material for interactive ListTile ink',
      (tester) async {
    final themeController = ThemeController(
      kInitialThemeConfig.copyWith(useGoogleFonts: false),
    );
    addTearDown(themeController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(themeController.config, Brightness.light),
        home: const Scaffold(
          body: AppCard(
            child: ListTile(
              title: Text('Pengaturan'),
              onTap: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('clinic home suggestions can be hidden and persist per clinic',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'clinic_home_guide_seen_c1': true,
    });
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final profileRepository = FakeClinicProfileRepository()
      ..mockClinic = const ClinicModel(
        id: 'c1',
        ownerId: 'u1',
        status: ClinicStatus.verified,
        clinicName: 'Klinik Contoh',
      )
      ..mockOnboardingStatus = const OnboardingStatusModel(
        status: ClinicStatus.verified,
        recommendations: ['media:gallery'],
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
    await clinicController.loadClinicData('c1');
    final themeController = ThemeController(
      kInitialThemeConfig.copyWith(useGoogleFonts: false),
    );
    addTearDown(clinicController.dispose);
    addTearDown(themeController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeController),
          ChangeNotifierProvider.value(
            value: AppController(const MockClinicRepository()),
          ),
          ChangeNotifierProvider.value(value: clinicController),
        ],
        child: MaterialApp(
          theme: AppTheme.build(themeController.config, Brightness.light),
          home: const Scaffold(body: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Klinik Contoh'), findsOneWidget);
    expect(find.text('Tambah foto galeri'), findsOneWidget);

    final hideRecommendation = find.byTooltip('Sembunyikan saran').last;
    await tester.ensureVisible(hideRecommendation);
    await tester.pumpAndSettle();
    await tester.tap(hideRecommendation);
    await tester.pumpAndSettle();

    expect(find.text('Tambah foto galeri'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        'clinic_home_recommendation_hidden_c1_media:gallery',
      ),
      isTrue,
    );
  });
}

void _noop() {}
