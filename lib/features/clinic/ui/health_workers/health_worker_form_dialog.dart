import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/context_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/buttons.dart';
import '../../../../widgets/forms.dart';
import '../../models/clinic_enums.dart';
import '../../models/health_worker_models.dart';
import '../../state/clinic_controller.dart';
import '../../widgets/document_upload_tile.dart';

class HealthWorkerFormDialog extends StatefulWidget {
  const HealthWorkerFormDialog({
    super.key,
    required this.clinicId,
    this.initialWorker,
  });

  final String clinicId;
  final HealthWorkerModel? initialWorker;

  @override
  State<HealthWorkerFormDialog> createState() => _HealthWorkerFormDialogState();
}

class _HealthWorkerFormDialogState extends State<HealthWorkerFormDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Data Pribadi
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _homeAddressCtrl = TextEditingController();
  final _npwpCtrl = TextEditingController();
  DateTime? _birthDate;

  // Data Profesional
  HealthWorkerType _selectedType = HealthWorkerType.doctor;
  bool _isPersonInCharge = false;
  final _titleCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _strNumberCtrl = TextEditingController();
  final _sipNumberCtrl = TextEditingController();
  DateTime? _strExpiry;
  DateTime? _sipExpiry;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialWorker != null) {
      final w = widget.initialWorker!;
      _fullNameCtrl.text = w.fullName;
      _selectedType = w.workerType;
      _isPersonInCharge = w.isPersonInCharge;
      _titleCtrl.text = w.titleDegree ?? '';
      _specializationCtrl.text = w.specialization ?? '';
      _strNumberCtrl.text = w.strNumber ?? '';
      _strExpiry = w.strExpiry;
      _sipNumberCtrl.text = w.sipNumber ?? '';
      _sipExpiry = w.sipExpiry;

      final p = w.privateData;
      if (p != null) {
        _phoneCtrl.text = p.phone ?? '';
        _emailCtrl.text = p.email ?? '';
        _nikCtrl.text = p.nik ?? '';
        _homeAddressCtrl.text = p.homeAddress ?? '';
        _npwpCtrl.text = p.npwp ?? '';
        _birthDate = p.birthDate;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _nikCtrl.dispose();
    _homeAddressCtrl.dispose();
    _npwpCtrl.dispose();
    _titleCtrl.dispose();
    _specializationCtrl.dispose();
    _strNumberCtrl.dispose();
    _sipNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final worker = HealthWorkerModel(
      id: widget.initialWorker?.id ?? '',
      clinicId: widget.clinicId,
      workerType: _selectedType,
      isPersonInCharge: _isPersonInCharge,
      fullName: _fullNameCtrl.text.trim(),
      titleDegree:
          _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : null,
      specialization: _specializationCtrl.text.trim().isNotEmpty
          ? _specializationCtrl.text.trim()
          : null,
      strNumber: _strNumberCtrl.text.trim().isNotEmpty
          ? _strNumberCtrl.text.trim()
          : null,
      strExpiry: _strExpiry,
      sipNumber: _sipNumberCtrl.text.trim().isNotEmpty
          ? _sipNumberCtrl.text.trim()
          : null,
      sipExpiry: _sipExpiry,
    );

    final privateData = HealthWorkerPrivateModel(
      workerId: widget.initialWorker?.id ?? '',
      clinicId: widget.clinicId,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      nik: _nikCtrl.text.trim().isNotEmpty ? _nikCtrl.text.trim() : null,
      homeAddress: _homeAddressCtrl.text.trim().isNotEmpty
          ? _homeAddressCtrl.text.trim()
          : null,
      npwp: _npwpCtrl.text.trim().isNotEmpty ? _npwpCtrl.text.trim() : null,
      birthDate: _birthDate,
    );

    final clinicCtrl = context.read<ClinicController>();
    final success = await clinicCtrl.saveHealthWorker(
      worker: worker,
      privateData: privateData,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() => _error = clinicCtrl.errorMessage ??
            'Gagal menyimpan data tenaga kesehatan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final workerId = widget.initialWorker?.id ?? '';

    HealthWorkerDocumentModel? photoDoc;
    HealthWorkerDocumentModel? ktpDoc;
    HealthWorkerDocumentModel? strDoc;
    HealthWorkerDocumentModel? sipDoc;
    HealthWorkerDocumentModel? diplomaDoc;

    if (widget.initialWorker != null) {
      for (final doc in widget.initialWorker!.documents) {
        if (doc.docType == WorkerDocumentType.profile_photo) photoDoc = doc;
        if (doc.docType == WorkerDocumentType.ktp_scan) ktpDoc = doc;
        if (doc.docType == WorkerDocumentType.str_scan) strDoc = doc;
        if (doc.docType == WorkerDocumentType.sip_scan) sipDoc = doc;
        if (doc.docType == WorkerDocumentType.diploma_scan) diplomaDoc = doc;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialWorker == null
                        ? 'Tambah Tenaga Kesehatan'
                        : 'Ubah Data Tenaga Kesehatan',
                    style: context.sH2,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '1. Data Pribadi'),
                Tab(text: '2. Data Profesional'),
                Tab(text: '3. Dokumen Pendukung'),
              ],
            ),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.withValues(alpha: 0.1),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Data Pribadi
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          AppFormField(
                            label: 'Nama Lengkap (Tanpa Gelar)',
                            hint: 'contoh: Ahmad Subagyo',
                            controller: _fullNameCtrl,
                            validator: (v) => AppValidators.validateRequired(
                                v, 'Nama lengkap'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppFormField(
                                  label: 'Nomor Telepon / WhatsApp',
                                  hint: '081234567890',
                                  controller: _phoneCtrl,
                                  validator: AppValidators.validatePhone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppFormField(
                                  label: 'Email',
                                  hint: 'dokter@email.com',
                                  controller: _emailCtrl,
                                  validator: AppValidators.validateEmail,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppFormField(
                            label: 'NIK (16 Digit)',
                            hint: '3171234567890001',
                            controller: _nikCtrl,
                            validator: AppValidators.validateNik,
                          ),
                          const SizedBox(height: 12),
                          AppFormField(
                            label: 'Alamat Tempat Tinggal',
                            hint: 'Alamat domisili lengkap',
                            controller: _homeAddressCtrl,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          AppFormField(
                            label: 'NPWP Pribadi (Opsional)',
                            hint: '15 atau 16 digit angka',
                            controller: _npwpCtrl,
                            validator: AppValidators.validateNpwp,
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Data Profesional
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jenis Tenaga Kesehatan',
                                        style: context.sBody.copyWith(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<HealthWorkerType>(
                                      initialValue: _selectedType,
                                      items: HealthWorkerType.values
                                          .map((t) => DropdownMenuItem(
                                              value: t, child: Text(t.label)))
                                          .toList(),
                                      onChanged: (v) => setState(() =>
                                          _selectedType =
                                              v ?? HealthWorkerType.doctor),
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder()),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppFormField(
                                  label: 'Gelar Akademik',
                                  hint: 'dr., Sp.PD / S.Kep',
                                  controller: _titleCtrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppFormField(
                            label: 'Spesialisasi / Keahlian Utama',
                            hint:
                                'Penyakit Dalam / Dokter Umum / Perawat Anestesi',
                            controller: _specializationCtrl,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Switch(
                                value: _isPersonInCharge,
                                onChanged: (v) =>
                                    setState(() => _isPersonInCharge = v),
                              ),
                              const SizedBox(width: 8),
                              Text('Penanggung Jawab Klinik',
                                  style: context.sBody
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // STR Row
                          Row(
                            children: [
                              Expanded(
                                child: AppFormField(
                                  label: 'Nomor STR Aktif',
                                  hint: 'Nomor Surat Tanda Registrasi',
                                  controller: _strNumberCtrl,
                                  validator: (v) =>
                                      AppValidators.validateRequired(
                                          v, 'Nomor STR'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Masa Berlaku STR',
                                        style: context.sBody.copyWith(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _strExpiry ??
                                              DateTime.now().add(
                                                  const Duration(days: 365)),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 3650)),
                                        );
                                        if (picked != null) {
                                          setState(() => _strExpiry = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: c.border),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(AppFormatters.formatDate(
                                                _strExpiry,
                                                fallback:
                                                    'Pilih Masa Berlaku STR')),
                                            const Icon(Icons.calendar_today,
                                                size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // SIP Row
                          Row(
                            children: [
                              Expanded(
                                child: AppFormField(
                                  label: 'Nomor SIP Aktif',
                                  hint: 'Nomor Surat Izin Praktik',
                                  controller: _sipNumberCtrl,
                                  validator: (v) =>
                                      AppValidators.validateRequired(
                                          v, 'Nomor SIP'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Masa Berlaku SIP',
                                        style: context.sBody.copyWith(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _sipExpiry ??
                                              DateTime.now().add(
                                                  const Duration(days: 365)),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 3650)),
                                        );
                                        if (picked != null) {
                                          setState(() => _sipExpiry = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: c.border),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(AppFormatters.formatDate(
                                                _sipExpiry,
                                                fallback:
                                                    'Pilih Masa Berlaku SIP')),
                                            const Icon(Icons.calendar_today,
                                                size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 3: Dokumen Pendukung
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: workerId.isEmpty
                          ? Center(
                              child: Text(
                                'Simpan data tenaga kesehatan terlebih dahulu untuk dapat mengunggah dokumen pendukung.',
                                style: context.sSmall,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                DocumentUploadTile(
                                  title: 'Unggah Pasfoto Formal',
                                  subtitle: 'Foto latar belakang merah/biru',
                                  clinicId: widget.clinicId,
                                  workerId: workerId,
                                  workerDocType:
                                      WorkerDocumentType.profile_photo,
                                  existingWorkerDoc: photoDoc,
                                  isRequired:
                                      _selectedType == HealthWorkerType.doctor,
                                ),
                                DocumentUploadTile(
                                  title: 'Unggah Scan KTP',
                                  subtitle: 'Scan KTP tenaga kesehatan',
                                  clinicId: widget.clinicId,
                                  workerId: workerId,
                                  workerDocType: WorkerDocumentType.ktp_scan,
                                  existingWorkerDoc: ktpDoc,
                                ),
                                DocumentUploadTile(
                                  title: 'Unggah Scan STR',
                                  subtitle: 'Scan Surat Tanda Registrasi aktif',
                                  clinicId: widget.clinicId,
                                  workerId: workerId,
                                  workerDocType: WorkerDocumentType.str_scan,
                                  existingWorkerDoc: strDoc,
                                ),
                                DocumentUploadTile(
                                  title: 'Unggah Scan SIP',
                                  subtitle:
                                      'Scan Surat Izin Praktik di klinik ini',
                                  clinicId: widget.clinicId,
                                  workerId: workerId,
                                  workerDocType: WorkerDocumentType.sip_scan,
                                  existingWorkerDoc: sipDoc,
                                ),
                                DocumentUploadTile(
                                  title:
                                      'Unggah Scan Ijazah Kedokteran/Keperawatan',
                                  subtitle:
                                      'Scan ijazah kelulusan perguruan tinggi',
                                  clinicId: widget.clinicId,
                                  workerId: workerId,
                                  workerDocType:
                                      WorkerDocumentType.diploma_scan,
                                  existingWorkerDoc: diplomaDoc,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Dialog Footer
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    'Simpan Tenaga Kesehatan',
                    icon: Icons.check,
                    kind: BtnKind.primary,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
