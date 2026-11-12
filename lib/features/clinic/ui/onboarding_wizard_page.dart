import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../../widgets/forms.dart';
import '../../auth/state/auth_controller.dart';
import '../models/clinic_document_model.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_equipment_model.dart';
import '../models/clinic_facility_model.dart';
import '../models/clinic_medicine_model.dart';
import '../models/clinic_org_structure_model.dart';

import '../state/clinic_controller.dart';
import '../widgets/document_upload_tile.dart';
import '../widgets/public_media_uploader.dart';
import 'health_workers/health_worker_form_dialog.dart';

class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({super.key, this.rejectionReason});

  final String? rejectionReason;

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  int _currentStep = 1;

  // Controllers for Step 1
  final _step1FormKey = GlobalKey<FormState>();
  final _clinicNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sioNumberCtrl = TextEditingController();
  final _npwpCtrl = TextEditingController();
  final _fasyankesCtrl = TextEditingController();
  final _deedNumberCtrl = TextEditingController();
  LegalEntityType? _selectedLegalType = LegalEntityType.individual;
  DateTime? _sioExpiryDate;

  // Controllers for Step 3
  bool _bpjsRegistered = false;
  final _bpjsCodeCtrl = TextEditingController();

  // Controllers for Step 4
  final _emrAppNameCtrl = TextEditingController();
  final _satusehatOrgCtrl = TextEditingController();
  final _satusehatSecretCtrl = TextEditingController();
  EmrAppType _selectedEmrType = EmrAppType.internal;

  bool _initializedData = false;
  bool _gettingLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedData) {
      _initFromClinic();
      _initializedData = true;
    }
  }

  void _initFromClinic() {
    final clinic = context.read<ClinicController>().clinic;
    if (clinic != null) {
      _currentStep = clinic.onboardingStep.clamp(1, 6);
      _clinicNameCtrl.text = clinic.clinicName ?? '';
      _selectedLegalType = clinic.legalEntityType ?? LegalEntityType.individual;
      _addressCtrl.text = clinic.addressFull ?? '';
      _latCtrl.text = clinic.latitude != null ? clinic.latitude.toString() : '';
      _lngCtrl.text =
          clinic.longitude != null ? clinic.longitude.toString() : '';
      _phoneCtrl.text = clinic.phone ?? '';
      _emailCtrl.text = clinic.email ?? '';
      _sioNumberCtrl.text = clinic.sioNumber ?? '';
      _sioExpiryDate = clinic.sioExpiry;
      _npwpCtrl.text = clinic.npwp ?? '';
      _fasyankesCtrl.text = clinic.fasyankesCode ?? '';
      _deedNumberCtrl.text = clinic.deedNumber ?? '';
      _bpjsRegistered = clinic.bpjsRegistered;
      _bpjsCodeCtrl.text = clinic.bpjsFacilityCode ?? '';
    }

    final emr = context.read<ClinicController>().emrSettings;
    if (emr != null) {
      _emrAppNameCtrl.text = emr.emrAppName ?? '';
      _satusehatOrgCtrl.text = emr.satusehatOrganizationId ?? '';
      _selectedEmrType = emr.emrAppType;
    }
  }

  @override
  void dispose() {
    _clinicNameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _sioNumberCtrl.dispose();
    _npwpCtrl.dispose();
    _fasyankesCtrl.dispose();
    _deedNumberCtrl.dispose();
    _bpjsCodeCtrl.dispose();
    _emrAppNameCtrl.dispose();
    _satusehatOrgCtrl.dispose();
    _satusehatSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Layanan lokasi GPS tidak aktif. Aktifkan GPS pada perangkat Anda.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Izin lokasi ditolak secara permanen. Izinkan melalui pengaturan aplikasi.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
        _gettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi GPS berhasil ditemukan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _gettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.mapError(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Isikan titik latitude dan longitude terlebih dahulu.')),
      );
      return;
    }
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _saveCurrentStepData() async {
    final clinicCtrl = context.read<ClinicController>();
    final currentClinic = clinicCtrl.clinic;
    if (currentClinic == null) return false;

    if (_currentStep == 1) {
      if (!(_step1FormKey.currentState?.validate() ?? false)) return false;

      final updated = currentClinic.copyWith(
        clinicName: _clinicNameCtrl.text.trim(),
        legalEntityType: _selectedLegalType,
        addressFull: _addressCtrl.text.trim(),
        latitude: double.tryParse(_latCtrl.text.trim()),
        longitude: double.tryParse(_lngCtrl.text.trim()),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        sioNumber: _sioNumberCtrl.text.trim(),
        sioExpiry: _sioExpiryDate,
        npwp: _npwpCtrl.text.trim(),
        fasyankesCode: _fasyankesCtrl.text.trim(),
        deedNumber: _deedNumberCtrl.text.trim(),
        onboardingStep: _currentStep,
      );

      return await clinicCtrl.updateBasicData(updated);
    } else if (_currentStep == 3) {
      final updated = currentClinic.copyWith(
        bpjsRegistered: _bpjsRegistered,
        bpjsFacilityCode: _bpjsCodeCtrl.text.trim(),
        onboardingStep: _currentStep,
      );

      return await clinicCtrl.updateBasicData(updated);
    } else if (_currentStep == 4) {
      final emr = clinicCtrl.emrSettings;
      if (emr != null) {
        await clinicCtrl.updateEmrSettings(
          emr.copyWith(
            emrAppName: _emrAppNameCtrl.text.trim(),
            emrAppType: _selectedEmrType,
            satusehatOrganizationId: _satusehatOrgCtrl.text.trim(),
          ),
        );
      }
      if (_satusehatSecretCtrl.text.trim().isNotEmpty) {
        await clinicCtrl.saveSatusehatSecret(_satusehatSecretCtrl.text.trim());
        _satusehatSecretCtrl.clear();
      }
      return true;
    } else {
      // Step 2, 5 save items dynamically on mutation
      final updated = currentClinic.copyWith(onboardingStep: _currentStep);
      await clinicCtrl.updateBasicData(updated);
      return true;
    }
  }

  Future<void> _goNext() async {
    final saved = await _saveCurrentStepData();
    if (saved && mounted) {
      if (_currentStep < 6) {
        setState(() => _currentStep++);
      }
    }
  }

  void _goBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final authCtrl = context.watch<AuthController>();
    final c = context.c;
    final onboarding = clinicCtrl.onboardingStatus;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(
            clinicCtrl.clinic?.clinicName ?? 'Onboarding Registrasi Klinik'),
        backgroundColor: c.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Progress',
            onPressed: () => clinicCtrl.refreshOnboardingStatus(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => authCtrl.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner rejection jika status rejected
          if (widget.rejectionReason != null &&
              widget.rejectionReason!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade900,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pendaftaran Sebelumnya Ditolak: "${widget.rejectionReason}". Perbaiki data di bawah lalu kirim kembali.',
                      style: context.sBody
                          .copyWith(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Top Stepper Navigation Header
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stepIndicator(
                      1, 'Data Dasar', onboarding.basicData.complete),
                  _stepIndicator(2, 'Layanan & Fasilitas',
                      onboarding.servicesFacilities.complete),
                  _stepIndicator(
                      3, 'Administrasi', onboarding.adminLegal.complete),
                  _stepIndicator(
                      4, 'Sistem RME', onboarding.emrSystem.complete),
                  _stepIndicator(
                      5, 'Tenaga Kesehatan', onboarding.healthWorkers.complete),
                  _stepIndicator(6, 'Tinjau & Kirim', onboarding.readyToSubmit),
                ],
              ),
            ),
          ),

          // Main Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildCurrentStepContent(context),
                ),
              ),
            ),
          ),

          // Bottom Action Navigation Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 1)
                  AppButton(
                    'Kembali',
                    icon: Icons.arrow_back,
                    kind: BtnKind.secondary,
                    onPressed: _goBack,
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    AppButton(
                      'Simpan Draf',
                      kind: BtnKind.secondary,
                      loading: clinicCtrl.loading,
                      onPressed: () => _saveCurrentStepData(),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep < 6)
                      AppButton(
                        'Simpan & Lanjut',
                        icon: Icons.arrow_forward,
                        kind: BtnKind.primary,
                        loading: clinicCtrl.loading,
                        onPressed: _goNext,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(int stepIndex, String title, bool isComplete) {
    final c = context.c;
    final bool isCurrent = _currentStep == stepIndex;

    return InkWell(
      onTap: () => setState(() => _currentStep = stepIndex),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? c.accent
                    : (isComplete ? Colors.green : c.border),
              ),
              child: Center(
                child: isComplete && !isCurrent
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$stepIndex',
                        style: context.sLabel.copyWith(
                          color:
                              isCurrent || isComplete ? Colors.white : c.muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: context.sLabel.copyWith(
                fontSize: 10,
                color: isCurrent ? c.accent : c.muted,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return _buildStep1DataDasar(context);
      case 2:
        return _buildStep2LayananFasilitas(context);
      case 3:
        return _buildStep3AdministrasiLegal(context);
      case 4:
        return _buildStep4SistemRme(context);
      case 5:
        return _buildStep5TenagaKesehatan(context);
      case 6:
        return _buildStep6TinjauKirim(context);
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: DATA DASAR ---
  Widget _buildStep1DataDasar(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';

    ClinicDocumentModel? sioDoc;
    ClinicDocumentModel? deedDoc;
    for (final doc in clinicCtrl.clinicDocuments) {
      if (doc.docType == DocumentType.sio) sioDoc = doc;
      if (doc.docType == DocumentType.deed_of_establishment) deedDoc = doc;
    }

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Langkah 1: Data Dasar Klinik', style: context.sH2),
            Text(
                'Isikan identitas resmi, lokasi, dan dokumen perizinan utama klinik Anda.',
                style: context.sSmall),
            const SizedBox(height: 24),

            AppFormField(
              label: 'Nama Resmi Klinik',
              hint: 'Nama sesuai SIO',
              controller: _clinicNameCtrl,
              validator: (v) =>
                  AppValidators.validateRequired(v, 'Nama resmi klinik'),
            ),
            const SizedBox(height: 16),

            Text('Bentuk Badan Hukum',
                style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<LegalEntityType>(
              initialValue: _selectedLegalType,
              items: LegalEntityType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLegalType = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            AppFormField(
              label: 'Alamat Lengkap Klinik',
              hint: 'Jalan, RT/RW, Kelurahan, Kecamatan, Kota/Kabupaten',
              controller: _addressCtrl,
              maxLines: 2,
              validator: (v) =>
                  AppValidators.validateRequired(v, 'Alamat lengkap'),
            ),
            const SizedBox(height: 16),

            // Geolocation Row
            Text('Titik Koordinat / Lokasi Geografis',
                style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'Latitude',
                    hint: '-6.200000',
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: true),
                    validator: (v) => AppValidators.validateLatitude(
                        double.tryParse(v ?? '')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppFormField(
                    label: 'Longitude',
                    hint: '106.816666',
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: true),
                    validator: (v) => AppValidators.validateLongitude(
                        double.tryParse(v ?? '')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                AppButton(
                  _gettingLocation
                      ? 'Mencari Lokasi...'
                      : 'Gunakan Lokasi Saya (GPS)',
                  icon: Icons.my_location,
                  kind: BtnKind.secondary,
                  loading: _gettingLocation,
                  onPressed: _getCurrentLocation,
                ),
                const SizedBox(width: 12),
                AppButton(
                  'Buka di Peta',
                  icon: Icons.map_outlined,
                  kind: BtnKind.secondary,
                  onPressed: _openGoogleMaps,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'Nomor Telepon Resmi',
                    hint: '081234567890',
                    controller: _phoneCtrl,
                    validator: AppValidators.validatePhone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppFormField(
                    label: 'Alamat Email Resmi',
                    hint: 'care@klinik.com',
                    controller: _emailCtrl,
                    validator: AppValidators.validateEmail,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'Nomor Surat Izin Operasional (SIO)',
                    hint: 'SIO/123/2025',
                    controller: _sioNumberCtrl,
                    validator: (v) =>
                        AppValidators.validateRequired(v, 'Nomor SIO'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Masa Berlaku SIO',
                          style: context.sBody
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _sioExpiryDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setState(() => _sioExpiryDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.c.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppFormatters.formatDate(_sioExpiryDate,
                                  fallback: 'Pilih Tanggal Masa Berlaku')),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DocumentUploadTile(
              title: 'Unggah Dokumen SIO Aktif',
              subtitle:
                  'Scan berkas asli Surat Izin Operasional Klinik yang masih berlaku',
              clinicId: clinicId,
              docType: DocumentType.sio,
              existingClinicDoc: sioDoc,
              isRequired: true,
              onChanged: () => clinicCtrl.refreshClinicDocuments(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'NPWP Klinik',
                    hint: '15 atau 16 digit angka',
                    controller: _npwpCtrl,
                    validator: AppValidators.validateNpwp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppFormField(
                    label: 'Kode Registrasi Fasyankes Kemenkes',
                    hint: 'Kode unik Kemenkes',
                    controller: _fasyankesCtrl,
                    validator: (v) =>
                        AppValidators.validateRequired(v, 'Kode fasyankes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedLegalType == LegalEntityType.pt ||
                _selectedLegalType == LegalEntityType.foundation) ...[
              AppFormField(
                label: 'Nomor Akta Pendirian',
                hint: 'Nomor akta PT/Yayasan',
                controller: _deedNumberCtrl,
                validator: (v) =>
                    AppValidators.validateRequired(v, 'Nomor akta pendirian'),
              ),
              const SizedBox(height: 16),
              DocumentUploadTile(
                title: 'Unggah Akta Pendirian (PT/Yayasan)',
                subtitle:
                    'Scan Akta Pendirian Notaris & Pengesahan Kemenkumham',
                clinicId: clinicId,
                docType: DocumentType.deed_of_establishment,
                existingClinicDoc: deedDoc,
                isRequired: true,
                onChanged: () => clinicCtrl.refreshClinicDocuments(),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('Identitas Visual Publik Klinik',
                style: context.sH2.copyWith(fontSize: 18)),
            Text(
                'Unggah logo dan foto sampul resmi yang akan ditampilkan ke pasien.',
                style: context.sSmall),
            const SizedBox(height: 16),

            PublicMediaUploader(
              title: 'Logo Resmi Klinik',
              subtitle: 'Logo format persegi (PNG/WEBP/JPG, maks. 5 MB)',
              clinicId: clinicId,
              kind: MediaKind.logo,
              existingMedia: clinicCtrl.mediaList,
              isRequired: true,
              onChanged: () => clinicCtrl.refreshMedia(),
            ),
            PublicMediaUploader(
              title: 'Foto Sampul Klinik',
              subtitle: 'Foto banner tampak depan klinik (16:9, maks. 5 MB)',
              clinicId: clinicId,
              kind: MediaKind.cover,
              existingMedia: clinicCtrl.mediaList,
              isRequired: true,
              onChanged: () => clinicCtrl.refreshMedia(),
            ),
            PublicMediaUploader(
              title: 'Galeri Foto Klinik (Opsional)',
              subtitle: 'Foto fasilitas dan suasana pelayanan (maks. 8 foto)',
              clinicId: clinicId,
              kind: MediaKind.gallery,
              existingMedia: clinicCtrl.mediaList,
              onChanged: () => clinicCtrl.refreshMedia(),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: LAYANAN & FASILITAS ---
  Widget _buildStep2LayananFasilitas(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';

    final standardCategories = [
      'Umum',
      'Gigi',
      'Anak',
      'Kecantikan',
      'Kandungan',
      'Mata',
      'THT',
      'Penyakit Dalam',
      'Fisioterapi',
      'Laboratorium',
    ];

    final activeCats = clinicCtrl.services
        .where((s) => s.isActive)
        .map((s) => s.serviceType)
        .toList();

    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Langkah 2: Layanan & Fasilitas Klinik', style: context.sH2),
              Text(
                  'Atur jenis pelayanan kesehatan, prasarana ruangan, peralatan medis, obat-obatan, dan jam operasional.',
                  style: context.sSmall),
              const SizedBox(height: 24),

              Text('1. Jenis Layanan / Spesialisasi Spesifik',
                  style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: standardCategories.map((cat) {
                  final isSelected = activeCats.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      final updated = List<String>.from(activeCats);
                      if (selected) {
                        updated.add(cat);
                      } else {
                        updated.remove(cat);
                      }
                      clinicCtrl.toggleServiceCategories(updated);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Facilities section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '2. Fasilitas & Prasarana Ruangan (${clinicCtrl.facilities.length})',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  AppButton(
                    'Tambah Ruang',
                    icon: Icons.add,
                    kind: BtnKind.secondary,
                    onPressed: () => _showFacilityDialog(context, clinicId),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (clinicCtrl.facilities.isEmpty)
                Text('Belum ada fasilitas/ruangan ditambahkan.',
                    style: context.sSmall)
              else
                Column(
                  children: clinicCtrl.facilities
                      .map((f) => ListTile(
                            leading: Icon(
                                f.isRoom ? Icons.meeting_room : Icons.business),
                            title: Text(f.name),
                            subtitle: Text(
                                '${f.kind.label} • Kapasitas: ${f.capacity ?? '-'} • Status: ${f.status.label}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => clinicCtrl.deleteFacility(f.id),
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 24),

              // Equipment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '3. Peralatan Medis & Non-Medis (${clinicCtrl.equipment.length})',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  AppButton(
                    'Tambah Alat',
                    icon: Icons.add,
                    kind: BtnKind.secondary,
                    onPressed: () => _showEquipmentDialog(context, clinicId),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (clinicCtrl.equipment.isEmpty)
                Text('Belum ada peralatan ditambahkan.', style: context.sSmall)
              else
                Column(
                  children: clinicCtrl.equipment
                      .map((eq) => ListTile(
                            leading: Icon(
                                eq.category == EquipmentCategory.medical
                                    ? Icons.medical_services
                                    : Icons.devices),
                            title: Text(eq.name),
                            subtitle: Text(
                                'Jumlah: ${eq.quantity} • Kondisi: ${eq.condition ?? 'Baik'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  clinicCtrl.deleteEquipment(eq.id),
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 24),

              // Medicines Catalog Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '4. Obat-obatan Tersedia (Opsional, ${clinicCtrl.medicines.length})',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      AppButton(
                        'Impor CSV',
                        icon: Icons.file_upload,
                        kind: BtnKind.secondary,
                        onPressed: () => _importCsvDialog(context),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        'Tambah Obat',
                        icon: Icons.add,
                        kind: BtnKind.secondary,
                        onPressed: () => _showMedicineDialog(context, clinicId),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (clinicCtrl.medicines.isEmpty)
                Text('Belum ada obat ditambahkan.', style: context.sSmall)
              else
                Column(
                  children: clinicCtrl.medicines
                      .map((m) => ListTile(
                            leading: const Icon(Icons.medication),
                            title: Text(m.name),
                            subtitle: Text(
                                '${m.dosageForm ?? '-'} • ${m.strength ?? '-'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => clinicCtrl.deleteMedicine(m.id),
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 24),

              // 7-day Operating Hours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5. Jam Operasional 7 Hari',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  AppButton(
                    'Salin ke Semua Hari Kerja',
                    icon: Icons.copy,
                    kind: BtnKind.secondary,
                    onPressed: () {
                      if (clinicCtrl.operatingHours.isNotEmpty) {
                        clinicCtrl.copyHoursToWeekdays(
                            clinicCtrl.operatingHours.first);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: clinicCtrl.operatingHours.map((hours) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(hours.dayName,
                              style: context.sBody
                                  .copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Switch(
                          value: hours.isOpen,
                          onChanged: (val) {
                            final updatedList =
                                clinicCtrl.operatingHours.map((h) {
                              if (h.id == hours.id) {
                                return h.copyWith(isOpen: val);
                              }
                              return h;
                            }).toList();
                            clinicCtrl.updateOperatingHours(updatedList);
                          },
                        ),
                        Text(hours.isOpen ? 'Buka' : 'Tutup',
                            style: context.sSmall),
                        if (hours.isOpen) ...[
                          const SizedBox(width: 16),
                          Text(
                              '${hours.openTime ?? '08:00'} - ${hours.closeTime ?? '17:00'}',
                              style: context.sBody),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 3: ADMINISTRASI & LEGAL ---
  Widget _buildStep3AdministrasiLegal(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';

    ClinicDocumentModel? requestLetterDoc;
    ClinicDocumentModel? qualityCommitmentDoc;
    ClinicDocumentModel? bpjsDoc;

    for (final doc in clinicCtrl.clinicDocuments) {
      if (doc.docType == DocumentType.registration_request_letter) {
        requestLetterDoc = doc;
      }
      if (doc.docType == DocumentType.quality_commitment_statement) {
        qualityCommitmentDoc = doc;
      }
      if (doc.docType == DocumentType.bpjs_cooperation_proof) {
        bpjsDoc = doc;
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langkah 3: Administrasi & Legal', style: context.sH2),
          Text(
              'Unggah surat permohonan, komitmen mutu, struktur organisasi, dan data BPJS Kesehatan.',
              style: context.sSmall),
          const SizedBox(height: 24),

          DocumentUploadTile(
            title: 'Unggah Surat Permohonan Registrasi',
            subtitle:
                'Surat resmi permohonan registrasi klinik ditandatangani penanggung jawab',
            clinicId: clinicId,
            docType: DocumentType.registration_request_letter,
            existingClinicDoc: requestLetterDoc,
            isRequired: true,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
          const SizedBox(height: 16),

          DocumentUploadTile(
            title: 'Unggah Surat Pernyataan Komitmen Mutu',
            subtitle:
                'Surat komitmen menjaga mutu pelayanan & keselamatan pasien',
            clinicId: clinicId,
            docType: DocumentType.quality_commitment_statement,
            existingClinicDoc: qualityCommitmentDoc,
            isRequired: true,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
          const SizedBox(height: 24),

          // Org Structure Editor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Struktur Organisasi Klinik (${clinicCtrl.orgStructure.length})',
                  style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
              AppButton(
                'Tambah Jabatan',
                icon: Icons.add,
                kind: BtnKind.secondary,
                onPressed: () => _showOrgStructureDialog(context, clinicId),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (clinicCtrl.orgStructure.isEmpty)
            Text('Belum ada struktur organisasi ditambahkan.',
                style: context.sSmall)
          else
            Column(
              children: clinicCtrl.orgStructure
                  .map((org) => ListTile(
                        leading: const Icon(Icons.account_tree_outlined),
                        title: Text('${org.position}: ${org.personName}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              clinicCtrl.deleteOrgStructureNode(org.id),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 24),

          // BPJS Section
          Row(
            children: [
              Switch(
                value: _bpjsRegistered,
                onChanged: (v) => setState(() => _bpjsRegistered = v),
              ),
              const SizedBox(width: 8),
              Text('Terdaftar & Bekerjasama dengan BPJS Kesehatan',
                  style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (_bpjsRegistered) ...[
            const SizedBox(height: 12),
            AppFormField(
              label: 'Kode Fasilitas Kesehatan BPJS (KDK)',
              hint: 'Kode Faskes BPJS',
              controller: _bpjsCodeCtrl,
              validator: (v) => _bpjsRegistered
                  ? AppValidators.validateRequired(v, 'Kode faskes BPJS')
                  : null,
            ),
            const SizedBox(height: 16),
            DocumentUploadTile(
              title: 'Unggah Bukti Kerjasama BPJS Kesehatan',
              subtitle:
                  'Scan perjanjian kerjasama / sertifikat faskes BPJS yang masih berlaku',
              clinicId: clinicId,
              docType: DocumentType.bpjs_cooperation_proof,
              existingClinicDoc: bpjsDoc,
              isRequired: true,
              onChanged: () => clinicCtrl.refreshClinicDocuments(),
            ),
          ],
        ],
      ),
    );
  }

  // --- STEP 4: SISTEM RME ---
  Widget _buildStep4SistemRme(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';
    final emr = clinicCtrl.emrSettings;

    ClinicDocumentModel? sopDoc;
    ClinicDocumentModel? photoDoc;
    ClinicDocumentModel? posterDoc;

    for (final doc in clinicCtrl.clinicDocuments) {
      if (doc.docType == DocumentType.service_sop) sopDoc = doc;
      if (doc.docType == DocumentType.clinic_photo) photoDoc = doc;
      if (doc.docType == DocumentType.educational_poster) posterDoc = doc;
    }

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langkah 4: Sistem RME & Integrasi SATUSEHAT',
              style: context.sH2),
          Text(
              'Informasi aplikasi Rekam Medis Elektronik (RME) dan integrasi Kemenkes SATUSEHAT.',
              style: context.sSmall),
          const SizedBox(height: 24),

          AppFormField(
            label: 'Nama Aplikasi RME',
            hint: 'contoh: Prometheon RME / Aplikasi Pihak Ke-3',
            controller: _emrAppNameCtrl,
            validator: (v) =>
                AppValidators.validateRequired(v, 'Nama aplikasi RME'),
          ),
          const SizedBox(height: 16),

          Text('Jenis Aplikasi RME',
              style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<EmrAppType>(
            initialValue: _selectedEmrType,
            items: EmrAppType.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedEmrType = v ?? EmrAppType.internal),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          AppFormField(
            label: 'ID Organisasi SATUSEHAT (Kemenkes)',
            hint: 'Kode Organization ID SATUSEHAT',
            controller: _satusehatOrgCtrl,
          ),
          const SizedBox(height: 16),

          // SATUSEHAT Write-only API Key Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppFormField(
                  label: 'Kode API Secret SATUSEHAT',
                  hint: emr?.satusehatConnected == true
                      ? 'Terhubung ✓ (Tersimpan)'
                      : 'Masukkan Client Secret SATUSEHAT',
                  controller: _satusehatSecretCtrl,
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                emr?.satusehatConnected == true ? 'Ganti Kode' : 'Simpan Kode',
                icon: Icons.vpn_key_outlined,
                kind: BtnKind.secondary,
                onPressed: () async {
                  if (_satusehatSecretCtrl.text.trim().isNotEmpty) {
                    final ok = await clinicCtrl
                        .saveSatusehatSecret(_satusehatSecretCtrl.text.trim());
                    if (ok && context.mounted) {
                      _satusehatSecretCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Kode API SATUSEHAT berhasil tersimpan!'),
                            backgroundColor: Colors.green),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          DocumentUploadTile(
            title: 'Unggah SOP Layanan Klinik',
            subtitle: 'Dokumen SOP pelayanan medis & tata kelola rekam medis',
            clinicId: clinicId,
            docType: DocumentType.service_sop,
            existingClinicDoc: sopDoc,
            isRequired: true,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
          const SizedBox(height: 16),

          DocumentUploadTile(
            title: 'Unggah Foto Fisik Klinik',
            subtitle: 'Tampak depan, ruang tunggu, dan ruang periksa utama',
            clinicId: clinicId,
            docType: DocumentType.clinic_photo,
            existingClinicDoc: photoDoc,
            isRequired: true,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
          const SizedBox(height: 16),

          DocumentUploadTile(
            title: 'Unggah Poster Edukasi Kesehatan (Opsional)',
            subtitle: 'Poster edukasi pasien di ruang tunggu',
            clinicId: clinicId,
            docType: DocumentType.educational_poster,
            existingClinicDoc: posterDoc,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
        ],
      ),
    );
  }

  // --- STEP 5: TENAGA KESEHATAN ---
  Widget _buildStep5TenagaKesehatan(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Langkah 5: Penanggung Jawab & Tenaga Kesehatan',
                      style: context.sH2),
                  Text('Daftar dokter dan perawat aktif beserta STR & SIP.',
                      style: context.sSmall),
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
          if (clinicCtrl.healthWorkers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.people_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Belum Ada Tenaga Kesehatan Terdaftar',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      'Setidaknya harus ada 1 Penanggung Jawab Klinik dan Dokter dengan STR & SIP aktif.',
                      style: context.sSmall,
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else
            Column(
              children: clinicCtrl.healthWorkers.map((worker) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(worker.fullName.isNotEmpty
                          ? worker.fullName[0]
                          : 'N'),
                    ),
                    title: Row(
                      children: [
                        Text(worker.fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if (worker.isPersonInCharge) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Penanggung Jawab',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.blue.shade800,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                        '${worker.workerType.label} • STR: ${worker.strNumber ?? '-'} • SIP: ${worker.sipNumber ?? '-'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => HealthWorkerFormDialog(
                              clinicId: clinicId, initialWorker: worker),
                        ).then((_) => clinicCtrl.loadClinicData(clinicId));
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- STEP 6: TINJAU & KIRIM ---
  Widget _buildStep6TinjauKirim(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final onboarding = clinicCtrl.onboardingStatus;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langkah 6: Tinjau Ringkasan & Kirim Pendaftaran',
              style: context.sH2),
          Text(
              'Periksa kelengkapan semua bagian sebelum mengirimkan pendaftaran ke tim verifikasi.',
              style: context.sSmall),
          const SizedBox(height: 24),
          _summarySectionTile(1, 'Data Dasar Klinik', onboarding.basicData),
          _summarySectionTile(
              2, 'Layanan & Fasilitas Klinik', onboarding.servicesFacilities),
          _summarySectionTile(3, 'Administrasi & Legal', onboarding.adminLegal),
          _summarySectionTile(
              4, 'Sistem RME & SATUSEHAT', onboarding.emrSystem),
          _summarySectionTile(5, 'Penanggung Jawab & Tenaga Kesehatan',
              onboarding.healthWorkers),
          const SizedBox(height: 32),
          if (!onboarding.readyToSubmit)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade800),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pendaftaran belum dapat dikirim. Lengkapi item-item yang bertanda merah di atas terlebih dahulu.',
                      style: context.sBody.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Semua persyaratan data onboarding telah LENGKAP! Anda dapat menekan tombol di bawah untuk mengajukan verifikasi.',
                      style: context.sBody.copyWith(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          AppButton(
            'Kirim Pendaftaran untuk Verifikasi',
            icon: Icons.send_outlined,
            kind: BtnKind.primary,
            loading: clinicCtrl.loading,
            onPressed: onboarding.readyToSubmit
                ? () async {
                    final ok = await clinicCtrl.submitClinicForReview();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Pendaftaran berhasil dikirim! Menunggu peninjauan verifikator.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _summarySectionTile(int stepIdx, String title, sectionStatus) {
    final c = context.c;
    final bool complete = sectionStatus.complete;
    final List<String> missing = List<String>.from(sectionStatus.missing);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: complete
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.red.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    complete ? Icons.check_circle : Icons.cancel,
                    color: complete ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentStep = stepIdx),
                child: const Text('Ubah'),
              ),
            ],
          ),
          if (!complete && missing.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Item yang belum lengkap:',
                style:
                    context.sSmall.copyWith(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: missing.map((itemKey) {
                final label = ErrorMapper.technicalKeyToIndonesian(itemKey);
                return InkWell(
                  onTap: () {
                    final targetStep = ErrorMapper.keyToStepIndex(itemKey);
                    setState(() => _currentStep = targetStep);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $label',
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            decoration: TextDecoration.underline)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- DIALOG HELPERS ---
  void _showFacilityDialog(BuildContext context, String clinicId) {
    final nameCtrl = TextEditingController();
    FacilityKind selectedKind = FacilityKind.consultation_room;
    int capacity = 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Fasilitas / Ruangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
                label: 'Nama Ruangan',
                hint: 'Ruang Periksa 1',
                controller: nameCtrl),
            const SizedBox(height: 12),
            DropdownButtonFormField<FacilityKind>(
              initialValue: selectedKind,
              items: FacilityKind.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged: (v) =>
                  selectedKind = v ?? FacilityKind.consultation_room,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<ClinicController>().saveFacility(
                      ClinicFacilityModel(
                        id: '',
                        clinicId: clinicId,
                        name: nameCtrl.text.trim(),
                        kind: selectedKind,
                        capacity: capacity,
                      ),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentDialog(BuildContext context, String clinicId) {
    final nameCtrl = TextEditingController();
    EquipmentCategory category = EquipmentCategory.medical;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Peralatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
                label: 'Nama Alat',
                hint: 'Stetoskop / Timbangan Digital',
                controller: nameCtrl),
            const SizedBox(height: 12),
            DropdownButtonFormField<EquipmentCategory>(
              initialValue: category,
              items: EquipmentCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => category = v ?? EquipmentCategory.medical,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<ClinicController>().saveEquipment(
                      ClinicEquipmentModel(
                        id: '',
                        clinicId: clinicId,
                        name: nameCtrl.text.trim(),
                        category: category,
                      ),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMedicineDialog(BuildContext context, String clinicId) {
    final nameCtrl = TextEditingController();
    final formCtrl = TextEditingController();
    final strengthCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Obat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
                label: 'Nama Obat', hint: 'Paracetamol', controller: nameCtrl),
            const SizedBox(height: 12),
            AppFormField(
                label: 'Bentuk Sediaan',
                hint: 'Tablet / Sirup',
                controller: formCtrl),
            const SizedBox(height: 12),
            AppFormField(
                label: 'Kekuatan Dosis',
                hint: '500 mg',
                controller: strengthCtrl),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<ClinicController>().saveMedicine(
                      ClinicMedicineModel(
                        id: '',
                        clinicId: clinicId,
                        name: nameCtrl.text.trim(),
                        dosageForm: formCtrl.text.trim(),
                        strength: strengthCtrl.text.trim(),
                      ),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _importCsvDialog(BuildContext context) {
    final csvCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impor Obat dari CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Tempelkan isi CSV dengan format: nama,bentuk,kekuatan per baris.'),
            const SizedBox(height: 12),
            TextField(
              controller: csvCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                  hintText:
                      'Paracetamol,Tablet,500mg\nAmoxicillin,Kapsul,500mg',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (csvCtrl.text.trim().isNotEmpty) {
                context
                    .read<ClinicController>()
                    .importMedicinesFromCsv(csvCtrl.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Impor Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showOrgStructureDialog(BuildContext context, String clinicId) {
    final personCtrl = TextEditingController();
    final positionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Jabatan Organisasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
                label: 'Nama Pejabat',
                hint: 'dr. Budi Santoso',
                controller: personCtrl),
            const SizedBox(height: 12),
            AppFormField(
                label: 'Jabatan / Posisi',
                hint: 'Kepala Klinik / Kepala Tata Usaha',
                controller: positionCtrl),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (personCtrl.text.trim().isNotEmpty &&
                  positionCtrl.text.trim().isNotEmpty) {
                context.read<ClinicController>().saveOrgStructureNode(
                      ClinicOrgStructureModel(
                        id: '',
                        clinicId: clinicId,
                        personName: personCtrl.text.trim(),
                        position: positionCtrl.text.trim(),
                      ),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
