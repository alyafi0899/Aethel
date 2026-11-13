import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/terms_id.dart';
import '../../../core/theme/context_ext.dart';
import '../../../state/app_controller.dart';
import 'compliance_page.dart';
import 'onboarding_wizard_page.dart';
import '../../operations/ui/public_operations_page.dart';

class ProfileLegalPage extends StatefulWidget {
  const ProfileLegalPage({super.key});

  @override
  State<ProfileLegalPage> createState() => _ProfileLegalPageState();
}

class _ProfileLegalPageState extends State<ProfileLegalPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _lastRequestedIndex = -1;

  static const _titles = [
    'Profil Klinik',
    'Layanan & Fasilitas',
    'Dokumen & Legal',
    kEmrSectionLabel,
    'Tampilan Publik',
    'Kepatuhan',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _titles.length, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final requestedIndex = context.read<AppController>().profileTab;
    if (_lastRequestedIndex != requestedIndex && !_tabs.indexIsChanging) {
      _lastRequestedIndex = requestedIndex;
      _tabs.animateTo(requestedIndex.clamp(0, _titles.length - 1));
    }
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    _lastRequestedIndex = _tabs.index;
    context.read<AppController>().selectProfileTab(_tabs.index);
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profil & Legal', style: context.sH2),
        const SizedBox(height: 4),
        Text('Atur informasi yang dibutuhkan untuk mengelola klinik.',
            style: context.sSmall),
        const SizedBox(height: 16),
        Material(
          color: context.c.surface,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: [for (final title in _titles) Tab(text: title)],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: switch (_tabs.index) {
            0 => const OnboardingWizardPage(),
            1 => const OnboardingWizardPage(initialStep: 2),
            2 => const OnboardingWizardPage(initialStep: 3),
            3 => const OnboardingWizardPage(
                initialStep: 4,
                showRmeSettings: true,
              ),
            4 => const PublicOperationsPage(),
            5 => const CompliancePage(),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}
