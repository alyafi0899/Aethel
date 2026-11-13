import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/common.dart';
import '../../clinic/state/clinic_controller.dart';
import '../models/clinic_operations_models.dart';
import '../models/operational_status.dart';

class InternalOperationsPage extends StatefulWidget {
  const InternalOperationsPage({super.key});

  @override
  State<InternalOperationsPage> createState() => _InternalOperationsPageState();
}

class _InternalOperationsPageState extends State<InternalOperationsPage> {
  Timer? _saveTimer;
  OperationalMode _mode = OperationalMode.closed;
  int _currentQueue = 0;
  int _totalQueues = 0;
  int _waitMinutes = 0;
  String _saveStatus = 'Tersimpan';
  bool _advancedExpanded = false;
  ClinicOperationsInternalModel? _lastSaved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ops = context.read<ClinicController>().internalOperations;
    if (ops != null && _lastSaved == null) {
      _applyModel(ops);
    }
  }

  void _applyModel(ClinicOperationsInternalModel ops) {
    _mode = OperationalMode.fromDatabase(
      facilityStatus: ops.facilityStatus,
      queueStatus: ops.queueProcessStatus,
    );
    _currentQueue = ops.currentQueueNumber;
    _totalQueues = ops.totalQueues;
    _waitMinutes = ops.averageWaitTime;
    _lastSaved = ops;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  ClinicOperationsInternalModel? _updatedModel(
      ClinicOperationsInternalModel? current) {
    if (current == null) return null;
    return current.copyWith(
      facilityStatus: _mode.facilityStatus,
      queueProcessStatus: _mode.queueStatus,
      currentQueueNumber: _currentQueue,
      totalQueues: _totalQueues,
      averageWaitTime: _waitMinutes,
    );
  }

  void _saveDebounced() {
    setState(() => _saveStatus = 'Menyimpan...');
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    final controller = context.read<ClinicController>();
    final updated = _updatedModel(controller.internalOperations);
    if (updated == null) {
      setState(() => _saveStatus = 'Data operasional belum tersedia');
      return;
    }
    final saved = await controller.updateInternalOperations(updated);
    if (!mounted) return;
    setState(() {
      _saveStatus = saved
          ? 'Tersimpan ✓'
          : 'Gagal menyimpan${controller.errorMessage == null ? '' : ': ${controller.errorMessage}'}';
      if (saved) _lastSaved = updated;
    });
  }

  Future<void> _setMode(OperationalMode mode) async {
    setState(() {
      _mode = mode;
      _saveStatus = 'Menyimpan...';
    });
    await _save();
  }

  Future<void> _restartQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai ulang antrean?'),
        content: const Text(
            'Nomor antrean dan jumlah antrean hari ini akan kembali ke 0.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mulai ulang'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _currentQueue = 0;
      _totalQueues = 0;
    });
    await _save();
  }

  void _nextQueue() {
    setState(() {
      _currentQueue++;
      if (_totalQueues < _currentQueue) _totalQueues = _currentQueue;
    });
    _saveDebounced();
  }

  void _previousQueue() {
    if (_currentQueue == 0) return;
    setState(() => _currentQueue--);
    _saveDebounced();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClinicController>();
    final ops = controller.internalOperations;
    final preview = controller.publicPreview;
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Operasional', style: context.sH2),
        const SizedBox(height: 4),
        Text('Atur layanan hari ini dan kelola nomor antrean.',
            style: context.sSmall),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Status klinik hari ini', style: context.sH3),
                  ),
                  Text(_saveStatus,
                      style: context.sSmall.copyWith(
                        color: _saveStatus.startsWith('Gagal')
                            ? c.fg(Tone.red)
                            : c.muted,
                      )),
                  if (_saveStatus.startsWith('Gagal')) ...[
                    const SizedBox(width: 8),
                    TextButton(
                        onPressed: _save, child: const Text('Coba lagi')),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              OperationalStatusControls(
                selected: _mode,
                onChanged: _setMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Antrean pasien', style: context.sH3),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Mundur satu nomor',
                    onPressed: _previousQueue,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Nomor yang sedang dilayani',
                            style: context.sSmall),
                        Text(
                          '$_currentQueue',
                          style: context.sH1.copyWith(
                            fontSize: 50,
                            color: c.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Dari $_totalQueues antrean hari ini',
                            style: context.sSmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _nextQueue,
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Panggil nomor berikutnya'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.hourglass_bottom),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Perkiraan waktu tunggu: $_waitMinutes menit',
                        style: context.sBody),
                  ),
                  IconButton(
                    tooltip: 'Kurangi waktu tunggu',
                    onPressed: _waitMinutes == 0
                        ? null
                        : () {
                            setState(() => _waitMinutes--);
                            _saveDebounced();
                          },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Tambah waktu tunggu',
                    onPressed: () {
                      setState(() => _waitMinutes++);
                      _saveDebounced();
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _restartQueue,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Mulai ulang antrean hari ini'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Informasi yang dihitung otomatis',
                        style: context.sH3),
                  ),
                  TextButton.icon(
                    onPressed: controller.refreshOperations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Perbarui'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(
                      title: 'Dokter tersedia',
                      value: '${ops?.totalDoctorsAvailable ?? 0}'),
                  _Metric(
                      title: 'Staf bertugas',
                      value: '${ops?.staffOnDutyCount ?? 0}'),
                  _Metric(
                      title: 'Ruang tersedia',
                      value: '${ops?.availableRoomsCount ?? 0}'),
                  _Metric(
                      title: 'Layanan aktif',
                      value: '${ops?.serviceTypes.length ?? 0}'),
                ],
              ),
              if (ops?.lastUpdateTimestamp != null) ...[
                const SizedBox(height: 10),
                Text(
                    'Terakhir diperbarui ${AppFormatters.formatDateTime(ops!.lastUpdateTimestamp)}',
                    style: context.sSmall),
              ],
              const Divider(height: 24),
              Text('Tampilan untuk pasien', style: context.sStrong),
              const SizedBox(height: 4),
              Text(
                preview == null
                    ? 'Pratinjau belum tersedia. Ketuk Perbarui untuk mencoba lagi.'
                    : 'Pasien melihat: ${ops == null ? preview.clinicStatus : OperationalMode.patientFacingStatus(facilityStatus: ops.facilityStatus, queueStatus: ops.queueProcessStatus)} · antrean ${preview.currentQueueNumber} · tunggu sekitar ${preview.estimatedWaitTime} menit',
                style: context.sSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                title: const Text('Pengaturan lanjutan'),
                subtitle: const Text('Pemeliharaan dan pilihan tambahan'),
                trailing: Icon(
                    _advancedExpanded ? Icons.expand_less : Icons.expand_more),
                onTap: () =>
                    setState(() => _advancedExpanded = !_advancedExpanded),
              ),
              if (_advancedExpanded) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.build_outlined),
                  title: const Text('Pemeliharaan'),
                  subtitle:
                      const Text('Tandai klinik sedang tidak melayani pasien'),
                  trailing: Switch(
                    value: _mode == OperationalMode.maintenance,
                    onChanged: (enabled) => _setMode(enabled
                        ? OperationalMode.maintenance
                        : OperationalMode.closed),
                  ),
                ),
                if (kShowManualOperationStats && ops != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Statistik manual saat ini: ${ops.totalRegisteredPatients} pasien terdaftar, ${ops.totalDailyVisitors} pengunjung.',
                      style: context.sSmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class OperationalStatusControls extends StatelessWidget {
  const OperationalStatusControls({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final OperationalMode selected;
  final ValueChanged<OperationalMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final mode in [
          OperationalMode.open,
          OperationalMode.breakTime,
          OperationalMode.closed,
        ])
          SizedBox(
            width: 150,
            child: FilledButton.tonalIcon(
              onPressed: () => onChanged(mode),
              icon: Icon(switch (mode) {
                OperationalMode.open => Icons.lock_open,
                OperationalMode.breakTime => Icons.free_breakfast_outlined,
                _ => Icons.lock_outline,
              }),
              label: Text(mode.label),
              style: FilledButton.styleFrom(
                backgroundColor: selected == mode
                    ? context.c.primary.withValues(alpha: .18)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.c.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.sH3),
            const SizedBox(height: 3),
            Text(title, style: context.sSmall),
          ],
        ),
      );
}
