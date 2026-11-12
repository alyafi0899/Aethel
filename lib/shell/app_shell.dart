import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/legal_consent_dialog.dart';
import '../features/clinic/data/legal_consent_repository.dart';
import '../features/clinic/state/clinic_controller.dart';
import '../features/clinic/ui/compliance_page.dart';
import '../features/clinic/ui/feedback/clinic_feedback_page.dart';
import '../features/clinic/ui/health_workers/health_worker_list_page.dart';
import '../features/clinic/ui/onboarding_wizard_page.dart';
import '../features/clinic/ui/reviews/clinic_reviews_page.dart';
import '../features/operations/ui/internal_operations_page.dart';
import '../features/operations/ui/public_operations_page.dart';
import '../pages/appointments_page.dart';
import '../pages/consultations_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/doctors_page.dart';
import '../pages/finance_page.dart';
import '../pages/marketplace_page.dart';
import '../pages/notifications_page.dart';
import '../pages/operations_page.dart';
import '../pages/patients_page.dart';
import '../pages/permissions_page.dart';
import '../pages/placeholder_page.dart';
import '../pages/reports_page.dart';
import '../pages/resources_page.dart';
import '../pages/services_page.dart';
import '../pages/settings_page.dart';
import '../pages/triage_page.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import 'app_header.dart';
import 'sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _checkedConsent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedConsent) {
      _checkLegalConsents();
      _checkedConsent = true;
    }
  }

  void _checkLegalConsents() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clinicCtrl = context.read<ClinicController>();
      final authCtrl = context.read<AuthController>();
      final uid = authCtrl.user?.id;
      if (uid != null) {
        final hasTerms = clinicCtrl.userConsents.any(
          (c) =>
              c.documentType == 'terms' && c.documentVersion == kLegalVersion,
        );
        final hasPrivacy = clinicCtrl.userConsents.any(
          (c) =>
              c.documentType == 'privacy' && c.documentVersion == kLegalVersion,
        );

        if (!hasTerms || !hasPrivacy) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const LegalConsentDialog(),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final clinicCtrl = context.watch<ClinicController>();
    final compliance = clinicCtrl.complianceStatus;

    if (ctrl.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (ctrl.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load clinic data', style: context.sH2),
              const SizedBox(height: 6),
              Text('${ctrl.error}', style: context.sSmall),
              const SizedBox(height: 14),
              AppButton('Retry', kind: BtnKind.primary, onPressed: ctrl.load),
            ],
          ),
        ),
      );
    }

    final desktop = Breakpoints.isDesktop(context);

    final content = Column(
      children: [
        const AppHeader(),

        // Global Compliance Alert Banners
        if (!compliance.sioValid || compliance.hasCriticalAlerts)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.red.shade900,
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SIO Klinik Sudah Kedaluwarsa! Klinik disembunyikan dari publik dan tidak dapat dipublikasikan sampai SIO diperbarui.',
                    style: context.sBody.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                AppButton(
                  'Lihat Halaman Kepatuhan',
                  kind: BtnKind.secondary,
                  compact: true,
                  onPressed: () => ctrl.go(AppPage.clinicCompliance),
                ),
              ],
            ),
          )
        else if (compliance.hasWarningAlerts)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.amber.shade900,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Terdapat peringatan masa berlaku perizinan (SIO/STR/SIP) yang akan segera berakhir.',
                    style: context.sBody
                        .copyWith(color: Colors.white, fontSize: 12),
                  ),
                ),
                AppButton(
                  'Periksa',
                  kind: BtnKind.secondary,
                  compact: true,
                  onPressed: () => ctrl.go(AppPage.clinicCompliance),
                ),
              ],
            ),
          ),

        Expanded(child: _PageBody(page: ctrl.page)),
      ],
    );

    if (desktop) {
      return Scaffold(
        body: Row(
          children: [
            const Sidebar(),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        width: 254,
        backgroundColor: context.c.sidebar,
        shape: const RoundedRectangleBorder(),
        child: Builder(
          builder: (ctx) => Sidebar(
            onNavigate: () => Navigator.of(ctx).pop(),
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
      body: content,
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});
  final AppPage page;

  Widget _page() {
    switch (page) {
      // KLINIK Group
      case AppPage.clinicProfile:
      case AppPage.clinicServices:
      case AppPage.clinicLegal:
      case AppPage.clinicEmr:
        return const OnboardingWizardPage();
      case AppPage.clinicStaff:
        return const HealthWorkerListPage();
      case AppPage.clinicOperationsInternal:
        return const InternalOperationsPage();
      case AppPage.clinicOperationsPublic:
        return const PublicOperationsPage();
      case AppPage.clinicReviews:
        return const ClinicReviewsPage();
      case AppPage.clinicFeedback:
        return const ClinicFeedbackPage();
      case AppPage.clinicCompliance:
        return const CompliancePage();

      // Demo Pages
      case AppPage.dashboard:
        return const DashboardPage();
      case AppPage.operations:
        return const OperationsPage();
      case AppPage.appointments:
        return const AppointmentsPage();
      case AppPage.triage:
        return const TriagePage();
      case AppPage.doctors:
        return const DoctorsPage();
      case AppPage.rooms:
        return const ResourcesPage();
      case AppPage.notifications:
        return const NotificationsPage();
      case AppPage.billing:
        return const FinancePage();
      case AppPage.reports:
        return const ReportsPage();
      case AppPage.patients:
        return const PatientsPage();
      case AppPage.services:
        return const ServicesPage();
      case AppPage.consultations:
        return const ConsultationsPage();
      case AppPage.publicProfile:
        return const MarketplacePage();
      case AppPage.roles:
        return const PermissionsPage();
      case AppPage.settings:
        return const SettingsPage();
      case AppPage.workflow:
      case AppPage.nurses:
      case AppPage.membership:
      case AppPage.scheduling:
      case AppPage.reviews:
        return PlaceholderPage(page: page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.isPhone(context);
    return SingleChildScrollView(
      key: ValueKey(page),
      padding: EdgeInsets.fromLTRB(
        phone ? 13 : 30,
        phone ? 20 : 27,
        phone ? 13 : 30,
        50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: _page(),
        ),
      ),
    );
  }
}
