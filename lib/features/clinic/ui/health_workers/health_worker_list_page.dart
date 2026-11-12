import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/context_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../widgets/buttons.dart';
import '../../../../widgets/common.dart';
import '../../models/clinic_enums.dart';
import '../../models/health_worker_models.dart';
import '../../state/clinic_controller.dart';
import 'health_worker_form_dialog.dart';

class HealthWorkerListPage extends StatefulWidget {
  const HealthWorkerListPage({super.key});

  @override
  State<HealthWorkerListPage> createState() => _HealthWorkerListPageState();
}

class _HealthWorkerListPageState extends State<HealthWorkerListPage> {
  String _searchQuery = '';
  HealthWorkerType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';

    var workers = clinicCtrl.healthWorkers;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      workers = workers.where((w) {
        final query = _searchQuery.toLowerCase();
        return w.fullName.toLowerCase().contains(query) ||
            (w.specialization?.toLowerCase().contains(query) ?? false) ||
            (w.strNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by worker type
    if (_selectedTypeFilter != null) {
      workers = workers.where((w) => w.workerType == _selectedTypeFilter).toList();
    }

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
                  Text('Tenaga Kesehatan Klinik', style: context.sH2),
                  Text('Manajemen dokter, perawat, penanggung jawab, status tugas, serta STR/SIP.', style: context.sSmall),
                ],
              ),
              AppButton(
                'Tambah Tenaga Kesehatan',
                icon: Icons.add,
                kind: BtnKind.primary,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => HealthWorkerFormDialog(clinicId: clinicId),
                  ).then((_) => clinicCtrl.loadClinicData(clinicId));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search & Filter Header Bar
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari nama, spesialisasi, atau nomor STR/SIP...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<HealthWorkerType?>(
                  value: _selectedTypeFilter,
                  hint: const Text('Semua Jenis'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Jenis')),
                    ...HealthWorkerType.values.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedTypeFilter = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (workers.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.person_search_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Tidak ada data tenaga kesehatan yang sesuai.', style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: workers.map((worker) => _workerCard(context, worker, clinicId)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _workerCard(BuildContext context, HealthWorkerModel worker, String clinicId) {
    final clinicCtrl = context.read<ClinicController>();

    final String initials = worker.fullName.isNotEmpty
        ? worker.fullName.trim().split(' ').map((e) => e[0]).take(2).join()
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: worker.workerType == HealthWorkerType.doctor
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.teal.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: worker.workerType == HealthWorkerType.doctor ? Colors.blue.shade800 : Colors.teal.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${worker.titleDegree ?? ''} ${worker.fullName}'.trim(),
                            style: context.sBody.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (worker.isPersonInCharge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade800,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Penanggung Jawab',
                                style: context.sLabel.copyWith(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                          if (!worker.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nonaktif',
                                style: context.sLabel.copyWith(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${worker.workerType.label} • ${worker.specialization ?? 'Umum'}',
                        style: context.sSmall.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      // Masked PII details
                      if (worker.privateData != null)
                        Text(
                          'Telepon: ${worker.privateData?.phone ?? '-'} • NIK: ${AppFormatters.maskNik(worker.privateData?.nik)} • NPWP: ${AppFormatters.maskNpwp(worker.privateData?.npwp)}',
                          style: context.sSmall.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),

                // Duty status selector
                DropdownButton<DutyStatus>(
                  value: worker.onDutyStatus,
                  items: DutyStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: s == DutyStatus.available
                                ? Colors.green
                                : (s == DutyStatus.busy ? Colors.orange : Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Text(s.label, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      clinicCtrl.updateHealthWorkerDutyStatus(worker.id, newStatus);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // STR / SIP Expiry Alerts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _expiryBadge('STR', worker.strNumber, worker.strExpiry, worker.isStrExpired, worker.isStrExpiringSoon),
                    _expiryBadge('SIP', worker.sipNumber, worker.sipExpiry, worker.isSipExpired, worker.isSipExpiringSoon),
                  ],
                ),

                Row(
                  children: [
                    Switch(
                      value: worker.isActive,
                      onChanged: (val) {
                        clinicCtrl.toggleHealthWorkerActive(worker.id, val);
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(worker.isActive ? 'Aktif' : 'Nonaktif', style: context.sSmall.copyWith(fontSize: 12)),
                    const SizedBox(width: 12),

                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Ubah Data',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => HealthWorkerFormDialog(
                            clinicId: clinicId,
                            initialWorker: worker,
                          ),
                        ).then((_) => clinicCtrl.loadClinicData(clinicId));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiryBadge(String type, String? number, DateTime? expiry, bool isExpired, bool isExpiringSoon) {
    Color bg = Colors.green.withValues(alpha: 0.1);
    Color fg = Colors.green.shade800;
    String statusText = 'Aktif';

    if (isExpired) {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.red.shade900;
      statusText = 'Kedaluwarsa!';
    } else if (isExpiringSoon) {
      bg = Colors.amber.withValues(alpha: 0.2);
      fg = Colors.amber.shade900;
      statusText = 'Segera Berakhir';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$type: ${number ?? '-'} (${AppFormatters.formatDate(expiry)}) • $statusText',
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
