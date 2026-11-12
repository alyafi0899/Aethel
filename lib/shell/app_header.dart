import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/clinic/state/clinic_controller.dart';
import '../sheets/quick_action_dialog.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final authCtrl = context.watch<AuthController>();
    final clinicCtrl = context.watch<ClinicController>();

    final desktop = Breakpoints.isDesktop(context);
    final width = MediaQuery.sizeOf(context).width;

    final String displayName = authCtrl.profile?.fullName ??
        authCtrl.user?.email ??
        ctrl.activeUserName;
    final String clinicName =
        clinicCtrl.clinic?.clinicName ?? ctrl.data.facilityName;
    final String initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'KU';

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 15),
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(bottom: BorderSide(color: context.c.border)),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            AppIconButton(
              AppIcons.menu,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width * .4 < 440 ? 440 : 440,
              ),
              child: SearchBox(
                hint: 'Cari pasien, janji temu, dokter...',
                onChanged: ctrl.setSearch,
                trailing: desktop
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.c.surface,
                          border: Border.all(color: context.c.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⌘ K',
                          style: context.sSmall.copyWith(fontSize: 9),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (desktop) ...[
            AppButton(
              'Aksi Cepat',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
              onPressed: () => QuickActionDialog.show(context),
            ),
            const SizedBox(width: 12),
          ],
          AppIconButton(
            AppIcons.bell,
            dot: ctrl.notifCount > 0,
            onPressed: () {
              ctrl.clearNotifBadge();
              ctrl.go(AppPage.notifications);
            },
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Profil Pengguna & Sesi',
            color: context.c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.m.radiusSm),
              side: BorderSide(color: context.c.border),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                authCtrl.signOut();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: context.sStrong),
                    const SizedBox(height: 2),
                    Text(clinicName,
                        style:
                            context.sSmall.copyWith(color: context.c.accent)),
                    const Divider(),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(AppIcons.alert,
                        size: 16, color: context.c.fg(Tone.red)),
                    const SizedBox(width: 8),
                    Text(
                      'Keluar (Logout)',
                      style: context.sBody.copyWith(
                        color: context.c.fg(Tone.red),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: EdgeInsets.only(left: desktop ? 14 : 0),
              decoration: BoxDecoration(
                border: desktop
                    ? Border(left: BorderSide(color: context.c.border))
                    : null,
              ),
              child: Row(
                children: [
                  Avatar(initials, tone: Tone.navy),
                  if (desktop) ...[
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(displayName, style: context.sStrong),
                        const SizedBox(height: 2),
                        Text(clinicName,
                            style: context.sSmall
                                .copyWith(color: context.c.accent)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Icon(AppIcons.chevronDown,
                        size: 16, color: context.c.muted),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
