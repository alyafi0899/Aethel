import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../../widgets/forms.dart';
import '../../clinic/models/clinic_enums.dart';
import '../../clinic/state/clinic_controller.dart';

class InternalOperationsPage extends StatefulWidget {
  const InternalOperationsPage({super.key});

  @override
  State<InternalOperationsPage> createState() => _InternalOperationsPageState();
}

class _InternalOperationsPageState extends State<InternalOperationsPage> {
  Timer? _debounceTimer;
  String? _saveStatus = 'Tersimpan';

  final _totalQueuesCtrl = TextEditingController();
  final _currentQueueCtrl = TextEditingController();
  final _avgWaitCtrl = TextEditingController();
  final _registeredPatientsCtrl = TextEditingController();
  final _dailyVisitorsCtrl = TextEditingController();
  final _dailyAppointmentsCtrl = TextEditingController();
  final _cancelledAppointmentsCtrl = TextEditingController();
  final _completedConsultationsCtrl = TextEditingController();

  QueueProcessStatus _queueStatus = QueueProcessStatus.closed;
  FacilityOperatingStatus _facilityStatus = FacilityOperatingStatus.closed;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initFromOperations();
      _initialized = true;
    }
  }

  void _initFromOperations() {
    final ops = context.read<ClinicController>().internalOperations;
    if (ops != null) {
      _totalQueuesCtrl.text = ops.totalQueues.toString();
      _currentQueueCtrl.text = ops.currentQueueNumber.toString();
      _avgWaitCtrl.text = ops.averageWaitTime.toString();
      _registeredPatientsCtrl.text = ops.totalRegisteredPatients.toString();
      _dailyVisitorsCtrl.text = ops.totalDailyVisitors.toString();
      _dailyAppointmentsCtrl.text = ops.dailyAppointmentsCount.toString();
      _cancelledAppointmentsCtrl.text =
          ops.cancelledAppointmentsCount.toString();
      _completedConsultationsCtrl.text =
          ops.totalCompletedConsultations.toString();
      _queueStatus = ops.queueProcessStatus;
      _facilityStatus = ops.facilityStatus;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _totalQueuesCtrl.dispose();
    _currentQueueCtrl.dispose();
    _avgWaitCtrl.dispose();
    _registeredPatientsCtrl.dispose();
    _dailyVisitorsCtrl.dispose();
    _dailyAppointmentsCtrl.dispose();
    _cancelledAppointmentsCtrl.dispose();
    _completedConsultationsCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    setState(() => _saveStatus = 'Menyimpan...');
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final clinicCtrl = context.read<ClinicController>();
      final currentOps = clinicCtrl.internalOperations;
      if (currentOps == null) return;

      final updated = currentOps.copyWith(
        totalQueues: int.tryParse(_totalQueuesCtrl.text) ?? 0,
        currentQueueNumber: int.tryParse(_currentQueueCtrl.text) ?? 0,
        queueProcessStatus: _queueStatus,
        averageWaitTime: int.tryParse(_avgWaitCtrl.text) ?? 0,
        totalRegisteredPatients:
            int.tryParse(_registeredPatientsCtrl.text) ?? 0,
        totalDailyVisitors: int.tryParse(_dailyVisitorsCtrl.text) ?? 0,
        dailyAppointmentsCount: int.tryParse(_dailyAppointmentsCtrl.text) ?? 0,
        cancelledAppointmentsCount:
            int.tryParse(_cancelledAppointmentsCtrl.text) ?? 0,
        facilityStatus: _facilityStatus,
        totalCompletedConsultations:
            int.tryParse(_completedConsultationsCtrl.text) ?? 0,
      );

      final ok = await clinicCtrl.updateInternalOperations(updated);
      if (mounted) {
        setState(() {
          _saveStatus = ok ? 'Tersimpan ✓' : 'Gagal menyimpan!';
        });
      }
    });
  }

  void _incrementQueue() {
    final cur = int.tryParse(_currentQueueCtrl.text) ?? 0;
    final total = int.tryParse(_totalQueuesCtrl.text) ?? 0;
    _currentQueueCtrl.text = (cur + 1).toString();
    if (cur + 1 > total) {
      _totalQueuesCtrl.text = (cur + 1).toString();
    }
    _onDataChanged();
  }

  void _decrementQueue() {
    final cur = int.tryParse(_currentQueueCtrl.text) ?? 0;
    if (cur > 0) {
      _currentQueueCtrl.text = (cur - 1).toString();
      _onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final c = context.c;
    final ops = clinicCtrl.internalOperations;

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
                  Text('Layer Operasional Klinik (Internal)',
                      style: context.sH2),
                  Text(
                      'Dasbor pemantauan antrean, ketersediaan fasilitas, dan statistik harian.',
                      style: context.sSmall),
                ],
              ),
              Row(
                children: [
                  if (_saveStatus != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _saveStatus!,
                        style: context.sLabel.copyWith(
                            color: Colors.green.shade800, fontSize: 12),
                      ),
                    ),
                  const SizedBox(width: 12),
                  AppButton(
                    'Hitung Ulang',
                    icon: Icons.sync,
                    kind: BtnKind.secondary,
                    onPressed: () => clinicCtrl.refreshOperations(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Queue & Facility Control Card
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Kontrol Antrean & Status Fasilitas',
                    style: context.sH2.copyWith(fontSize: 18)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Queue counter
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
                            Text('Nomor Antrean Saat Ini',
                                style: context.sSmall),
                            const SizedBox(height: 8),
                            Text(
                              _currentQueueCtrl.text.isEmpty
                                  ? '0'
                                  : _currentQueueCtrl.text,
                              style: context.sH1.copyWith(
                                  fontSize: 48,
                                  color: c.accent,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  icon: const Icon(Icons.remove),
                                  onPressed: _decrementQueue,
                                ),
                                const SizedBox(width: 16),
                                IconButton.filled(
                                  icon: const Icon(Icons.add),
                                  onPressed: _incrementQueue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status Pemrosesan Antrean',
                              style: context.sBody
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<QueueProcessStatus>(
                            value: _queueStatus,
                            items: QueueProcessStatus.values
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.label)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _queueStatus = v);
                                _onDataChanged();
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          Text('Status Operasional Fasilitas',
                              style: context.sBody
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<FacilityOperatingStatus>(
                            value: _facilityStatus,
                            items: FacilityOperatingStatus.values
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.label)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _facilityStatus = v);
                                _onDataChanged();
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppFormField(
                        label: 'Total Antrean Terdaftar',
                        hint: '0',
                        controller: _totalQueuesCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppFormField(
                        label: 'Rata-rata Waktu Tunggu (Menit)',
                        hint: '15',
                        controller: _avgWaitCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Statistics Card
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2. Statistik Operasional Hari Ini',
                        style: context.sH2.copyWith(fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Diisi manual (Akan terisi otomatis setelah modul appointment aktif)',
                        style: context.sLabel.copyWith(
                            color: Colors.amber.shade900, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppFormField(
                        label: 'Pasien Terdaftar',
                        hint: '0',
                        controller: _registeredPatientsCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppFormField(
                        label: 'Pengunjung Harian',
                        hint: '0',
                        controller: _dailyVisitorsCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppFormField(
                        label: 'Konsultasi Selesai',
                        hint: '0',
                        controller: _completedConsultationsCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppFormField(
                        label: 'Jumlah Janji Temu (Appointments)',
                        hint: '0',
                        controller: _dailyAppointmentsCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppFormField(
                        label: 'Janji Temu Dibatalkan',
                        hint: '0',
                        controller: _cancelledAppointmentsCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onDataChanged(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Read-only Auto Metrics Card
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3. Indikator Otomatis Server (Hanya-Baca)',
                        style: context.sH2.copyWith(fontSize: 18)),
                    Text(
                        'Terakhir diperbarui: ${AppFormatters.formatDateTime(ops?.lastUpdateTimestamp)}',
                        style: context.sSmall.copyWith(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _metricBlock(
                        'Dokter Tersedia',
                        '${ops?.totalDoctorsAvailable ?? 0}',
                        Icons.medical_services_outlined,
                        Colors.blue),
                    _metricBlock(
                        'Staf Bertugas',
                        '${ops?.staffOnDutyCount ?? 0}',
                        Icons.people_outline,
                        Colors.teal),
                    _metricBlock('Ruang Aktif', '${ops?.activeRoomsCount ?? 0}',
                        Icons.meeting_room_outlined, Colors.purple),
                    _metricBlock(
                        'Ruang Tersedia',
                        '${ops?.availableRoomsCount ?? 0}',
                        Icons.door_sliding_outlined,
                        Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Jenis Layanan Aktif:',
                    style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (ops == null || ops.serviceTypes.isEmpty)
                  Text('Belum ada jenis layanan aktif.', style: context.sSmall)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ops.serviceTypes
                        .map((type) => Chip(
                              label: Text(type),
                              backgroundColor: c.surface,
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(String title, String value, IconData icon, Color color) {
    return Builder(builder: (context) {
      final c = context.c;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: context.sH2
                        .copyWith(color: color, fontWeight: FontWeight.bold)),
                Text(title, style: context.sSmall.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
      );
    });
  }
}
