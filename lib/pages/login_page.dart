import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/feature_flags.dart';
import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/register_clinic_page.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/forms.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserRole _selectedRole = UserRole.admin;
  bool _loading = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(
          () => _errorMessage = 'Isi email dan kata sandi terlebih dahulu.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final success = await auth.signIn(email: email, password: pass);
    if (mounted) {
      setState(() {
        _loading = false;
        if (!success) {
          _errorMessage =
              auth.errorMessage ?? 'Tidak dapat masuk. Silakan coba lagi.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final phone = Breakpoints.isPhone(context);
    return Scaffold(
      backgroundColor: c.sidebar,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: phone ? 16 : 24,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(context.m.radiusLg),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Branding Header
                  if (kUseMockData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      color: c.sidebar,
                      child: Column(
                        children: [
                          const _LogoIcon(),
                          const SizedBox(height: 14),
                          Text(
                            'PROMETHEON CLINIC OS',
                            style: context.tt.titleMedium!.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Administrasi dan operasional klinik',
                            style: context.sSmall.copyWith(
                              color: const Color(0xFF7F92A7),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kUseMockData) ...[
                          Text(
                            'Pilih peran demo',
                            style: context.sLabel.copyWith(
                              letterSpacing: 1.1,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Role Selection Tabs (Admin vs Nurse)
                          Row(
                            children: [
                              Expanded(
                                child: _RoleTab(
                                  role: UserRole.admin,
                                  active: _selectedRole == UserRole.admin,
                                  onTap: () => _onRoleChanged(UserRole.admin),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleTab(
                                  role: UserRole.nurse,
                                  active: _selectedRole == UserRole.nurse,
                                  onTap: () => _onRoleChanged(UserRole.nurse),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Role Description Badge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.soft(_selectedRole.tone),
                              borderRadius:
                                  BorderRadius.circular(context.m.radiusSm),
                              border: Border.all(
                                color: c
                                    .fg(_selectedRole.tone)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedRole.isAdmin
                                      ? AppIcons.shield
                                      : AppIcons.nurse,
                                  size: 18,
                                  color: c.fg(_selectedRole.tone),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedRole.description,
                                    style: context.sSmall.copyWith(
                                      color: c.fg(_selectedRole.tone),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Quick 1-Click Demo Logins
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius:
                                BorderRadius.circular(context.m.radiusSm),
                            border: Border.all(color: c.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AKSES DEMO',
                                style: context.sLabel.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      'Masuk sebagai admin',
                                      icon: AppIcons.shield,
                                      kind: BtnKind.primary,
                                      onPressed: () => context
                                          .read<AppController>()
                                          .loginAsRole(UserRole.admin),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppButton(
                                      'Masuk sebagai perawat',
                                      icon: AppIcons.plus,
                                      kind: BtnKind.secondary,
                                      onPressed: () => context
                                          .read<AppController>()
                                          .loginAsRole(UserRole.nurse),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'ATAU MASUK DENGAN SUPABASE',
                                style: context.sSmall.copyWith(fontSize: 10),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: c.soft(Tone.red),
                              borderRadius:
                                  BorderRadius.circular(context.m.radiusSm),
                            ),
                            child: Row(
                              children: [
                                Icon(AppIcons.alert,
                                    size: 16, color: c.fg(Tone.red)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: context.sSmall.copyWith(
                                      color: c.fg(Tone.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        FormField2(
                          'Email Klinik / Pengelola',
                          child: AppTextField(
                            controller: _emailCtrl,
                            hint: 'nama@klinik.id',
                          ),
                        ),
                        const SizedBox(height: 12),

                        FormField2(
                          'Kata Sandi',
                          child: AppTextField(
                            controller: _passCtrl,
                            obscureText: true,
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            _loading ? 'Memeriksa...' : 'Masuk Sekarang',
                            kind: BtnKind.primary,
                            onPressed: _loading ? null : _handleSubmit,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterClinicPage(),
                              ),
                            ),
                            child: Text(
                              'Belum memiliki akun? Daftarkan klinik',
                              style: context.sSmall.copyWith(
                                color: c.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.role,
    required this.active,
    required this.onTap,
  });

  final UserRole role;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = active ? c.fg(role.tone) : c.text;
    final bg = active ? c.soft(role.tone) : c.surface;
    final border = active ? c.fg(role.tone) : c.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.m.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: active ? 1.5 : 1),
          borderRadius: BorderRadius.circular(context.m.radiusSm),
        ),
        child: Column(
          children: [
            Icon(
              role.isAdmin ? AppIcons.shield : AppIcons.nurse,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              role.isAdmin ? 'Admin Role' : 'Nurse Role',
              style: context.sStrong.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();

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

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        children: [
          Positioned(left: 7, top: 0, child: bar(11, 28, teal)),
          Positioned(right: 6, bottom: 0, child: bar(11, 28, blue)),
          Positioned(left: 0, bottom: 6, child: bar(28, 11, teal)),
          Positioned(right: 0, top: 6, child: bar(28, 11, blue)),
        ],
      ),
    );
  }
}
