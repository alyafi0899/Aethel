import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/context_ext.dart';
import '../../../domain/clinic_repositories.dart';
import '../../../domain/models.dart';
import '../../../data/supabase/clinic_realtime_service.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../auth/state/current_staff_controller.dart';
import '../../clinic/state/clinic_controller.dart';
import '../../../data/supabase/supabase_clinical_repository.dart';

enum VisitFlowView {
  queue('Antrean'),
  patients('Pasien'),
  triage('Triase'),
  consultations('Pemeriksaan'),
  billing('Tagihan'),
  inbox('Kotak Masuk'),
  emergencies('Darurat');

  const VisitFlowView(this.label);
  final String label;
}

class VisitFlowPage extends StatefulWidget {
  const VisitFlowPage({
    super.key,
    this.initialView = VisitFlowView.queue,
    this.repository,
  });

  final VisitFlowView initialView;
  final ClinicWorkflowRepository? repository;

  @override
  State<VisitFlowPage> createState() => _VisitFlowPageState();
}

class _VisitFlowPageState extends State<VisitFlowPage> {
  late final ClinicWorkflowRepository _repository =
      widget.repository ?? SupabaseClinicalRepository();
  ClinicRealtimeService? _realtime;
  StreamSubscription<ClinicRealtimeEvent>? _realtimeSubscription;
  VisitFlowView? _selectedView;
  String? _loadedClinicId;
  String? _errorMessage;
  bool _loading = false;
  List<Visit> _visits = [];
  List<ClinicPatient> _patients = [];
  List<Invoice> _invoices = [];
  List<InboxItem> _inbox = [];
  List<EmergencyAlert> _alerts = [];
  final TextEditingController _patientSearch = TextEditingController();

  VisitFlowView get _view => _selectedView ?? widget.initialView;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clinicId = context.read<ClinicController>().clinicId;
    if (clinicId != null && clinicId != _loadedClinicId) {
      _loadedClinicId = clinicId;
      if (widget.repository == null) _connectRealtime(clinicId);
      _load();
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    final realtime = _realtime;
    if (realtime != null) unawaited(realtime.dispose());
    _patientSearch.dispose();
    super.dispose();
  }

