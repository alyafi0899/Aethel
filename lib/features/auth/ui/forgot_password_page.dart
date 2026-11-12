import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../../widgets/forms.dart';
import '../state/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authCtrl = context.read<AuthController>();
    final success =
        await authCtrl.resetPasswordForEmail(_emailCtrl.text.trim());
    if (success && mounted) {
      setState(() => _sent = true);
    } else if (mounted && authCtrl.errorMessage != null) {
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
      appBar: AppBar(
        title: const Text('Lupa Kata Sandi'),
        backgroundColor: c.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              padding: const EdgeInsets.all(28.0),
              child: _sent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline,
                              size: 36, color: Colors.green),
                        ),
                        const SizedBox(height: 16),
                        Text('Instruksi Reset Dikirim',
                            style: context.sH2, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          'Tautan pemulihan kata sandi telah dikirim ke:\n${_emailCtrl.text.trim()}',
                          style: context.sSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          'Kembali ke Halaman Masuk',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: ClinicColors.lighten(c.accent, 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.lock_reset_outlined,
                                  size: 32, color: c.accent),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Atur Ulang Kata Sandi',
                            style: context.sH2
                                .copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan alamat email terdaftar untuk menerima tautan pemulihan',
                            style: context.sSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          AppFormField(
                            label: 'Email Klinik / Pendaftar',
                            hint: 'nama@klinik.com',
                            controller: _emailCtrl,
                            validator: AppValidators.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            'Kirim Tautan Pemulihan',
                            icon: Icons.send_outlined,
                            kind: BtnKind.primary,
                            loading: authCtrl.loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
