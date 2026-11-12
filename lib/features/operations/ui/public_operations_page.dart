import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../clinic/models/clinic_enums.dart';
import '../../clinic/state/clinic_controller.dart';

class PublicOperationsPage extends StatefulWidget {
  const PublicOperationsPage({super.key});

  @override
  State<PublicOperationsPage> createState() => _PublicOperationsPageState();
}

class _PublicOperationsPageState extends State<PublicOperationsPage> {
  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final c = context.c;
    final clinic = clinicCtrl.clinic;
    final preview = clinicCtrl.publicPreview;

    final bool isVerified = clinic?.status == ClinicStatus.verified;
    final bool isPublished = clinic?.isPublished ?? false;

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
                  Text('Layer Operasional Publik (Shared to Patients)',
                      style: context.sH2),
                  Text(
                      'Tampilan informasi operasional real-time yang dibagikan kepada publik & pasien.',
                      style: context.sSmall),
                ],
              ),
              AppButton(
                'Segarkan Pratinjau',
                icon: Icons.refresh,
                kind: BtnKind.secondary,
                onPressed: () => clinicCtrl.refreshOperations(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Publication Control Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPublished ? Icons.public : Icons.public_off,
                          color: isPublished ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPublished
                                  ? 'Klinik Dipublikasikan ke Pasien'
                                  : 'Klinik Disembunyikan dari Publik',
                              style: context.sBody.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isPublished
                                  ? 'Data operasional real-time klinik Anda dapat diakses oleh publik.'
                                  : 'Aktifkan sakelar untuk mempublikasikan klinik setelah terverifikasi.',
                              style: context.sSmall.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isPublished,
                      onChanged: isVerified
                          ? (val) {
                              clinicCtrl.setClinicPublished(val);
                            }
                          : null,
                    ),
                  ],
                ),
                if (!isVerified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade800),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Klinik Anda berstatus "${clinic?.status.label}". Publikasi hanya dapat diaktifkan setelah klinik disetujui dan berstatus Terverifikasi.',
                            style: context.sBody.copyWith(
                                color: Colors.amber.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Patient Public Preview Card
          Text('Pratinjau Kartu Informasi Pasien',
              style: context.sH2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),

          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview?.clinicName ??
                                clinic?.clinicName ??
                                'Nama Klinik',
                            style: context.sH1.copyWith(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 14, color: c.muted),
                              const SizedBox(width: 4),
                              Text(preview?.contactNumber ?? '-',
                                  style: context.sSmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: preview?.clinicStatus == 'open'
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        preview?.clinicStatus == 'open'
                            ? 'BUKA OPERASIONAL'
                            : 'TUTUP',
                        style: context.sLabel.copyWith(
                          color: preview?.clinicStatus == 'open'
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Live Queue Block
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          children: [
                            Text('Antrean Saat Ini', style: context.sSmall),
                            const SizedBox(height: 6),
                            Text(
                              '${preview?.currentQueueNumber ?? 0}',
                              style: context.sH1.copyWith(
                                  color: c.accent,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          children: [
                            Text('Estimasi Waktu Tunggu',
                                style: context.sSmall),
                            const SizedBox(height: 6),
                            Text(
                              '~${preview?.estimatedWaitTime ?? 0} Mnt',
                              style: context.sH1.copyWith(
                                  color: Colors.blue,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Available Doctors List
                Text(
                    'Dokter Bertugas Hari Ini (${preview?.availableDoctors.length ?? 0}):',
                    style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (preview == null || preview.availableDoctors.isEmpty)
                  Text('Tidak ada dokter yang sedang tersedia.',
                      style: context.sSmall)
                else
                  Column(
                    children: preview.availableDoctors.map((doc) {
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${doc.title ?? ''} ${doc.name}'.trim(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(doc.specialization ?? 'Dokter Umum'),
                        dense: true,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                // Map & Services
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Layanan Tersedia:',
                        style: context.sBody
                            .copyWith(fontWeight: FontWeight.bold)),
                    if (preview?.locationCoordinates != null)
                      TextButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('Buka Peta Lokasi'),
                        onPressed: () async {
                          final lat = preview?.locationCoordinates?['latitude'];
                          final lng =
                              preview?.locationCoordinates?['longitude'];
                          if (lat != null && lng != null) {
                            final uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (preview?.serviceTypes ?? [])
                      .map((s) =>
                          Chip(label: Text(s), backgroundColor: c.surface))
                      .toList(),
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Pembaruan Terakhir: ${AppFormatters.formatDateTime(preview?.lastUpdateTimestamp)}',
                    style: context.sSmall.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API/Query Help for Patient App
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contoh Query API Publik Pasien',
                    style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Aplikasi pasien atau portal publik membaca data dari view database "clinic_operations_public" yang secara otomatis memfilter hanya klinik verified + published:',
                  style: context.sSmall.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "final response = await supabase\n"
                    "  .from('clinic_operations_public')\n"
                    "  .select('*')\n"
                    "  .eq('clinic_id', clinicId);",
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 12),
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
