import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/context_ext.dart';
import '../../../shell/app_shell.dart';

import '../../../widgets/buttons.dart';
import '../../clinic/models/clinic_enums.dart';
import '../../clinic/state/clinic_controller.dart';
import '../../clinic/ui/onboarding_wizard_page.dart';
import '../state/auth_controller.dart';
import 'login_page.dart';
import 'pending_verification_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadedUserId;

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final clinicCtrl = context.watch<ClinicController>();

    // 1. Loading state -> Splash screen
    if (authCtrl.loading) {
      return const _BrandSplashScreen(message: 'Memuat sesi autentikasi...');
    }

    // 2. Unauthenticated -> Login Page
    if (!authCtrl.isAuthenticated) {
      _loadedUserId = null;
      return const LoginPage();
    }

    // 3. Check account type
    final profile = authCtrl.profile;
    if (profile != null && !profile.isClinicAccount) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_accounts_outlined, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Akun Ini Bukan Akun Pengelola Klinik',
                  style: context.sH2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Akun dengan email (${profile.fullName ?? authCtrl.user?.email}) terdaftar sebagai tipe "${profile.accountType}". Tahap ini khusus untuk pengelola klinik.',
                  style: context.sBodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Keluar Akun',
                  icon: Icons.logout,
                  onPressed: () => authCtrl.signOut(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Trigger loading clinic for current user if not loaded
    final uid = authCtrl.user?.id;
    if (uid != null && _loadedUserId != uid) {
      _loadedUserId = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ClinicController>().loadClinicForUser(uid);
      });
      return const _BrandSplashScreen(message: 'Memuat profil klinik...');
    }

    if (clinicCtrl.loading && clinicCtrl.clinic == null) {
      return const _BrandSplashScreen(message: 'Menyiapkan data klinik...');
    }

    final clinic = clinicCtrl.clinic;
    if (clinic == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Data Klinik Tidak Ditemukan', style: context.sH2),
                const SizedBox(height: 8),
                Text(
                  clinicCtrl.errorMessage ?? 'Tidak dapat menemukan data pendaftaran klinik untuk akun ini.',
                  style: context.sBodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      label: 'Coba Lagi',
                      icon: Icons.refresh,
                      onPressed: () {
                        if (uid != null) {
                          clinicCtrl.loadClinicForUser(uid);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Keluar',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => authCtrl.signOut(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 5. Route based on clinic status
    final status = clinic.status;

    switch (status) {
      case ClinicStatus.draft:
      case ClinicStatus.rejected:
        return OnboardingWizardPage(
          rejectionReason: status == ClinicStatus.rejected ? clinic.rejectionReason : null,
        );
      case ClinicStatus.submitted:
      case ClinicStatus.under_review:
        return const PendingVerificationPage();
      case ClinicStatus.verified:
        return const AppShell();
      case ClinicStatus.suspended:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Akun Klinik Ditangguhkan', style: context.sH2),
                  const SizedBox(height: 8),
                  Text(
                    'Pendaftaran operasional klinik ini telah ditangguhkan oleh administrator platform. Silakan hubungi dukungan Prometheon Clinic OS.',
                    style: context.sBodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Keluar Akun',
                    icon: Icons.logout,
                    onPressed: () => authCtrl.signOut(),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _BrandSplashScreen extends StatelessWidget {
  const _BrandSplashScreen({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.health_and_safety, size: 48, color: c.accent),
            ),
            const SizedBox(height: 24),
            Text(
              'PROMETHEON',
              style: context.sH2.copyWith(
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'CLINIC OS',
              style: context.sLabel.copyWith(
                color: c.muted,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: context.sBodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
