import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/auth/state/current_staff_controller.dart';
import '../features/auth/ui/legal_consent_dialog.dart';
import '../features/clinic/data/legal_consent_repository.dart';
import '../features/clinic/state/clinic_controller.dart';
import '../features/clinic/ui/compliance_page.dart';
import '../features/clinic/ui/clinic_settings_page.dart';
import '../features/clinic/ui/feedback/clinic_feedback_page.dart';
import '../features/clinic/ui/health_workers/health_worker_list_page.dart';
import '../features/clinic/ui/home_page.dart';
import '../features/clinic/ui/onboarding_wizard_page.dart';
import '../features/clinic/ui/profile_legal_page.dart';
import '../features/clinic/ui/reviews_feedback_page.dart';
import '../features/operations/ui/internal_operations_page.dart';
import '../features/operations/ui/public_operations_page.dart';
import '../features/operations/ui/visit_flow_page.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
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
              Text('Data klinik belum dapat dimuat', style: context.sH2),
              const SizedBox(height: 6),
              Text('Periksa koneksi internet, lalu coba lagi.',
                  style: context.sSmall),
              const SizedBox(height: 14),
              AppButton('Coba lagi',
                  kind: BtnKind.primary, onPressed: ctrl.load),
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
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileIndex(ctrl.page),
        onDestinationSelected: (index) {
          if (index == 4) {
            _showMoreSheet(context, ctrl);
            return;
          }
          ctrl.go([
            AppPage.dashboard,
            AppPage.clinicOperationsInternal,
            AppPage.clinicStaff,
            AppPage.clinicReviews,
          ][index]);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.health_and_safety_outlined),
              label: 'Operasional'),
          NavigationDestination(
              icon: Icon(Icons.badge_outlined), label: 'Tenaga'),
          NavigationDestination(
              icon: Icon(Icons.rate_review_outlined), label: 'Ulasan'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Lainnya'),
        ],
      ),
    );
  }

  int _mobileIndex(AppPage page) => switch (page) {
        AppPage.dashboard => 0,
        AppPage.clinicOperationsInternal => 1,
        AppPage.clinicStaff => 2,
        AppPage.clinicReviews || AppPage.clinicFeedback => 3,
        _ => 4,
      };

  void _showMoreSheet(BuildContext context, AppController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Profil & Legal'),
              onTap: () {
                Navigator.pop(context);
                controller.go(AppPage.clinicProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
                controller.go(AppPage.settings);
              },
            ),
          ],
        ),
      ),
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
        return const ProfileLegalPage();
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
        return const ReviewsFeedbackPage();
      case AppPage.clinicFeedback:
        return const ClinicFeedbackPage();
      case AppPage.clinicCompliance:
        return const CompliancePage();

      // Demo Pages
      case AppPage.dashboard:
        return const HomePage();
      case AppPage.operations:
        return const InternalOperationsPage();
      case AppPage.appointments:
        return const VisitFlowPage(initialView: VisitFlowView.queue);
      case AppPage.triage:
        return const VisitFlowPage(initialView: VisitFlowView.triage);
      case AppPage.doctors:
      case AppPage.nurses:
      case AppPage.membership:
        return const HealthWorkerListPage();
      case AppPage.rooms:
        return const ProfileLegalPage();
      case AppPage.notifications:
        return const VisitFlowPage(initialView: VisitFlowView.inbox);
      case AppPage.billing:
        return const VisitFlowPage(initialView: VisitFlowView.billing);
      case AppPage.reports:
        return const VisitFlowPage(initialView: VisitFlowView.billing);
      case AppPage.patients:
        return const VisitFlowPage(initialView: VisitFlowView.patients);
      case AppPage.services:
        return const ProfileLegalPage();
      case AppPage.consultations:
        return const VisitFlowPage(initialView: VisitFlowView.consultations);
      case AppPage.publicProfile:
        return const PublicOperationsPage();
      case AppPage.roles:
        return const _StaffAccessPage();
      case AppPage.settings:
        return const ClinicSettingsPage();
      case AppPage.workflow:
        return const VisitFlowPage();
      case AppPage.scheduling:
        return const VisitFlowPage(initialView: VisitFlowView.queue);
      case AppPage.reviews:
        return const ReviewsFeedbackPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.isPhone(context);
    if (const {
      AppPage.dashboard,
      AppPage.clinicProfile,
      AppPage.rooms,
      AppPage.services,
      AppPage.clinicReviews,
      AppPage.settings,
      AppPage.clinicOperationsInternal,
    }.contains(page)) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          phone ? 13 : 30,
          phone ? 20 : 27,
          phone ? 13 : 30,
          20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: _page(),
          ),
        ),
      );
    }
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

class _StaffAccessPage extends StatelessWidget {
  const _StaffAccessPage();

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<CurrentStaffController>();
    final access = staff.access;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Peran & Akses',
          desc:
              'Hak akses ditetapkan oleh keanggotaan klinik dan kebijakan server.',
        ),
        AppCard(
          child: access == null
              ? const Text('Keanggotaan klinik belum tersedia.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peran: ${access.role}'),
                    const SizedBox(height: 8),
                    Text(
                      'Akses klinis: ${access.clinicalAccess ? 'Diaktifkan' : 'Tidak diaktifkan'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Akses baca data klinis: ${access.canViewClinical ? 'Diizinkan' : 'Tidak diizinkan'}',
                    ),
                    Text(
                      'Bertindak sebagai dokter: ${access.canActAsDoctor ? 'Diizinkan' : 'Tidak diizinkan'}',
                    ),
                    Text(
                      'Pengelolaan tagihan: ${access.canManageBilling ? 'Diizinkan' : 'Tidak diizinkan'}',
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