  void _connectRealtime(String clinicId) {
    _realtimeSubscription?.cancel();
    final previous = _realtime;
    if (previous != null) unawaited(previous.dispose());
    final realtime = ClinicRealtimeService(
      clinicId: clinicId,
      poller: _load,
      realtimeEnabled: const bool.fromEnvironment(
        'SUPABASE_REALTIME_ENABLED',
        defaultValue: true,
      ),
    );
    _realtime = realtime;
    _realtimeSubscription = realtime.events.listen(
      (_) {
        if (mounted) _load();
      },
      onError: (Object _, StackTrace __) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Pembaruan langsung terputus; data akan diperbarui berkala.';
          });
        }
      },
    );
    realtime.start();
  }

  Future<void> _load() async {
    final clinicId = _loadedClinicId;
    if (clinicId == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      switch (_view) {
        case VisitFlowView.queue:
        case VisitFlowView.triage:
        case VisitFlowView.consultations:
          _visits = await _repository.loadVisitBoard(clinicId);
        case VisitFlowView.patients:
          _patients = await _repository.searchPatients(
            clinicId,
            _patientSearch.text,
          );
        case VisitFlowView.billing:
          _invoices = await _repository.loadInvoices(clinicId);
        case VisitFlowView.inbox:
          _inbox = await _repository.loadInbox(clinicId);
        case VisitFlowView.emergencies:
          _alerts = await _repository.loadEmergencyAlerts(clinicId);
      }
    } on ClinicRepositoryException catch (error) {
      _clearCurrentViewData();
      _errorMessage = _errorText(error.code);
    } catch (_) {
      _clearCurrentViewData();
      _errorMessage = 'Data belum dapat dimuat. Silakan coba lagi.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _clearCurrentViewData() {
    switch (_view) {
      case VisitFlowView.queue:
      case VisitFlowView.triage:
      case VisitFlowView.consultations:
        _visits = [];
      case VisitFlowView.patients:
        _patients = [];
      case VisitFlowView.billing:
        _invoices = [];
      case VisitFlowView.inbox:
        _inbox = [];
      case VisitFlowView.emergencies:
        _alerts = [];
    }
  }

  String _errorText(String code) => switch (code) {
        'not_authorized' => 'Akses Anda tidak mencakup data ini.',
        'not_authenticated' => 'Sesi Anda berakhir. Silakan masuk kembali.',
        'queue_closed' => 'Antrean klinik sedang ditutup.',
        'visit_closed' => 'Kunjungan ini sudah ditutup.',
        'invalid_stage_transition' =>
          'Tahap kunjungan tidak dapat diubah ke status tersebut.',
        'invalid_ticket_transition' =>
          'Status tiket antrean sudah berubah. Muat ulang data.',
        _ => 'Operasi belum dapat diselesaikan. Silakan coba lagi.',
      };

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await action();
      await _load();
    } on ClinicRepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = _errorText(error.code);
          if (error.code == 'not_authorized' ||
              error.code == 'not_authenticated') {
            _clearCurrentViewData();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Operasi belum dapat diselesaikan. Silakan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<CurrentStaffController>();
    final clinic = context.watch<ClinicController>();
    if (_loadedClinicId == null && clinic.clinicId != null) {
      _loadedClinicId = clinic.clinicId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          title: _view.label,
          desc: 'Kelola kunjungan klinik sesuai akses akun Anda.',
          actions: [
            AppButton(
              'Muat ulang',
              icon: Icons.refresh,
              kind: BtnKind.secondary,
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<VisitFlowView>(
            segments: VisitFlowView.values
                .map((view) => ButtonSegment(
                      value: view,
                      label: Text(view.label),
                    ))
                .toList(),
            selected: {_view},
            onSelectionChanged: (value) {
              setState(() => _selectedView = value.first);
              _load();
            },
          ),
        ),
        const SizedBox(height: 14),
        if (_errorMessage != null)
          _MessageCard(
            message: _errorMessage!,
            onRetry: _load,
          ),
        if (_loading) const LinearProgressIndicator(),
        if (_view == VisitFlowView.queue)
          _buildQueue(staff, clinic)
        else if (_view == VisitFlowView.triage)
          _buildStageList(
            title: 'Kunjungan untuk triase',
            stages: {VisitStage.checkedIn, VisitStage.screening},
            staff: staff,
          )
        else if (_view == VisitFlowView.consultations)
          _buildStageList(
            title: 'Kunjungan untuk pemeriksaan',
            stages: {
              VisitStage.waitingDoctor,
              VisitStage.inConsultation,
              VisitStage.awaitingPayment,
            },
            staff: staff,
          )
        else if (_view == VisitFlowView.patients)
          _buildPatients()
        else if (_view == VisitFlowView.billing)
          _buildBilling(staff)
        else if (_view == VisitFlowView.inbox)
          _buildInbox()
        else
          _buildEmergencies(staff),
      ],
    );
  }

  Widget _buildQueue(CurrentStaffController staff, ClinicController clinic) {
    final activeVisits = _visits.where((visit) => !{
          VisitStage.completed,
          VisitStage.cancelled,
          VisitStage.noShow,
        }.contains(visit.stage));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (staff.canReceiveQueue)
              AppButton(
                'Daftarkan kunjungan',
                icon: Icons.add,
                kind: BtnKind.primary,
                onPressed: clinic.services.isEmpty ? null : _registerVisit,
              ),
            const SizedBox(width: 8),
            if (staff.canReceiveQueue)
              PopupMenuButton<QueueStation>(
                tooltip: 'Panggil antrean berikutnya',
                onSelected: (station) => _run(() async {
                  await _repository.callNext(
                    clinic.clinicId!,
                    station: station,
                  );
                }),
                itemBuilder: (context) => QueueStation.values
                    .map((station) => PopupMenuItem(
                          value: station,
                          child: Text('Panggil: ${station.label}'),
                        ))
                    .toList(),
                child: const Chip(
                  avatar: Icon(Icons.record_voice_over_outlined),
                  label: Text('Panggil berikutnya'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeVisits.isEmpty)
          const _EmptyCard(message: 'Belum ada kunjungan aktif.')
        else
          ...activeVisits.map((visit) => _visitCard(visit, staff)),
      ],
    );
  }

  Widget _buildStageList({
    required String title,
    required Set<VisitStage> stages,
    required CurrentStaffController staff,
  }) {
    final items = _visits.where((visit) => stages.contains(visit.stage));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.sH2),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const _EmptyCard(message: 'Tidak ada kunjungan pada tahap ini.')
        else
          ...items.map((visit) => _visitCard(visit, staff)),
      ],
    );
  }

  Widget _visitCard(Visit visit, CurrentStaffController staff) {
    final ticket = visit.ticket;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visit.patientName ?? 'Pasien',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Chip(label: Text(visit.stage.label)),
                ],
              ),
              Text(
                [
                  if (visit.reference != null) 'Ref. ${visit.reference}',
                  if (ticket?.displayCode.isNotEmpty == true)
                    'Antrean ${ticket!.displayCode}',
                  if (visit.serviceType?.isNotEmpty == true) visit.serviceType!,
                ].join(' · '),
                style: context.sSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _visitActions(visit, staff),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _visitActions(Visit visit, CurrentStaffController staff) {
    final actions = <Widget>[];
    if (staff.canReceiveQueue &&
        {VisitStage.registered, VisitStage.queued}.contains(visit.stage)) {
      actions.add(_action(
          'Check-in',
          () => _run(() async {
                await _repository.checkIn(visit.encounterId);
              })));
    }
    if (staff.canReceiveQueue && visit.stage == VisitStage.registered) {
      actions.add(_action(
          'Ambil antrean',
          () => _run(() async {
                await _repository.takeQueue(visit.encounterId);
              })));
    }
    if (staff.canReceiveQueue && visit.stage == VisitStage.checkedIn) {
      actions.add(_action('Skrining awal', () => _submitIntake(visit)));
      actions.add(_action(
          'Tidak hadir',
          () => _run(() async {
                await _repository.markNoShow(visit.encounterId);
              })));
    }
    if (staff.canRecordTriage &&
        {VisitStage.checkedIn, VisitStage.screening}.contains(visit.stage)) {
      actions.add(_action('Isi triase', () => _recordTriage(visit)));
    }
    if (staff.canActAsDoctor && visit.stage == VisitStage.waitingDoctor) {
      actions.add(_action(
          'Mulai pemeriksaan',
          () => _run(() async {
                await _repository.startConsultation(visit.encounterId);
              })));
    }
    if (staff.canActAsDoctor && visit.stage == VisitStage.inConsultation) {
      actions.add(
          _action('Catat & selesaikan', () => _completeConsultation(visit)));
    }
    if (staff.canReceiveQueue &&
        {VisitStage.registered, VisitStage.queued, VisitStage.checkedIn}
            .contains(visit.stage)) {
      actions.add(_action(
          'Batalkan',
          () => _run(() async {
                await _repository.cancelVisit(visit.encounterId);
              })));
    }
    return actions;
  }

  Widget _action(String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: _loading ? null : onPressed,
        child: Text(label),
      );

  Future<void> _recordTriage(Visit visit) async {
    final noteController = TextEditingController();
    var priority = TriageLevel.routine;
    var redFlag = false;
    final result = await showDialog<TriageRecord>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Catat triase'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TriageLevel>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Prioritas'),
                  items: TriageLevel.values
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => priority = value);
                  },
                ),
                TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'Catatan triase'),
                  maxLines: 3,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: redFlag,
                  title: const Text('Tandai perlu perhatian segera'),
                  onChanged: (value) => setDialogState(() => redFlag = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                TriageRecord(
                  priority: priority,
                  redFlag: redFlag,
                  notes: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ),
              ),
              child: const Text('Simpan triase'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result == null) return;
    await _run(() async {
      await _repository.recordTriage(
        visit.encounterId,
        result,
        readyForDoctor: true,
      );
    });
  }

  Future<void> _submitIntake(Visit visit) async {
    final complaint = TextEditingController();
    final duration = TextEditingController();
    final history = TextEditingController();
    final allergies = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<IntakeData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skrining awal'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _recordField(complaint, 'Keluhan utama'),
                _recordField(duration, 'Lama keluhan'),
                _recordField(history, 'Riwayat kesehatan'),
                _recordField(allergies, 'Alergi obat'),
                _recordField(notes, 'Catatan tambahan'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (complaint.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                IntakeData(
                  chiefComplaint: complaint.text.trim(),
                  durationText: duration.text.trim().isEmpty
                      ? null
                      : duration.text.trim(),
                  medicalHistory:
                      history.text.trim().isEmpty ? null : history.text.trim(),
                  medicationAllergies: allergies.text.trim().isEmpty
                      ? null
                      : allergies.text.trim(),
                  additionalNotes:
                      notes.text.trim().isEmpty ? null : notes.text.trim(),
                ),
              );
            },
            child: const Text('Simpan skrining'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _run(() async {
        await _repository.submitIntake(visit.encounterId, result);
      });
    }
    complaint.dispose();
    duration.dispose();
    history.dispose();
    allergies.dispose();
    notes.dispose();
  }

  Future<void> _completeConsultation(Visit visit) async {
    final subjective = TextEditingController();
    final objective = TextEditingController();
    final assessment = TextEditingController();
    final plan = TextEditingController();
    final medicineName = TextEditingController();
    final medicineDose = TextEditingController();
    final medicineFrequency = TextEditingController();
    final medicineQuantity = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rekam medis dan ringkasan pulang'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _recordField(subjective, 'Subjektif / keluhan'),
                _recordField(objective, 'Objektif / pemeriksaan'),
                _recordField(assessment, 'Asesmen'),
                _recordField(plan, 'Rencana'),
                const Divider(),
                TextField(
                  controller: medicineName,
                  decoration: const InputDecoration(
                    labelText: 'Nama obat (opsional)',
                  ),
                ),
                TextField(
                  controller: medicineDose,
                  decoration: const InputDecoration(labelText: 'Dosis'),
                ),
                TextField(
                  controller: medicineFrequency,
                  decoration:
                      const InputDecoration(labelText: 'Frekuensi penggunaan'),
                ),
                TextField(
                  controller: medicineQuantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan, tanda tangani & lanjut')),
        ],
      ),
    );
    if (result != true) {
      subjective.dispose();
      objective.dispose();
      assessment.dispose();
      plan.dispose();
      medicineName.dispose();
      medicineDose.dispose();
      medicineFrequency.dispose();
      medicineQuantity.dispose();
      return;
    }
    if ([subjective, objective, assessment, plan]
        .every((field) => field.text.trim().isEmpty)) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Isi rekam medis sebelum menyelesaikan pemeriksaan.';
        });
      }
      subjective.dispose();
      objective.dispose();
      assessment.dispose();
      plan.dispose();
      medicineName.dispose();
      medicineDose.dispose();
      medicineFrequency.dispose();
      medicineQuantity.dispose();
      return;
    }
    await _run(() async {
      await _repository.saveMedicalRecord(
        visit.encounterId,
        MedicalRecordVersion(
          recordId: '',
          version: 0,
          subjective: subjective.text,
          objective: objective.text,
          assessment: assessment.text,
          plan: plan.text,
        ),
      );
      await _repository.signMedicalRecord(visit.encounterId);
      if (medicineName.text.trim().isNotEmpty) {
        await _repository.issuePrescription(
          visit.encounterId,
          [
            PrescriptionItem(
              medicineName: medicineName.text.trim(),
              dose: medicineDose.text.trim().isEmpty
                  ? null
                  : medicineDose.text.trim(),
              frequency: medicineFrequency.text.trim().isEmpty
                  ? null
                  : medicineFrequency.text.trim(),
              quantity: int.tryParse(medicineQuantity.text.trim()),
            ),
          ],
        );
      }
      await _repository.completeConsultation(
        visit.encounterId,
        Discharge(
          encounterId: visit.encounterId,
          summary: assessment.text,
          followUpNote: plan.text,
        ),
      );
    });
    subjective.dispose();
    objective.dispose();
    assessment.dispose();
    plan.dispose();
    medicineName.dispose();
    medicineDose.dispose();
    medicineFrequency.dispose();
    medicineQuantity.dispose();
  }

  Widget _recordField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          maxLines: 3,
        ),
      );

  Future<void> _registerVisit() async {
    final clinic = context.read<ClinicController>();
    final services = clinic.services;
    final patientName = TextEditingController();
    final phone = TextEditingController();
    final complaint = TextEditingController();
    final patientQuery = TextEditingController();
    var service = services.first;
    var selectedGender = 'female';
    var existingPatient = false;
    String? selectedPatientId;
    var patientMatches = <ClinicPatient>[];
    final result = await showDialog<RegisterVisitRequest>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Daftarkan kunjungan'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: service.serviceType,
                    decoration: const InputDecoration(labelText: 'Layanan'),
                    items: services
                        .map((item) => DropdownMenuItem(
                              value: item.serviceType,
                              child: Text(item.serviceType),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => service = services
                            .firstWhere((item) => item.serviceType == value));
                      }
                    },
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Pasien baru')),
                      ButtonSegment(
                          value: true, label: Text('Pasien terdaftar')),
                    ],
                    selected: {existingPatient},
                    onSelectionChanged: (value) => setDialogState(() {
                      existingPatient = value.first;
                      selectedPatientId = null;
                    }),
                  ),
                  if (existingPatient) ...[
                    TextField(
                      controller: patientQuery,
                      decoration: InputDecoration(
                        labelText: 'Cari nama atau nomor rekam medis',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            final rows = await _repository.searchPatients(
                              clinic.clinicId!,
                              patientQuery.text,
                            );
                            setDialogState(() => patientMatches = rows);
                          },
                        ),
                      ),
                      onSubmitted: (query) async {
                        final rows = await _repository.searchPatients(
                          clinic.clinicId!,
                          query,
                        );
                        setDialogState(() => patientMatches = rows);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPatientId,
                      decoration:
                          const InputDecoration(labelText: 'Pasien terpilih'),
                      items: patientMatches
                          .map((item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  '${item.fullName} · ${item.medicalRecordNo}',
                                ),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedPatientId = value),
                    ),
                  ] else ...[
                    TextField(
                      controller: patientName,
                      decoration: const InputDecoration(
                        labelText: 'Nama pasien',
                        hintText: 'Wajib untuk pasien datang langsung',
                      ),
                    ),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Nomor telepon'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration:
                          const InputDecoration(labelText: 'Jenis kelamin'),
                      items: const [
                        DropdownMenuItem(
                            value: 'female', child: Text('Perempuan')),
                        DropdownMenuItem(
                            value: 'male', child: Text('Laki-laki')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedGender = value);
                        }
                      },
                    ),
                  ],
                  TextField(
                    controller: complaint,
                    decoration:
                        const InputDecoration(labelText: 'Keluhan awal'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final Map<String, dynamic>? patient;
                if (existingPatient) {
                  if (selectedPatientId == null) return;
                  patient = {'id': selectedPatientId};
                } else {
                  final name = patientName.text.trim();
                  if (name.isEmpty) return;
                  patient = {
                    'full_name': name,
                    'gender': selectedGender,
                    if (phone.text.trim().isNotEmpty)
                      'phone': phone.text.trim(),
                  };
                }
                Navigator.pop(
                  context,
                  RegisterVisitRequest(
                    clinicId: clinic.clinicId!,
                    serviceType: service.serviceType,
                    source: VisitSource.reception,
                    visitKind: VisitKind.inPerson,
                    patient: patient,
                    complaint: complaint.text.trim().isEmpty
                        ? null
                        : complaint.text.trim(),
                  ),
                );
              },
              child: const Text('Daftarkan'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await _run(() async {
        await _repository.registerVisit(result);
      });
    }
    patientName.dispose();
    phone.dispose();
    complaint.dispose();
    patientQuery.dispose();
  }

  Widget _buildPatients() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _patientSearch,
            decoration: InputDecoration(
              labelText: 'Cari nama atau nomor rekam medis',
              suffixIcon: IconButton(
                onPressed: _load,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 12),
          if (_patients.isEmpty)
            const _EmptyCard(message: 'Pasien tidak ditemukan.')
          else
            ..._patients.map((patient) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(patient.fullName),
                        subtitle: Text(
                          'No. RM ${patient.medicalRecordNo}'
                          '${patient.phone == null ? '' : ' · ${patient.phone}'}',
                        ),
                        trailing: Text(patient.registrationStatus),
                      ),
                    ),
                  ),
                )),
        ],
      );

  Widget _buildBilling(CurrentStaffController staff) {
    if (!staff.canManageBilling) {
      return const _MessageCard(
          message: 'Akses tagihan tidak tersedia untuk peran Anda.');
    }
    if (_invoices.isEmpty) {
      return const _EmptyCard(message: 'Belum ada tagihan.');
    }
    return Column(
      children: _invoices.map((invoice) {
        final actions = <Widget>[];
        if (invoice.status == InvoiceState.draft) {
          actions.add(_action('Ubah rincian', () => _editInvoice(invoice)));
          actions.add(_action(
              'Terbitkan',
              () => _run(() async {
                    await _repository.issueInvoice(invoice.id);
                  })));
        }
        if (staff.access?.canManageClinic == true &&
            {InvoiceState.draft, InvoiceState.issued, InvoiceState.failed}
                .contains(invoice.status)) {
          actions.add(_action('Batalkan tagihan', () => _voidInvoice(invoice)));
        }
        if ({
          InvoiceState.issued,
          InvoiceState.processing,
          InvoiceState.failed,
        }.contains(invoice.status)) {
          actions
              .add(_action('Catat pembayaran', () => _recordPayment(invoice)));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.reference,
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '${invoice.status.label} · Rp${invoice.total} · '
                    '${invoice.encounterId}',
                    style: context.sSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: actions),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _editInvoice(Invoice invoice) async {
    final initialItems = invoice.items.isEmpty
        ? [InvoiceItem(description: 'Biaya layanan', unitPrice: invoice.total)]
        : invoice.items;
    final descriptions = initialItems
        .map((item) => TextEditingController(text: item.description))
        .toList();
    final quantities = initialItems
        .map((item) => TextEditingController(text: '${item.quantity}'))
        .toList();
    final unitPrices = initialItems
        .map((item) => TextEditingController(text: '${item.unitPrice}'))
        .toList();
    final itemTypes = initialItems.map((item) => item.itemType).toList();
    final discount = TextEditingController(text: '${invoice.discount}');
    var validationMessage = '';
    final result = await showDialog<({List<InvoiceItem> items, int discount})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah rincian tagihan'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < descriptions.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          TextField(
                            controller: descriptions[index],
                            decoration: InputDecoration(
                              labelText: 'Rincian ${index + 1}',
                              suffixIcon: descriptions.length > 1
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Hapus rincian',
                                      onPressed: () {
                                        setDialogState(() {
                                          descriptions
                                              .removeAt(index)
                                              .dispose();
                                          quantities.removeAt(index).dispose();
                                          unitPrices.removeAt(index).dispose();
                                          itemTypes.removeAt(index);
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: quantities[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Jumlah'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: unitPrices[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Harga satuan (rupiah)'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setDialogState(() {
                        descriptions.add(TextEditingController());
                        quantities.add(TextEditingController(text: '1'));
                        unitPrices.add(TextEditingController(text: '0'));
                        itemTypes.add('manual');
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah rincian'),
                    ),
                  ),
                  TextField(
                    controller: discount,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Diskon (rupiah)'),
                  ),
                  if (validationMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationMessage,
                        style: TextStyle(color: context.c.danger),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final items = <InvoiceItem>[];
                for (var index = 0; index < descriptions.length; index++) {
                  final description = descriptions[index].text.trim();
                  final quantity = int.tryParse(quantities[index].text.trim());
                  final unitPrice = int.tryParse(unitPrices[index].text.trim());
                  if (description.isEmpty ||
                      quantity == null ||
                      quantity < 1 ||
                      unitPrice == null ||
                      unitPrice < 0) {
                    setDialogState(() {
                      validationMessage =
                          'Isi rincian, jumlah minimal 1, dan harga yang valid.';
                    });
                    return;
                  }
                  items.add(InvoiceItem(
                    description: description,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    itemType: itemTypes[index],
                  ));
                }
                final discountValue = int.tryParse(discount.text.trim());
                if (discountValue == null || discountValue < 0) {
                  setDialogState(() {
                    validationMessage = 'Masukkan diskon rupiah yang valid.';
                  });
                  return;
                }
                Navigator.pop(context, (items: items, discount: discountValue));
              },
              child: const Text('Simpan rincian'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      ...descriptions,
      ...quantities,
      ...unitPrices,
      discount,
    ]) {
      controller.dispose();
    }
    if (result != null) {
      await _run(() async {
        await _repository.updateInvoiceItems(
          invoice.encounterId,
          result.items,
          discount: result.discount,
        );
      });
    }
  }

  Future<void> _voidInvoice(Invoice invoice) async {
    final reason = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan tagihan'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: 'Alasan pembatalan'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali')),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Batalkan tagihan'),
          ),
        ],
      ),
    );
    final note = reason.text.trim();
    reason.dispose();
    if (result == true) {
      await _run(() async {
        await _repository.voidInvoice(invoice.id, reason: note);
      });
    }
  }

  Future<void> _recordPayment(Invoice invoice) async {
    final amount = TextEditingController(text: '${invoice.total}');
    var method = 'cash';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Catat pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah (rupiah)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Metode'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(
                      value: 'bank_transfer', child: Text('Transfer bank')),
                  DropdownMenuItem(
                      value: 'debit_card', child: Text('Kartu debit')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'bpjs', child: Text('BPJS')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => method = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Simpan pembayaran')),
          ],
        ),
      ),
    );
    final value = int.tryParse(amount.text.trim());
    amount.dispose();
    if (confirmed != true || value == null || value < 1) return;
    await _run(() async {
      await _repository.recordOfflinePayment(
        invoice.id,
        amount: value,
        method: method,
      );
    });
  }

  Widget _buildInbox() {
    if (_inbox.isEmpty) return const _EmptyCard(message: 'Kotak masuk kosong.');
    return Column(
      children: _inbox
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(item.body ?? item.kind),
                      leading: Icon(
                        item.severity == 'critical'
                            ? Icons.warning_amber_rounded
                            : Icons.notifications_none,
                      ),
                      trailing: item.isRead
                          ? const Icon(Icons.done,
                              semanticLabel: 'Sudah dibaca')
                          : TextButton(
                              onPressed: () => _run(
                                () => _repository.markInboxRead([item.id]),
                              ),
                              child: const Text('Tandai dibaca'),
                            ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEmergencies(CurrentStaffController staff) {
    if (!staff.canReceiveQueue) {
      return const _MessageCard(
          message: 'Akses panggilan darurat tidak tersedia.');
    }
    if (_alerts.isEmpty) {
      return const _EmptyCard(message: 'Tidak ada panggilan darurat aktif.');
    }
    return Column(
      children: _alerts.map((alert) {
        final closed = {'resolved', 'false_alarm'}.contains(alert.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.patientName ?? 'Panggilan darurat',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.w700)),
                  Text(alert.message ?? alert.status, style: context.sSmall),
                  if (!closed)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final status in [
                          'acknowledged',
                          'dispatched',
                          'resolved',
                          'false_alarm',
                        ])
                          _action(
                              _statusLabel(status),
                              () => _run(() async {
                                    await _repository.updateEmergencyAlert(
                                      alert.id,
                                      status,
                                    );
                                  })),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'acknowledged' => 'Diterima',
        'dispatched' => 'Petugas menuju lokasi',
        'resolved' => 'Selesai',
        _ => 'Panggilan keliru',
      };
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(child: Text(message, style: context.sBody)),
                if (onRetry != null)
                  TextButton(
                      onPressed: onRetry, child: const Text('Coba lagi')),
              ],
            ),
          ),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
        child: SizedBox(
          width: double.infinity,
          child: Text(message, style: context.sSmall),
        ),
      );
}
