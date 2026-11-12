import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/clinic/state/clinic_controller.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, this.onNavigate, this.onClose});

  /// Called after a nav item is tapped (the mobile drawer closes itself).
  final VoidCallback? onNavigate;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final authCtrl = context.watch<AuthController>();
    final clinicCtrl = context.watch<ClinicController>();

    final c = context.c;
    final data = ctrl.data;

    final String clinicName =
        clinicCtrl.clinic?.clinicName ?? data.facilityName;
    final String roleLabel = authCtrl.membership?.role.label ??
        authCtrl.profile?.accountType.toUpperCase() ??
        ctrl.activeUserRole;

    return Container(
      width: 254,
      color: c.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            _Brand(onClose: onClose),
            _FacilityCard(name: clinicName, roleLabel: roleLabel),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 25),
                children: [
                  for (final section in ctrl.navSections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 13, 10, 5),
                      child: Text(
                        section.title,
                        style: context.sLabel.copyWith(
                          color: c.sidebarMuted,
                          letterSpacing: 1.2,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    for (final page in section.pages)
                      _NavItem(
                        page: page,
                        active: ctrl.page == page,
                        badge: data.navBadges[page],
                        onTap: () {
                          if (page == AppPage.notifications) {
                            ctrl.clearNotifBadge();
                          }
                          ctrl.go(page);
                          onNavigate?.call();
                        },
                      ),
                  ],
                ],
              ),
            ),
            const _HelpCard(),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final teal = ClinicColors.lighten(c.accent, .12);
    final blue = ClinicColors.lighten(c.primary, .18);

    Widget bar(double w, double h, Color color) => Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              children: [
                Positioned(left: 5, top: 0, child: bar(8, 20, teal)),
                Positioned(right: 4, bottom: 0, child: bar(8, 20, blue)),
                Positioned(left: 0, bottom: 4, child: bar(20, 8, teal)),
                Positioned(right: 0, top: 4, child: bar(20, 8, blue)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROMETHEON',
                  style: context.tt.titleSmall!.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CLINIC OS',
                  style: context.sLabel.copyWith(
                    color: const Color(0xFF7F92A7),
                    letterSpacing: 2.2,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null) CloseIconButton(onPressed: onClose!),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.name, required this.roleLabel});
  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        border: Border.all(color: const Color(0x15FFFFFF)),
        borderRadius: BorderRadius.circular(context.m.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.sidebarActive,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              AppIcons.building,
              size: 17,
              color: ClinicColors.lighten(c.accent, .12),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel.toUpperCase(),
                  style: context.sLabel.copyWith(
                    color: const Color(0xFF71859A),
                    fontSize: 8.5,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.sStrong.copyWith(
                    color: const Color(0xFFECF4FA),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.page,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final AppPage page;
  final bool active;
  final NavBadge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = ClinicColors.lighten(c.accent, .1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Material(
          color: active ? c.sidebarActive : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: c.sidebarActive.withValues(alpha: .6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 36,
                  color: active ? accent : Colors.transparent,
                ),
                const SizedBox(width: 7),
                Icon(
                  page.icon,
                  size: 18,
                  color: active ? accent : const Color(0xFF71869A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    page.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.sBody.copyWith(
                      color: active ? Colors.white : c.sidebarText,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badge!.alert
                          ? const Color(0xFFD94F54)
                          : const Color(0xFF26394A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!.text,
                      style: context.tt.labelSmall!.copyWith(
                        color: badge!.alert
                            ? Colors.white
                            : const Color(0xFFAEBDCA),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF182A3D),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(context.m.radius),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.shield, size: 18, color: Color(0xFF7BD5CC)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dukungan Sistem',
                  style: context.sStrong.copyWith(
                    color: const Color(0xFFD8E3EC),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bantuan Prometheon OS',
                  style: context.sSmall.copyWith(
                    color: const Color(0xFF71859A),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.chevron, size: 14, color: Color(0xFF71859A)),
        ],
      ),
    );
  }
}
