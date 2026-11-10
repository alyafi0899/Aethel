import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
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
import '../pages/login_page.dart';
import '../pages/services_page.dart';
import '../pages/settings_page.dart';
import '../pages/triage_page.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import 'app_header.dart';
import 'sidebar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();

    if (!ctrl.isLoggedIn) {
      return const LoginPage();
    }

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
