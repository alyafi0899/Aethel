import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../../widgets/forms.dart';
import '../state/auth_controller.dart';
import 'forgot_password_page.dart';
import 'register_clinic_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!success && mounted && authCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authCtrl.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand Header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ClinicColors.lighten(c.accent, 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.local_hospital, size: 36, color: c.accent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prometheon Clinic OS',
                    style: context.sH2.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk ke Sistem Operasional Klinik',
                    style: context.sBodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  AppCard(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authCtrl.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authCtrl.errorMessage!,
                                    style: context.sBodyMuted.copyWith(color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        FormField2(
                          label: 'Email Klinik / Pengelola',
                          hint: 'nama@klinik.com',
                          controller: _emailCtrl,
                          validator: AppValidators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        FormField2(
                          label: 'Kata Sandi',
                          hint: 'Masukkan kata sandi Anda',
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          validator: (v) => AppValidators.validateRequired(v, 'Kata sandi'),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                              color: c.muted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Lupa kata sandi?',
                              style: context.sBody.copyWith(color: c.accent, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        AppButton(
                          label: 'Masuk Sekarang',
                          icon: Icons.login,
                          loading: authCtrl.loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum mendaftarkan klinik Anda?', style: context.sBodyMuted),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterClinicPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Daftar Klinik Baru',
                          style: context.sBody.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
