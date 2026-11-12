import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../clinic/models/clinic_enums.dart';
import '../../clinic/state/clinic_controller.dart';
import '../state/auth_controller.dart';

class PendingVerificationPage extends StatefulWidget {
  const PendingVerificationPage({super.key});

  @override
  State<PendingVerificationPage> createState() =>
      _PendingVerificationPageState();
}

class _PendingVerificationPageState extends State<PendingVerificationPage> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Auto-polling every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final authCtrl = context.read<AuthController>();
    final clinicCtrl = context.read<ClinicController>();
    await authCtrl.refreshProfile();
    final uid = authCtrl.user?.id;
    if (uid != null) {
      await clinicCtrl.loadClinicForUser(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final authCtrl = context.watch<AuthController>();
    final c = context.c;
    final clinic = clinicCtrl.clinic;

    final isSubmitted = clinic?.status == ClinicStatus.submitted;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Status Verifikasi Klinik'),
        backgroundColor: c.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => authCtrl.signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AppCard(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isSubmitted
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSubmitted
                            ? Icons.fact_check_outlined
                            : Icons.hourglass_top_rounded,
                        size: 40,
                        color:
                            isSubmitted ? Colors.blue : Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSubmitted
                        ? 'Pengajuan Berhasil Dikirim'
                        : 'Pendaftaran Dalam Peninjauan',
                    style: context.sH2.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSubmitted
                        ? 'Tim verifikator Prometheon Clinic OS telah menerima dokumen registrasi klinik Anda.'
                        : 'Tim analis verifikasi sedang meninjau kelayakan dokumen operasional klinik Anda.',
                    style: context.sSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Nama Klinik', clinic?.clinicName ?? '-'),
                        const Divider(height: 16),
                        _infoRow('Bentuk Badan Hukum',
                            clinic?.legalEntityType?.label ?? '-'),
                        const Divider(height: 16),
                        _infoRow(
                            'Kode Fasyankes', clinic?.fasyankesCode ?? '-'),
                        const Divider(height: 16),
                        _infoRow('Waktu Pengajuan',
                            AppFormatters.formatDateTime(clinic?.submittedAt)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Status Pendaftaran', style: context.sSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    (isSubmitted ? Colors.blue : Colors.amber)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                clinic?.status.label ?? 'Peninjauan',
                                style: context.sLabel.copyWith(
                                  color: isSubmitted
                                      ? Colors.blue.shade800
                                      : Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          'Segarkan Status',
                          icon: Icons.refresh,
                          kind: BtnKind.primary,
                          loading: clinicCtrl.loading,
                          onPressed: _refresh,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          'Keluar Akun',
                          icon: Icons.logout,
                          kind: BtnKind.secondary,
                          onPressed: () => authCtrl.signOut(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Halaman ini akan memperbarui status secara otomatis setiap 30 detik.',
                    style: context.sSmall.copyWith(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Builder(builder: (context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.sSmall),
          Flexible(
            child: Text(
              value,
              style: context.sBody.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    });
  }
}
