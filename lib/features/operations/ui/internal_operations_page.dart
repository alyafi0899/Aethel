import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/clinic_colors.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';
import '../../../features/auth/state/current_staff_controller.dart';
import '../../../state/app_controller.dart';
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
  OperationalMode _mode = OperationalMode.closed;
  String _saveStatus = 'Tersimpan';
  bool _advancedExpanded = false;
  String? _loadedClinicId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ops = context.read<ClinicController>().internalOperations;
    if (ops != null && ops.clinicId != _loadedClinicId) {
      _loadedClinicId = ops.clinicId;
      _applyModel(ops);
    }
  }

  void _applyModel(ClinicOperationsInternalModel ops) {
    _mode = OperationalMode.fromDatabase(
      facilityStatus: ops.facilityStatus,
      queueStatus: ops.queueProcessStatus,
    );
  }

  ClinicOperationsInternalModel? _updatedModel(
      ClinicOperationsInternalModel? current) {
    if (current == null) return null;
    return current.copyWith(
      facilityStatus: _mode.facilityStatus,
      queueProcessStatus: _mode.queueStatus,
    );
  }

  Future<void> _save() async {
    final controller = context.read<ClinicController>();
    final staff = context.read<CurrentStaffController>();
    if (staff.access?.canManageClinic != true) {
      setState(() => _saveStatus = 'Akses terbatas');
      return;
    }
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
    });
  }

  Future<void> _setMode(OperationalMode mode) async {
    setState(() {
      _mode = mode;
      _saveStatus = 'Menyimpan...';
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClinicController>();
    final staff = context.watch<CurrentStaffController>();
    final ops = controller.internalOperations;
    final preview = controller.publicPreview;
    final c = context.c;
    final canManage = staff.access?.canManageClinic == true;

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
              if (canManage)
                OperationalStatusControls(
                  selected: _mode,
                  onChanged: _setMode,
                )
              else
                Text(
                  'Status saat ini: ${_mode.label}. Hanya pemilik atau admin yang dapat mengubahnya.',
                  style: context.sBody,
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
              const SizedBox(height: 8),
              Text(
                'Nomor antrean dan waktu tunggu dihitung dari kunjungan aktif.',
                style: context.sBody,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Metric(
                    title: 'Nomor dilayani',
                    value: '${ops?.currentQueueNumber ?? 0}',
                  ),
                  _Metric(
                    title: 'Antrean hari ini',
                    value: '${ops?.totalQueues ?? 0}',
                  ),
                  _Metric(
                    title: 'Perkiraan tunggu',
                    value: '${ops?.averageWaitTime ?? 0} menit',
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<AppController>().go(AppPage.workflow),
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('Buka alur antrean'),
                  ),
                ],
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
                    onPressed: () async {
                      final refreshed = await controller.refreshOperations();
                      if (refreshed && mounted) {
                        final latest = controller.internalOperations;
                        if (latest != null) {
                          setState(() => _applyModel(latest));
                        }
                      }
                    },
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
                    onChanged: canManage
                        ? (enabled) => _setMode(enabled
                            ? OperationalMode.maintenance
                            : OperationalMode.closed)
                        : null,
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
