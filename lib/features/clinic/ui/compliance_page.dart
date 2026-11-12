import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';
import '../../../state/app_controller.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../models/clinic_enums.dart';
import '../state/clinic_controller.dart';
import 'health_workers/health_worker_form_dialog.dart';

class CompliancePage extends StatefulWidget {
  const CompliancePage({super.key});

  @override
  State<CompliancePage> createState() => _CompliancePageState();
}

class _CompliancePageState extends State<CompliancePage> {
  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final appCtrl = context.watch<AppController>();

    final clinic = clinicCtrl.clinic;
    final compliance = clinicCtrl.complianceStatus;
    final clinicId = clinicCtrl.clinicId ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kepatuhan & Masa Berlaku Perizinan',
                      style: context.sH2),
                  Text(
                      'Pemantauan masa berlaku SIO klinik, STR, dan SIP tenaga kesehatan.',
                      style: context.sSmall),
                ],
              ),
              AppButton(
                'Segarkan Alerts',
                icon: Icons.refresh,
                kind: BtnKind.secondary,
                onPressed: () => clinicCtrl.refreshCompliance(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Visibility Status Banner
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  compliance.publiclyVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: compliance.publiclyVisible ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compliance.publiclyVisible
                            ? 'Status Publikasi Pasien: TAMPIL KE PUBLIK'
                            : 'Status Publikasi Pasien: TIDAK TAMPIL',
                        style: context.sBody.copyWith(
                          fontWeight: FontWeight.bold,
                          color: compliance.publiclyVisible
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        compliance.publiclyVisible
                            ? 'Klinik terverifikasi, SIO aktif, dan publikasi dinyalakan.'
                            : 'Klinik disembunyikan dari publik karena SIO kedaluwarsa, belum terverifikasi, atau sakelar dipadamkan.',
                        style: context.sSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SIO Compliance Card
          Text('1. Surat Izin Operasional Klinik (SIO)',
              style: context.sH2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nomor SIO: ${clinic?.sioNumber ?? '-'}',
                            style: context.sBody
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text(
                            'Masa Berlaku: ${AppFormatters.formatDate(compliance.sioExpiry)}',
                            style: context.sSmall),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (compliance.sioValid ? Colors.green : Colors.red)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        compliance.sioValid
                            ? 'SIO Aktif (${compliance.sioDaysLeft ?? 0} Hari Tersisa)'
                            : 'SIO KEDALUWARSA!',
                        style: TextStyle(
                          color: compliance.sioValid
                              ? Colors.green.shade800
                              : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  'Perbarui SIO di Data Dasar',
                  icon: Icons.edit_calendar,
                  kind: BtnKind.secondary,
                  onPressed: () {
                    appCtrl.go(AppPage.clinicProfile);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Health Workers STR/SIP Compliance List
          Text(
              '2. Masa Berlaku STR & SIP Tenaga Kesehatan (${clinicCtrl.healthWorkers.length})',
              style: context.sH2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          if (clinicCtrl.healthWorkers.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Text('Belum ada data tenaga kesehatan.',
                  style: context.sSmall),
            )
          else
            Column(
              children: clinicCtrl.healthWorkers.map((worker) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${worker.titleDegree ?? ''} ${worker.fullName}'
                                        .trim(),
                                    style: context.sBody
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                    '${worker.workerType.label} • ${worker.specialization ?? 'Umum'}',
                                    style: context.sSmall),
                              ],
                            ),
                            AppButton(
                              'Perbarui',
                              icon: Icons.edit_outlined,
                              kind: BtnKind.secondary,
                              compact: true,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => HealthWorkerFormDialog(
                                    clinicId: clinicId,
                                    initialWorker: worker,
                                  ),
                                ).then(
                                    (_) => clinicCtrl.loadClinicData(clinicId));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _licensePill(
                                    'STR',
                                    worker.strNumber,
                                    worker.strExpiry,
                                    worker.isStrExpired,
                                    worker.isStrExpiringSoon)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _licensePill(
                                    'SIP',
                                    worker.sipNumber,
                                    worker.sipExpiry,
                                    worker.isSipExpired,
                                    worker.isSipExpiringSoon)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Active Compliance Alerts List
          Text('3. Daftar Peringatan Sistem (${compliance.alerts.length})',
              style: context.sH2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          if (compliance.alerts.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Text('Tidak ada peringatan kepatuhan terbuka.',
                      style: context.sBody),
                ],
              ),
            )
          else
            Column(
              children: compliance.alerts.map((alert) {
                final isCritical = alert.severity == AlertSeverity.critical;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isCritical
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.amber.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: Icon(
                      isCritical ? Icons.error : Icons.warning_amber,
                      color: isCritical ? Colors.red : Colors.amber.shade900,
                    ),
                    title: Text(alert.message,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCritical
                                ? Colors.red.shade900
                                : Colors.amber.shade900)),
                    subtitle: Text(
                        'Tenggat: ${AppFormatters.formatDate(alert.dueDate)} • Kategori: ${alert.severity.label}'),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _licensePill(String label, String? number, DateTime? expiry,
      bool isExpired, bool isExpiringSoon) {
    Color col = Colors.green.shade800;
    Color bg = Colors.green.withValues(alpha: 0.1);
    String status = 'Aktif';

    if (isExpired) {
      col = Colors.red.shade900;
      bg = Colors.red.withValues(alpha: 0.15);
      status = 'Kedaluwarsa!';
    } else if (isExpiringSoon) {
      col = Colors.amber.shade900;
      bg = Colors.amber.withValues(alpha: 0.2);
      status = 'Segera Berakhir';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${number ?? '-'}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: col, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Masa Berlaku: ${AppFormatters.formatDate(expiry)} ($status)',
              style: TextStyle(color: col, fontSize: 11)),
        ],
      ),
    );
  }
}
