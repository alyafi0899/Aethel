import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
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
import 'package:clinic_operations_platform/features/clinic/models/clinic_member_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/state/clinic_controller.dart';
import 'package:clinic_operations_platform/features/operations/data/operations_repository.dart';
import 'package:clinic_operations_platform/features/operations/models/clinic_operations_models.dart';
import 'package:clinic_operations_platform/features/operations/ui/internal_operations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

ClinicController _createClinicController(
    FakeOperationsRepository operationsRepository) {
  return ClinicController(
    profileRepo: FakeClinicProfileRepository()
      ..mockClinic = const ClinicModel(
        id: 'clinic-1',
        ownerId: 'owner-1',
        status: ClinicStatus.verified,
        clinicName: 'Klinik Uji',
      ),
    catalogRepo: FakeClinicCatalogRepository(),
    staffRepo: FakeStaffRepository(),
    documentRepo: FakeDocumentRepository(),
    operationsRepo: operationsRepository,
    mediaRepo: FakeMediaRepository(),
    complianceRepo: FakeComplianceRepository(),
    reviewsRepo: FakeReviewsRepository(),
    feedbackRepo: FakeFeedbackRepository(),
    legalRepo: FakeLegalConsentRepository(),
  );
}

void main() {
  testWidgets('hanya owner/admin mengubah status dan antrean tetap read-only',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final theme = ThemeController();
    final operations = FakeOperationsRepository()
      ..internalOps = const ClinicOperationsInternalModel(
        clinicId: 'clinic-1',
        totalQueues: 12,
        currentQueueNumber: 5,
        averageWaitTime: 18,
      );
    final clinic = _createClinicController(operations);
    final staff = CurrentStaffController()
      ..syncMembership(const ClinicMemberModel(
        clinicId: 'clinic-1',
        userId: 'receptionist-1',
        role: ClinicRole.receptionist,
      ));
    await clinic.loadClinicData('clinic-1');
    addTearDown(() {
      theme.dispose();
      clinic.dispose();
      staff.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: clinic),
          ChangeNotifierProvider.value(value: staff),
        ],
        child: MaterialApp(
          theme: AppTheme.build(theme.config, Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: InternalOperationsPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buka'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Panggil nomor berikutnya'), findsNothing);
    expect(find.text('Buka alur antrean'), findsOneWidget);

    staff.syncMembership(const ClinicMemberModel(
      clinicId: 'clinic-1',
      userId: 'owner-1',
      role: ClinicRole.owner,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    expect(operations.updateCount, 1);
    expect(operations.internalOps.facilityStatus, FacilityOperatingStatus.open);
    expect(
        operations.internalOps.queueProcessStatus, QueueProcessStatus.active);
    expect(operations.internalOps.totalQueues, 12);
    expect(operations.internalOps.currentQueueNumber, 5);
    expect(operations.internalOps.averageWaitTime, 18);
  });
}
