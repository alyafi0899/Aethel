import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../core/l10n/terms_id.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/clinic/state/clinic_controller.dart';
import '../widgets/common.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final clinicCtrl = context.watch<ClinicController>();

    final desktop = Breakpoints.isDesktop(context);
    final String displayName =
        authCtrl.profile?.fullName ?? authCtrl.user?.email ?? 'Pengguna';
    final String clinicName = clinicCtrl.clinic?.clinicName ?? 'Klinik Anda';
    final clinicStatus = clinicCtrl.clinic?.status.userLabel ?? 'Memuat status';
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(clinicName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.sStrong),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.sSmall),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.c.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(clinicStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.sLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (desktop) ...[
            const SizedBox(width: 10),
            Avatar(initials, tone: Tone.navy),
          ],
        ],
      ),
    );
  }
}
