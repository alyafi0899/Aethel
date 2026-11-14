import 'package:clinic_operations_platform/core/theme/app_theme.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/domain/clinic_repositories.dart';
import 'package:clinic_operations_platform/domain/models.dart';
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
import 'package:clinic_operations_platform/features/operations/ui/visit_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _WorkflowRepository implements ClinicWorkflowRepository {
  Visit visit = const Visit(
    encounterId: 'encounter-1',
    clinicId: 'clinic-1',
    reference: 'VIS-1001',
    stage: VisitStage.registered,
    patientName: 'Pasien Uji',
    medicalRecordNo: 'RM-000001',
  );
  int checkInCount = 0;
  List<Invoice> invoices = [];
  int updateInvoiceItemsCount = 0;
  List<InvoiceItem> updatedItems = [];
  String? visitBoardFailure;

  @override
  Future<List<Visit>> loadVisitBoard(String clinicId) async {
    final failure = visitBoardFailure;
    if (failure != null) throw ClinicRepositoryException(failure);
    return [visit];
  }

  @override
  Future<List<Invoice>> loadInvoices(String clinicId) async => invoices;

  @override
  Future<Visit> checkIn(String encounterId) async {
    checkInCount += 1;
    visit = Visit(
      encounterId: visit.encounterId,
      clinicId: visit.clinicId,
      reference: visit.reference,
      stage: VisitStage.checkedIn,
      patientName: visit.patientName,
      medicalRecordNo: visit.medicalRecordNo,
    );
    return visit;
  }

  @override
  Future<Map<String, dynamic>> updateInvoiceItems(
    String encounterId,
    List<InvoiceItem> items, {
    int? discount,
  }) async {
    updateInvoiceItemsCount += 1;
    updatedItems = items;
    return {'encounter_id': encounterId, 'discount': discount};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('alur kunjungan menampilkan data server dan menjalankan check-in',
      (tester) async {
    final theme = ThemeController();
    final clinicProfile = FakeClinicProfileRepository()
      ..mockClinic = const ClinicModel(
        id: 'clinic-1',
        ownerId: 'owner-1',
        status: ClinicStatus.verified,
        clinicName: 'Klinik Uji',
      );
    final clinic = ClinicController(
      profileRepo: clinicProfile,
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
    final staff = CurrentStaffController()
      ..syncMembership(const ClinicMemberModel(
        clinicId: 'clinic-1',
        userId: 'receptionist-1',
        role: ClinicRole.receptionist,
      ));
    final repository = _WorkflowRepository();
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisitFlowPage(repository: repository),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pasien Uji'), findsOneWidget);
    expect(find.text('Terdaftar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Check-in'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Check-in'));
    await tester.pumpAndSettle();

    expect(repository.checkInCount, 1);
    expect(find.widgetWithText(OutlinedButton, 'Check-in'), findsNothing);
    expect(
        find.widgetWithText(OutlinedButton, 'Skrining awal'), findsOneWidget);

    repository.visitBoardFailure = 'not_authorized';
    await tester.tap(find.text('Muat ulang'));
    await tester.pumpAndSettle();
    expect(find.text('Akses Anda tidak mencakup data ini.'), findsOneWidget);
    expect(find.text('Pasien Uji'), findsNothing);
  });

  testWidgets('rincian tagihan draf disimpan melalui repository',
      (tester) async {
    final theme = ThemeController();
    final clinicProfile = FakeClinicProfileRepository()
      ..mockClinic = const ClinicModel(
        id: 'clinic-1',
        ownerId: 'owner-1',
        status: ClinicStatus.verified,
        clinicName: 'Klinik Uji',
      );
    final clinic = ClinicController(
      profileRepo: clinicProfile,
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
    final staff = CurrentStaffController()
      ..syncMembership(const ClinicMemberModel(
        clinicId: 'clinic-1',
        userId: 'cashier-1',
        role: ClinicRole.cashier,
      ));
    final repository = _WorkflowRepository()
      ..invoices = const [
        Invoice(
          id: 'invoice-1',
          clinicId: 'clinic-1',
          encounterId: 'encounter-1',
          reference: 'INV-1001',
          status: InvoiceState.draft,
          subtotal: 30000,
          total: 30000,
          items: [
            InvoiceItem(
              description: 'Konsultasi',
              quantity: 1,
              unitPrice: 30000,
              itemType: 'service',
            ),
          ],
        ),
      ];
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
          home: Scaffold(
            body: VisitFlowPage(
              initialView: VisitFlowView.billing,
              repository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ubah rincian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan rincian'));
    await tester.pumpAndSettle();

    expect(repository.updateInvoiceItemsCount, 1);
    expect(repository.updatedItems.single.description, 'Konsultasi');
    expect(repository.updatedItems.single.itemType, 'service');
  });
}
