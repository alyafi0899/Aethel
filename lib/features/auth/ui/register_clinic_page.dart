import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../../widgets/forms.dart';
import '../state/auth_controller.dart';

class RegisterClinicPage extends StatefulWidget {
  const RegisterClinicPage({super.key});

  @override
  State<RegisterClinicPage> createState() => _RegisterClinicPageState();
}

class _RegisterClinicPageState extends State<RegisterClinicPage> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _clinicNameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  double _evaluatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double score = 0.0;
    if (password.length >= 10) score += 0.4;
    if (password.contains(RegExp(r'[a-zA-Z]'))) score += 0.3;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.3;
    return score.clamp(0.0, 1.0);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Anda harus menyetujui Syarat & Ketentuan Pendaftaran Klinik.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.signUpClinic(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      clinicName: _clinicNameCtrl.text.trim(),
    );

    if (!success && mounted && authCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authCtrl.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } else if (success && authCtrl.unconfirmedEmailSent) {
      _startCooldownTimer();
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    final authCtrl = context.read<AuthController>();
    final success =
        await authCtrl.resendVerificationEmail(_emailCtrl.text.trim());
    if (success && mounted) {
      _startCooldownTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Email konfirmasi berhasil dikirim ulang. Periksa kotak masuk Anda.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final c = context.c;

    if (authCtrl.unconfirmedEmailSent) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCard(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_unread_outlined,
                          size: 40, color: Colors.blue),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Cek Kotak Masuk Email Anda',
                      style: context.sH2.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kami telah mengirimkan tautan konfirmasi pendaftaran klinik ke email:\n${_emailCtrl.text.trim()}',
                      style: context.sSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Klik tautan pada email tersebut untuk mengaktifkan akun pendaftaran klinik Anda.',
                      style: context.sBody.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      _resendCooldown > 0
                          ? 'Kirim Ulang ($_resendCooldown detik)'
                          : 'Kirim Ulang Email Konfirmasi',
                      icon: Icons.refresh,
                      kind: BtnKind.secondary,
                      onPressed: _resendCooldown > 0 ? null : _resendEmail,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Kembali ke Halaman Masuk',
                          style: context.sBody.copyWith(color: c.accent)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final strength = _evaluatePasswordStrength(_passwordCtrl.text);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Pendaftaran Klinik Baru'),
        backgroundColor: c.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
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
                      child: Icon(Icons.add_business_outlined,
                          size: 32, color: c.accent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Registrasi Operasional Klinik',
                    style: context.sH2.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daftarkan klinik Anda untuk mengaktifkan sistem RME dan manajemen fasilitas',
                    style: context.sSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authCtrl.errorMessage!,
                                    style: context.sSmall.copyWith(
                                        color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppFormField(
                          label: 'Nama Resmi Klinik',
                          hint: 'contoh: Klinik Pratama Sehat Sejahtera',
                          controller: _clinicNameCtrl,
                          validator: (v) => AppValidators.validateRequired(
                              v, 'Nama resmi klinik'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Nama Lengkap Pendaftar / Penanggung Jawab',
                          hint: 'contoh: dr. Ahmad Subagyo, Sp.PD',
                          controller: _fullNameCtrl,
                          validator: (v) => AppValidators.validateRequired(
                              v, 'Nama penanggung jawab'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Email Resmi Klinik',
                          hint: 'info@kliniksehat.com',
                          controller: _emailCtrl,
                          validator: AppValidators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Nomor Telepon / WhatsApp Resmi',
                          hint: '081234567890',
                          controller: _phoneCtrl,
                          validator: AppValidators.validatePhone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Kata Sandi',
                          hint: 'Minimal 10 karakter (huruf & angka)',
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          validator: AppValidators.validatePassword,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: c.muted,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        if (_passwordCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: strength,
                                  backgroundColor: c.border,
                                  color: strength >= 0.8
                                      ? Colors.green
                                      : (strength >= 0.4
                                          ? Colors.orange
                                          : Colors.red),
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                strength >= 0.8
                                    ? 'Kuat'
                                    : (strength >= 0.4 ? 'Sedang' : 'Lemah'),
                                style: context.sSmall.copyWith(
                                  fontSize: 11,
                                  color: strength >= 0.8
                                      ? Colors.green
                                      : (strength >= 0.4
                                          ? Colors.orange
                                          : Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Konfirmasi Kata Sandi',
                          hint: 'Ulangi kata sandi di atas',
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirmPassword,
                          validator: (v) =>
                              AppValidators.validateConfirmPassword(
                                  v, _passwordCtrl.text),
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: c.muted,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeTerms,
                                onChanged: (v) =>
                                    setState(() => _agreeTerms = v ?? false),
                                activeColor: c.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saya menyatakan bahwa data yang diisikan adalah benar dan bersedia mematuhi Syarat & Ketentuan Layanan Prometheon Clinic OS.',
                                style: context.sSmall.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          'Daftarkan Klinik Sekarang',
                          icon: Icons.check_circle_outline,
                          kind: BtnKind.primary,
                          loading: authCtrl.loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sudah memiliki akun pendaftaran?',
                          style: context.sSmall),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Masuk',
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
