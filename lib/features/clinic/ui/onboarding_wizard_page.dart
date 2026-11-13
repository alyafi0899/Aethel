import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/l10n/terms_id.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models.dart';
import '../../../state/app_controller.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/common.dart';
import '../../../widgets/forms.dart';
import '../../help/field_help.dart';
import '../../help/support_actions.dart';
import '../../auth/state/auth_controller.dart';
import '../models/clinic_emr_settings_model.dart';
import '../models/clinic_document_model.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_equipment_model.dart';
import '../models/clinic_facility_model.dart';
import '../models/clinic_medicine_model.dart';
import '../models/clinic_operating_hours_model.dart';
import '../models/clinic_org_structure_model.dart';
import '../models/onboarding_recommendation.dart';
import '../models/onboarding_status_model.dart';

import '../state/clinic_controller.dart';
import '../widgets/document_upload_tile.dart';
import '../widgets/public_media_uploader.dart';
import '../widgets/rejected_items_panel.dart';
import '../widgets/verification_timeline.dart';
import 'health_workers/health_worker_form_dialog.dart';
import 'satusehat_secret_dialog.dart';

const kPrometheonEmrDescription = 'Rekam medis elektronik bawaan Prometheon.';

class _ClinicTemplate {
  const _ClinicTemplate({
    required this.name,
    required this.services,
    required this.rooms,
    required this.equipment,
  });

  final String name;
  final List<String> services;
  final List<String> rooms;
  final List<String> equipment;
}

const _clinicTemplates = [
  _ClinicTemplate(
    name: 'Klinik umum',
    services: ['Umum'],
    rooms: ['Ruang Konsultasi', 'Ruang Tindakan'],
    equipment: ['Stetoskop', 'Tensimeter'],
  ),
  _ClinicTemplate(
    name: 'Klinik gigi',
    services: ['Gigi'],
    rooms: ['Ruang Konsultasi', 'Ruang Tindakan'],
    equipment: ['Dental unit', 'Autoklaf'],
  ),
  _ClinicTemplate(
    name: 'Klinik ibu dan anak',
    services: ['Anak', 'Kandungan'],
    rooms: ['Ruang Konsultasi', 'Ruang Tindakan'],
    equipment: ['Doppler janin', 'Timbangan bayi'],
  ),
];

enum _OperatingTimeField { open, close, breakStart, breakEnd }

class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({
    super.key,
    this.rejectionReason,
    this.initialStep,
    this.showRmeSettings = false,
  });

  final String? rejectionReason;
  final int? initialStep;
  final bool showRmeSettings;

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
  EmrAppType _selectedEmrType = EmrAppType.prometheon;

  bool _initializedData = false;
  bool _gettingLocation = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _clinicNameCtrl,
      _addressCtrl,
      _latCtrl,
      _lngCtrl,
      _phoneCtrl,
      _emailCtrl,
      _sioNumberCtrl,
      _npwpCtrl,
      _fasyankesCtrl,
      _deedNumberCtrl,
      _bpjsCodeCtrl,
      _emrAppNameCtrl,
      _satusehatOrgCtrl,
    ]) {
      controller.addListener(_scheduleAutoSave);
    }
  }

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
    if (widget.showRmeSettings) _currentStep = 4;
    if (clinic != null) {
      final requestedStep = widget.initialStep ?? clinic.onboardingStep;
      _currentStep =
          widget.showRmeSettings ? 4 : _normalizeWizardStep(requestedStep);
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
    _autoSaveTimer?.cancel();
    for (final controller in [
      _clinicNameCtrl,
      _addressCtrl,
      _latCtrl,
      _lngCtrl,
      _phoneCtrl,
      _emailCtrl,
      _sioNumberCtrl,
      _npwpCtrl,
      _fasyankesCtrl,
      _deedNumberCtrl,
      _bpjsCodeCtrl,
      _emrAppNameCtrl,
      _satusehatOrgCtrl,
    ]) {
      controller.removeListener(_scheduleAutoSave);
    }
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

  void _scheduleAutoSave() {
    if (!_initializedData ||
        !mounted ||
        ![1, 3].contains(_currentStep) &&
            !(widget.showRmeSettings && _currentStep == 4)) {
      return;
    }
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 900), () async {
      _autoSaveTimer = null;
      final saved = await _saveCurrentStepData(
        validate: false,
        confirmEmrChoice: false,
      );
      if (!saved && mounted) {
        final clinicCtrl = context.read<ClinicController>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(clinicCtrl.errorMessage ??
                'Simpan otomatis belum berhasil. Periksa koneksi Anda.'),
          ),
        );
      }
    });
  }

  Future<bool> _saveCurrentStepData({
    bool showFeedback = false,
    bool validate = true,
    bool confirmEmrChoice = false,
  }) async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    final clinicCtrl = context.read<ClinicController>();
    final currentClinic = clinicCtrl.clinic;
    if (currentClinic == null) {
      return _reportStepSave(false, showFeedback, clinicCtrl);
    }

    if (_currentStep == 1) {
      if (validate && !(_step1FormKey.currentState?.validate() ?? false)) {
        return false;
      }

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

      final saved = await clinicCtrl.updateBasicData(updated);
      return _reportStepSave(saved, showFeedback, clinicCtrl);
    } else if (_currentStep == 3) {
      final updated = currentClinic.copyWith(
        bpjsRegistered: _bpjsRegistered,
        bpjsFacilityCode: _bpjsCodeCtrl.text.trim(),
        onboardingStep: _currentStep,
      );

      final saved = await clinicCtrl.updateBasicData(updated);
      return _reportStepSave(saved, showFeedback, clinicCtrl);
    } else if (_currentStep == 4) {
      final emr = clinicCtrl.emrSettings ??
          ClinicEmrSettingsModel(clinicId: currentClinic.id);
      final appName = _selectedEmrType == EmrAppType.thirdParty ||
              _selectedEmrType == EmrAppType.internal
          ? _emrAppNameCtrl.text.trim()
          : '';
      final organizationId = _selectedEmrType == EmrAppType.none
          ? ''
          : _satusehatOrgCtrl.text.trim();
      final saved = await clinicCtrl.updateEmrSettings(
        emr.copyWith(
          emrAppType: _selectedEmrType,
          emrAppName: appName.isEmpty ? null : appName,
          clearEmrAppName: appName.isEmpty,
          satusehatOrganizationId:
              organizationId.isEmpty ? null : organizationId,
          clearSatusehatOrganizationId: organizationId.isEmpty,
          emrChoiceConfirmed: confirmEmrChoice ? true : emr.emrChoiceConfirmed,
        ),
      );
      return _reportStepSave(saved, showFeedback, clinicCtrl);
    } else {
      // Step 2, 5 save items dynamically on mutation
      final updated = currentClinic.copyWith(onboardingStep: _currentStep);
      final saved = await clinicCtrl.updateBasicData(updated);
      return _reportStepSave(saved, showFeedback, clinicCtrl);
    }
  }

  bool _reportStepSave(
    bool saved,
    bool showFeedback,
    ClinicController clinicCtrl,
  ) {
    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved
              ? 'Progress tersimpan. Anda dapat melanjutkan nanti.'
              : clinicCtrl.errorMessage ??
                  'Progress belum tersimpan. Periksa koneksi dan coba lagi.'),
        ),
      );
    }
    return saved;
  }

  Future<void> _goNext() async {
    final saved = await _saveCurrentStepData(
      showFeedback: true,
      confirmEmrChoice: widget.showRmeSettings && _currentStep == 4,
    );
    if (saved && mounted) {
      if (_currentStep < 6) {
        setState(() => _currentStep = _nextWizardStep(_currentStep));
      }
    }
  }

  Future<void> _goToStep(int step) async {
    final targetStep =
        widget.showRmeSettings ? step : _normalizeWizardStep(step);
    if (targetStep == _currentStep) return;
    final saved = await _saveCurrentStepData(
      validate: false,
      confirmEmrChoice: false,
    );
    if (!mounted) return;
    if (!saved) {
      final clinicCtrl = context.read<ClinicController>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(clinicCtrl.errorMessage ??
              'Perubahan belum tersimpan. Periksa koneksi sebelum berpindah bagian.'),
        ),
      );
      if (!widget.showRmeSettings || _currentStep != 4) return;
    }
    setState(() => _currentStep = targetStep);
  }

  int _normalizeWizardStep(int step) {
    final boundedStep = step.clamp(1, 6);
    return boundedStep == 4 ? 5 : boundedStep;
  }

  int _nextWizardStep(int step) {
    if (!widget.showRmeSettings && step == 3) return 5;
    return step + 1;
  }

  void _goBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep =
            !widget.showRmeSettings && _currentStep == 5 ? 3 : _currentStep - 1;
      });
    }
  }

  void _openEmrSettings() {
    final app = context.read<AppController>();
    app.go(AppPage.clinicProfile);
    app.selectProfileTab(3);
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
          if (hasSupportContact)
            IconButton(
              icon: const Icon(Icons.support_agent_outlined),
              tooltip: 'Hubungi dukungan',
              onPressed: () => openSupportChat(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Progress',
            onPressed: () async {
              final refreshed = await clinicCtrl.refreshMedia();
              if (!refreshed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(clinicCtrl.errorMessage ??
                        'Status pendaftaran belum dapat diperbarui.'),
                  ),
                );
              }
            },
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

          if (!widget.showRmeSettings)
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
                      5,
                      'Tenaga Kesehatan',
                      onboarding.healthWorkers.complete,
                      displayNumber: 4,
                    ),
                    _stepIndicator(
                      6,
                      'Tinjau & Kirim',
                      onboarding.readyToSubmit,
                      displayNumber: 5,
                    ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (clinicCtrl.clinic?.status == ClinicStatus.rejected)
                        RejectedItemsPanel(
                          onFix: _goToStep,
                        ),
                      if (clinicCtrl.clinic?.status == ClinicStatus.rejected &&
                          clinicCtrl.clinic != null) ...[
                        const SizedBox(height: 12),
                        VerificationTimeline(clinic: clinicCtrl.clinic!),
                        const SizedBox(height: 12),
                      ],
                      if (clinicCtrl.emrInitializationError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pengaturan RME otomatis belum tersimpan: ${clinicCtrl.emrInitializationError}',
                                    style: context.sSmall,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final saved = await clinicCtrl
                                        .ensurePrometheonEmrSettings();
                                    if (!saved && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(clinicCtrl
                                                  .emrInitializationError ??
                                              'Pengaturan RME belum berhasil disimpan.'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!widget.showRmeSettings)
                        _missingItemsBanner(onboarding),
                      _buildCurrentStepContent(context),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (widget.showRmeSettings)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  'Simpan perubahan',
                  icon: Icons.check,
                  kind: BtnKind.primary,
                  loading: clinicCtrl.loading,
                  onPressed: () => _saveCurrentStepData(
                    showFeedback: true,
                    confirmEmrChoice: true,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  if (_currentStep > 1)
                    AppButton(
                      'Kembali',
                      icon: Icons.arrow_back,
                      kind: BtnKind.secondary,
                      onPressed: _goBack,
                    )
                  else
                    const SizedBox.shrink(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppButton(
                        'Simpan & lanjut besok',
                        kind: BtnKind.secondary,
                        loading: clinicCtrl.loading,
                        onPressed: () => _saveCurrentStepData(
                          showFeedback: true,
                          confirmEmrChoice: false,
                        ),
                      ),
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

  Widget _missingItemsBanner(OnboardingStatusModel status) {
    final missing = [
      ...status.basicData.missing,
      ...status.servicesFacilities.missing,
      ...status.adminLegal.missing,
      ...status.healthWorkers.missing,
      ...status.publicMedia.missing,
    ];
    if (missing.isEmpty || status.readyToSubmit) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.checklist_outlined),
          title: Text('Tinggal ${missing.length} hal lagi'),
          subtitle: Text(
              'Ketuk untuk melengkapi: ${ErrorMapper.technicalKeyToIndonesian(missing.first)}'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => _goToStep(ErrorMapper.keyToStepIndex(missing.first)),
        ),
      ),
    );
  }

  Widget _stepIndicator(
    int stepIndex,
    String title,
    bool isComplete, {
    int? displayNumber,
  }) {
    final c = context.c;
    final bool isCurrent = _currentStep == stepIndex;

    return InkWell(
      onTap: () => _goToStep(stepIndex),
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
                        '${displayNumber ?? stepIndex}',
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
              onChanged: (v) {
                setState(() => _selectedLegalType = v);
                _scheduleAutoSave();
              },
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
            Text('Atau ketuk peta untuk memilih titik klinik.',
                style: context.sSmall),
            const SizedBox(height: 8),
            _buildLocationMap(),
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
                            _scheduleAutoSave();
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
                            children: [
                              Expanded(
                                child: Text(
                                  AppFormatters.formatDate(_sioExpiryDate,
                                      fallback: 'Pilih Tanggal Masa Berlaku'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
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
            const FieldHelp(contentId: 'sio'),
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
            const Wrap(
              spacing: 8,
              children: [
                FieldHelp(contentId: 'clinic_npwp'),
                FieldHelp(contentId: 'fasyankes_code'),
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
              const FieldHelp(contentId: 'deed'),
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

  Widget _buildLocationMap() {
    final latitude = double.tryParse(_latCtrl.text);
    final longitude = double.tryParse(_lngCtrl.text);
    final hasLocation = latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    final center =
        hasLocation ? LatLng(latitude, longitude) : const LatLng(-2.5, 118);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: hasLocation ? 13 : 4,
            onTap: (_, point) {
              setState(() {
                _latCtrl.text = point.latitude.toStringAsFixed(6);
                _lngCtrl.text = point.longitude.toStringAsFixed(6);
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.prometheon.clinic',
            ),
            if (hasLocation)
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 40,
                    height: 48,
                    child: Builder(
                      builder: (mapContext) => GestureDetector(
                        onPanUpdate: (details) {
                          final camera = MapCamera.of(mapContext);
                          final markerOffset =
                              camera.latLngToScreenOffset(center);
                          final point = camera.screenOffsetToLatLng(
                            markerOffset + details.delta,
                          );
                          setState(() {
                            _latCtrl.text = point.latitude.toStringAsFixed(6);
                            _lngCtrl.text = point.longitude.toStringAsFixed(6);
                          });
                        },
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
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

              AppButton(
                'Mulai dari template',
                icon: Icons.auto_awesome_outlined,
                kind: BtnKind.secondary,
                onPressed: () => _showClinicTemplateDialog(
                  context,
                  clinicId,
                  clinicCtrl,
                  activeCats,
                ),
              ),
              const SizedBox(height: 20),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit ${f.name}',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showFacilityDialog(
                                    context,
                                    clinicId,
                                    facility: f,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus ${f.name}',
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      clinicCtrl.deleteFacility(f.id),
                                ),
                              ],
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit ${eq.name}',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showEquipmentDialog(
                                    context,
                                    clinicId,
                                    equipment: eq,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus ${eq.name}',
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      clinicCtrl.deleteEquipment(eq.id),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 24),

              // Medicines Catalog Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '4. Obat-obatan Tersedia (Opsional, ${clinicCtrl.medicines.length})',
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppButton(
                        'Impor CSV',
                        icon: Icons.file_upload,
                        kind: BtnKind.secondary,
                        onPressed: () => _importCsvDialog(context),
                      ),
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
                children: clinicCtrl.operatingHours
                    .map((hours) => _buildOperatingHoursEditor(
                          context,
                          clinicCtrl,
                          hours,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHoursEditor(
    BuildContext context,
    ClinicController clinicCtrl,
    ClinicOperatingHoursModel hours,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(hours.dayName,
                      style:
                          context.sBody.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(hours.isOpen ? 'Buka' : 'Tutup', style: context.sSmall),
                Switch(
                  value: hours.isOpen,
                  onChanged: (isOpen) => _setOperatingDayOpen(
                    context,
                    clinicCtrl,
                    hours,
                    isOpen,
                  ),
                ),
              ],
            ),
            if (hours.isOpen) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _operatingTimeButton(
                    context,
                    clinicCtrl,
                    hours,
                    _OperatingTimeField.open,
                    'Jam buka',
                    hours.openTime,
                  ),
                  _operatingTimeButton(
                    context,
                    clinicCtrl,
                    hours,
                    _OperatingTimeField.close,
                    'Jam tutup',
                    hours.closeTime,
                  ),
                  _operatingTimeButton(
                    context,
                    clinicCtrl,
                    hours,
                    _OperatingTimeField.breakStart,
                    'Istirahat mulai',
                    hours.breakStart,
                  ),
                  _operatingTimeButton(
                    context,
                    clinicCtrl,
                    hours,
                    _OperatingTimeField.breakEnd,
                    'Istirahat selesai',
                    hours.breakEnd,
                  ),
                  if (hours.breakStart != null)
                    TextButton(
                      onPressed: () => _clearOperatingBreak(
                        context,
                        clinicCtrl,
                        hours,
                        clearStart: true,
                      ),
                      child: const Text('Hapus jam mulai istirahat'),
                    ),
                  if (hours.breakEnd != null)
                    TextButton(
                      onPressed: () => _clearOperatingBreak(
                        context,
                        clinicCtrl,
                        hours,
                        clearEnd: true,
                      ),
                      child: const Text('Hapus jam selesai istirahat'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _operatingTimeButton(
    BuildContext context,
    ClinicController clinicCtrl,
    ClinicOperatingHoursModel hours,
    _OperatingTimeField field,
    String label,
    String? value,
  ) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.schedule, size: 18),
      label: Text(value == null ? label : '$label: ${_displayTime(value)}'),
      onPressed: () => _pickOperatingTime(
        context,
        clinicCtrl,
        hours,
        field,
        value,
      ),
    );
  }

  Future<void> _setOperatingDayOpen(
    BuildContext context,
    ClinicController clinicCtrl,
    ClinicOperatingHoursModel hours,
    bool isOpen,
  ) async {
    final updatedHour = hours.copyWith(
      isOpen: isOpen,
      openTime: isOpen ? hours.openTime ?? '08:00:00' : null,
      closeTime: isOpen ? hours.closeTime ?? '17:00:00' : null,
    );
    await _saveOperatingHour(context, clinicCtrl, updatedHour);
  }

  Future<void> _pickOperatingTime(
    BuildContext context,
    ClinicController clinicCtrl,
    ClinicOperatingHoursModel hours,
    _OperatingTimeField field,
    String? currentValue,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentValue, field),
      helpText: switch (field) {
        _OperatingTimeField.open => 'Pilih jam buka',
        _OperatingTimeField.close => 'Pilih jam tutup',
        _OperatingTimeField.breakStart => 'Pilih awal jam istirahat',
        _OperatingTimeField.breakEnd => 'Pilih akhir jam istirahat',
      },
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected == null || !context.mounted) return;

    final time = _databaseTime(selected);
    final updatedHour = switch (field) {
      _OperatingTimeField.open => hours.copyWith(openTime: time),
      _OperatingTimeField.close => hours.copyWith(closeTime: time),
      _OperatingTimeField.breakStart => hours.copyWith(breakStart: time),
      _OperatingTimeField.breakEnd => hours.copyWith(breakEnd: time),
    };

    if (updatedHour.isOpen &&
        (updatedHour.openTime == null ||
            updatedHour.closeTime == null ||
            !_isAfter(updatedHour.closeTime!, updatedHour.openTime!))) {
      _showOperatingHoursError(
        context,
        'Jam tutup harus lebih akhir daripada jam buka.',
      );
      return;
    }
    if (updatedHour.breakStart != null &&
        updatedHour.breakEnd != null &&
        !_isAfter(updatedHour.breakEnd!, updatedHour.breakStart!)) {
      _showOperatingHoursError(
        context,
        'Jam selesai istirahat harus lebih akhir daripada jam mulainya.',
      );
      return;
    }

    await _saveOperatingHour(context, clinicCtrl, updatedHour);
  }

  Future<void> _clearOperatingBreak(
    BuildContext context,
    ClinicController clinicCtrl,
    ClinicOperatingHoursModel hours, {
    bool clearStart = false,
    bool clearEnd = false,
  }) async {
    await _saveOperatingHour(
      context,
      clinicCtrl,
      hours.copyWith(
        clearBreakStart: clearStart,
        clearBreakEnd: clearEnd,
      ),
    );
  }

  Future<void> _saveOperatingHour(
    BuildContext context,
    ClinicController clinicCtrl,
    ClinicOperatingHoursModel updatedHour,
  ) async {
    if (updatedHour.isOpen &&
        (updatedHour.openTime == null ||
            updatedHour.closeTime == null ||
            !_isAfter(updatedHour.closeTime!, updatedHour.openTime!))) {
      _showOperatingHoursError(
        context,
        'Jam buka dan jam tutup wajib diisi; jam tutup harus lebih akhir.',
      );
      return;
    }
    if (updatedHour.breakStart != null &&
        updatedHour.breakEnd != null &&
        !_isAfter(updatedHour.breakEnd!, updatedHour.breakStart!)) {
      _showOperatingHoursError(
        context,
        'Jam selesai istirahat harus lebih akhir daripada jam mulainya.',
      );
      return;
    }

    final updatedHours = clinicCtrl.operatingHours
        .map((item) => item.id == updatedHour.id ? updatedHour : item)
        .toList();
    final success = await clinicCtrl.updateOperatingHours(updatedHours);
    if (!success && context.mounted) {
      _showOperatingHoursError(
        context,
        clinicCtrl.errorMessage ?? 'Jam operasional belum berhasil disimpan.',
      );
    }
  }

  void _showOperatingHoursError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  TimeOfDay _parseTime(String? value, _OperatingTimeField field) {
    final fallback = switch (field) {
      _OperatingTimeField.open => const TimeOfDay(hour: 8, minute: 0),
      _OperatingTimeField.close => const TimeOfDay(hour: 17, minute: 0),
      _OperatingTimeField.breakStart => const TimeOfDay(hour: 12, minute: 0),
      _OperatingTimeField.breakEnd => const TimeOfDay(hour: 13, minute: 0),
    };
    if (value == null) return fallback;
    final parts = value.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return fallback;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _databaseTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

  String _displayTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  bool _isAfter(String later, String earlier) =>
      _minutesSinceMidnight(later) > _minutesSinceMidnight(earlier);

  int _minutesSinceMidnight(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hour * 60 + minute;
  }

  void _showClinicTemplateDialog(
    BuildContext context,
    String clinicId,
    ClinicController clinicCtrl,
    List<String> currentServices,
  ) {
    var selectedTemplate = _clinicTemplates.first;
    var selectedServices = Set<String>.from(selectedTemplate.services);
    var selectedRooms = Set<String>.from(selectedTemplate.rooms);
    var selectedEquipment = Set<String>.from(selectedTemplate.equipment);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih template klinik'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Template hanya menambahkan data yang belum ada. Tinjau dan sesuaikan pilihan sebelum menerapkan.'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_ClinicTemplate>(
                    initialValue: selectedTemplate,
                    items: _clinicTemplates
                        .map((template) => DropdownMenuItem(
                              value: template,
                              child: Text(template.name),
                            ))
                        .toList(),
                    onChanged: (template) {
                      if (template == null) return;
                      setDialogState(() {
                        selectedTemplate = template;
                        selectedServices = Set<String>.from(template.services);
                        selectedRooms = Set<String>.from(template.rooms);
                        selectedEquipment =
                            Set<String>.from(template.equipment);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Jenis klinik',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Layanan', style: context.sStrong),
                  for (final service in selectedTemplate.services)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(service),
                      value: selectedServices.contains(service),
                      onChanged: (value) => setDialogState(() {
                        if (value == true) {
                          selectedServices.add(service);
                        } else {
                          selectedServices.remove(service);
                        }
                      }),
                    ),
                  Text('Ruangan', style: context.sStrong),
                  for (final room in selectedTemplate.rooms)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(room),
                      value: selectedRooms.contains(room),
                      onChanged: (value) => setDialogState(() {
                        if (value == true) {
                          selectedRooms.add(room);
                        } else {
                          selectedRooms.remove(room);
                        }
                      }),
                    ),
                  Text('Peralatan', style: context.sStrong),
                  for (final equipment in selectedTemplate.equipment)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(equipment),
                      value: selectedEquipment.contains(equipment),
                      onChanged: (value) => setDialogState(() {
                        if (value == true) {
                          selectedEquipment.add(equipment);
                        } else {
                          selectedEquipment.remove(equipment);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final services = {...currentServices, ...selectedServices};
                var saved = await clinicCtrl.toggleServiceCategories(
                  services.toList(),
                );
                if (!saved) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(clinicCtrl.errorMessage ??
                            'Layanan template belum berhasil disimpan.'),
                      ),
                    );
                  }
                  return;
                }

                final existingRooms = clinicCtrl.facilities
                    .map((facility) => facility.name.trim().toLowerCase())
                    .toSet();
                for (final room in selectedRooms) {
                  if (existingRooms.contains(room.trim().toLowerCase())) {
                    continue;
                  }
                  final kind = room == 'Ruang Tindakan'
                      ? FacilityKind.treatment_room
                      : FacilityKind.consultation_room;
                  saved = await clinicCtrl.saveFacility(
                    ClinicFacilityModel(
                      id: '',
                      clinicId: clinicId,
                      name: room,
                      kind: kind,
                      capacity: 1,
                    ),
                  );
                  if (!saved) break;
                  existingRooms.add(room.trim().toLowerCase());
                }

                final existingEquipment = clinicCtrl.equipment
                    .map((item) => item.name.trim().toLowerCase())
                    .toSet();
                if (saved) {
                  for (final equipment in selectedEquipment) {
                    if (existingEquipment
                        .contains(equipment.trim().toLowerCase())) {
                      continue;
                    }
                    saved = await clinicCtrl.saveEquipment(
                      ClinicEquipmentModel(
                        id: '',
                        clinicId: clinicId,
                        name: equipment,
                        category: EquipmentCategory.medical,
                      ),
                    );
                    if (!saved) break;
                    existingEquipment.add(equipment.trim().toLowerCase());
                  }
                }

                if (!dialogContext.mounted || !context.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(saved
                        ? 'Template diterapkan. Periksa kembali sebelum melanjutkan.'
                        : clinicCtrl.errorMessage ??
                            'Sebagian template belum berhasil disimpan.'),
                  ),
                );
              },
              child: const Text('Terapkan template'),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 3: ADMINISTRASI & LEGAL ---
  Widget _buildStep3AdministrasiLegal(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    final clinicId = clinicCtrl.clinicId ?? '';

    ClinicDocumentModel? requestLetterDoc;
    ClinicDocumentModel? qualityCommitmentDoc;
    ClinicDocumentModel? bpjsDoc;
    ClinicDocumentModel? serviceSopDoc;
    ClinicDocumentModel? clinicPhotoDoc;
    ClinicDocumentModel? educationPosterDoc;

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
      if (doc.docType == DocumentType.service_sop) serviceSopDoc = doc;
      if (doc.docType == DocumentType.clinic_photo) clinicPhotoDoc = doc;
      if (doc.docType == DocumentType.educational_poster) {
        educationPosterDoc = doc;
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
          const FieldHelp(contentId: 'registration_request'),
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
          const FieldHelp(contentId: 'quality_commitment'),
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
              children: clinicCtrl.orgStructure.map((org) {
                final linkedWorkers = clinicCtrl.healthWorkers
                    .where((worker) => worker.id == org.healthWorkerId)
                    .toList();
                final linkedWorker =
                    linkedWorkers.isEmpty ? null : linkedWorkers.first;
                return ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text('${org.position}: ${org.personName}'),
                  subtitle: Text(
                    'Urutan ${org.sortOrder}'
                    '${linkedWorker == null ? '' : ' • Tenaga kesehatan: ${linkedWorker.fullName}'}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Ubah jabatan',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showOrgStructureDialog(
                          context,
                          clinicId,
                          org,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus jabatan',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            clinicCtrl.deleteOrgStructureNode(org.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // BPJS Section
          Row(
            children: [
              Switch(
                value: _bpjsRegistered,
                onChanged: (v) {
                  setState(() => _bpjsRegistered = v);
                  _scheduleAutoSave();
                },
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
          const SizedBox(height: 24),
          Text('Dokumen tambahan (Opsional)',
              style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DocumentUploadTile(
            title: 'Unggah SOP layanan (Opsional)',
            subtitle: 'Panduan kerja klinik untuk menjalankan layanan.',
            clinicId: clinicId,
            docType: DocumentType.service_sop,
            existingClinicDoc: serviceSopDoc,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
          const FieldHelp(contentId: 'service_sop'),
          const SizedBox(height: 8),
          DocumentUploadTile(
            title: 'Unggah poster edukasi kesehatan (Opsional)',
            subtitle: 'Poster edukasi pasien di ruang tunggu.',
            clinicId: clinicId,
            docType: DocumentType.educational_poster,
            existingClinicDoc: educationPosterDoc,
            onChanged: () => clinicCtrl.refreshClinicDocuments(),
          ),
          if (clinicPhotoDoc != null) ...[
            const SizedBox(height: 16),
            Text('Dokumen lain', style: context.sBody),
            const SizedBox(height: 8),
            DocumentUploadTile(
              title: 'Foto fisik klinik lama',
              subtitle:
                  'Dokumen lama ini tidak lagi menjadi syarat pendaftaran.',
              clinicId: clinicId,
              docType: DocumentType.clinic_photo,
              existingClinicDoc: clinicPhotoDoc,
              allowUpload: false,
              onChanged: () => clinicCtrl.refreshClinicDocuments(),
            ),
          ],
        ],
      ),
    );
  }

  // --- STEP 4: REKAM MEDIS (RME) ---
  Widget _buildStep4SistemRme(BuildContext context) {
    final clinicCtrl = context.watch<ClinicController>();
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.showRmeSettings
                ? kEmrSectionLabel
                : 'Langkah 4: $kEmrSectionLabel · Opsional',
            style: context.sH2,
          ),
          Text(
            'Sampaikan sistem rekam medis yang digunakan klinik. Informasi ini tidak memengaruhi pengiriman pendaftaran.',
            style: context.sSmall,
          ),
          const SizedBox(height: 24),
          Text(
            'Sistem rekam medis apa yang dipakai klinik Anda?',
            style: context.sBody.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioGroup<EmrAppType>(
            groupValue: _selectedEmrType,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedEmrType = value);
              _scheduleAutoSave();
            },
            child: Column(
              children: [
                _emrChoiceCard(
                  EmrAppType.prometheon,
                  description: kPrometheonEmrDescription,
                ),
                _emrChoiceCard(EmrAppType.thirdParty),
                _emrChoiceCard(EmrAppType.internal),
                _emrChoiceCard(EmrAppType.none),
              ],
            ),
          ),
          if (_selectedEmrType == EmrAppType.none) ...[
            const SizedBox(height: 12),
            _informationBanner(
              'Fasilitas pelayanan kesehatan diwajibkan menyelenggarakan rekam medis elektronik (PMK 24/2022). Anda tetap dapat melanjutkan pendaftaran. Pastikan sesuai ketentuan yang berlaku.',
            ),
          ],
          if (_selectedEmrType == EmrAppType.thirdParty ||
              _selectedEmrType == EmrAppType.internal) ...[
            const SizedBox(height: 16),
            AppFormField(
              label: 'Nama aplikasi (opsional)',
              hint: 'Contoh: nama aplikasi rekam medis',
              controller: _emrAppNameCtrl,
            ),
          ],
          if (_selectedEmrType != EmrAppType.none) ...[
            const SizedBox(height: 16),
            AppFormField(
              label: 'ID organisasi SATUSEHAT (opsional)',
              hint: 'Masukkan ID organisasi jika sudah tersedia',
              controller: _satusehatOrgCtrl,
            ),
            const FieldHelp(contentId: 'satusehat_org'),
            const SizedBox(height: 12),
            _informationBanner(
              'Integrasi SATUSEHAT diaktifkan setelah klinik terverifikasi.',
            ),
          ],
          const SizedBox(height: 24),
          _satusehatIntegrationPanel(context, clinicCtrl),
        ],
      ),
    );
  }

  Widget _satusehatIntegrationPanel(
    BuildContext context,
    ClinicController clinicCtrl,
  ) {
    final status = clinicCtrl.clinic?.status;
    final canConnect =
        status == ClinicStatus.verified || status == ClinicStatus.under_review;
    final isConnected = clinicCtrl.emrSettings?.satusehatConnected ?? false;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Integrasi SATUSEHAT', style: context.sStrong),
          const SizedBox(height: 8),
          if (!canConnect)
            Text(
              'Tersedia setelah klinik terverifikasi.',
              style: context.sSmall,
            )
          else
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text(
                  isConnected ? 'Terhubung ✓' : 'Belum terhubung',
                  style: context.sBody,
                ),
                AppButton(
                  isConnected ? 'Ganti kode' : 'Hubungkan',
                  icon: Icons.vpn_key_outlined,
                  kind: BtnKind.secondary,
                  onPressed: () async {
                    final connected = await showDialog<bool>(
                      context: context,
                      builder: (_) => const SatusehatSecretDialog(),
                    );
                    if (connected == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SATUSEHAT berhasil dihubungkan.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _emrChoiceCard(EmrAppType type, {String? description}) {
    final selected = _selectedEmrType == type;
    final colors = context.c;
    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? colors.accent : colors.border),
      ),
      child: RadioListTile<EmrAppType>(
        value: type,
        title: Text(type.userLabel),
        subtitle: description == null ? null : Text(description),
      ),
    );
  }

  Widget _informationBanner(String text) {
    final colors = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.sBody)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Langkah 4: Penanggung Jawab & Tenaga Kesehatan',
                      style: context.sH2),
                  Text('Daftar dokter dan perawat aktif beserta STR & SIP.',
                      style: context.sSmall),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  'Tambah Tenaga Kesehatan',
                  icon: Icons.add,
                  kind: BtnKind.primary,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          HealthWorkerFormDialog(clinicId: clinicId),
                    ).then((_) => clinicCtrl.loadClinicData(clinicId));
                  },
                ),
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
    final recommendations = onboarding.recommendations
        .map(OnboardingRecommendation.fromKey)
        .whereType<OnboardingRecommendation>()
        .where((recommendation) =>
            recommendation.destination !=
            OnboardingRecommendationDestination.emrSettings)
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langkah 5: Tinjau Ringkasan & Kirim Pendaftaran',
              style: context.sH2),
          Text(
              'Periksa kelengkapan semua bagian sebelum mengirimkan pendaftaran ke tim verifikasi.',
              style: context.sSmall),
          const SizedBox(height: 24),
          _summarySectionTile(1, 'Data Dasar Klinik', onboarding.basicData),
          _summarySectionTile(
              1, 'Identitas Visual Publik', onboarding.publicMedia),
          _summarySectionTile(
              2, 'Layanan & Fasilitas Klinik', onboarding.servicesFacilities),
          _summarySectionTile(3, 'Administrasi & Legal', onboarding.adminLegal),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(kEmrSectionLabel, style: context.sBody),
              subtitle: const Text(
                'Prometheon Clinic OS · Dikelola otomatis',
              ),
              trailing: TextButton(
                onPressed: _openEmrSettings,
                child: const Text('Atur sekarang'),
              ),
            ),
          ),
          _summarySectionTile(5, 'Penanggung Jawab & Tenaga Kesehatan',
              onboarding.healthWorkers),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Saran sebelum mengirim', style: context.sH3),
            const SizedBox(height: 8),
            for (final recommendation in recommendations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.lightbulb_outline, color: context.c.muted),
                    title: Text(recommendation.label, style: context.sBody),
                    trailing: TextButton(
                      onPressed: () =>
                          _goToStep(recommendation.wizardStepIndex),
                      child: const Text('Buka'),
                    ),
                  ),
                ),
              ),
          ],
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
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(clinicCtrl.errorMessage ??
                              'Pendaftaran belum berhasil dikirim. Coba segarkan status dan periksa kembali data.'),
                          backgroundColor: Colors.red,
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
                onPressed: () => _goToStep(stepIdx),
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
                  onTap: () => _goToStep(ErrorMapper.keyToStepIndex(itemKey)),
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
  Future<void> _showFacilityDialog(
    BuildContext context,
    String clinicId, {
    ClinicFacilityModel? facility,
  }) async {
    final nameCtrl = TextEditingController(text: facility?.name ?? '');
    final capacityCtrl = TextEditingController(
      text: facility?.capacity?.toString() ?? (facility == null ? '1' : ''),
    );
    final notesCtrl = TextEditingController(text: facility?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    FacilityKind selectedKind =
        facility?.kind ?? FacilityKind.consultation_room;
    FacilityUnitStatus selectedStatus =
        facility?.status ?? FacilityUnitStatus.available;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(facility == null
              ? 'Tambah fasilitas atau ruangan'
              : 'Edit fasilitas atau ruangan'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppFormField(
                      label: 'Nama fasilitas atau ruangan',
                      hint: 'Ruang Periksa 1',
                      controller: nameCtrl,
                      validator: (value) => AppValidators.validateRequired(
                          value, 'Nama fasilitas'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FacilityKind>(
                      initialValue: selectedKind,
                      items: FacilityKind.values
                          .map((kind) => DropdownMenuItem(
                              value: kind, child: Text(kind.label)))
                          .toList(),
                      onChanged: (value) => setDialogState(() {
                        selectedKind = value ?? FacilityKind.consultation_room;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Jenis fasilitas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Kapasitas (orang)',
                      hint: '1',
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return AppValidators.validateNonNegativeInt(
                            value, 'Kapasitas');
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FacilityUnitStatus>(
                      initialValue: selectedStatus,
                      items: FacilityUnitStatus.values
                          .map((status) => DropdownMenuItem(
                              value: status, child: Text(status.label)))
                          .toList(),
                      onChanged: (value) => setDialogState(() {
                        selectedStatus = value ?? FacilityUnitStatus.available;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Status fasilitas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Catatan prasarana (opsional)',
                      hint: 'Contoh: akses kursi roda, dekat ruang tunggu',
                      controller: notesCtrl,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            AppButton(
              'Batal',
              kind: BtnKind.secondary,
              onPressed:
                  saving ? null : () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              facility == null ? 'Simpan' : 'Simpan Perubahan',
              icon: Icons.save_outlined,
              kind: BtnKind.primary,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      final controller = context.read<ClinicController>();
                      final success = await controller.saveFacility(
                        ClinicFacilityModel(
                          id: facility?.id ?? '',
                          clinicId: clinicId,
                          name: nameCtrl.text.trim(),
                          kind: selectedKind,
                          isRoom: facility?.isRoom ?? true,
                          capacity: capacityCtrl.text.trim().isEmpty
                              ? null
                              : int.parse(capacityCtrl.text.trim()),
                          status: selectedStatus,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(controller.errorMessage ??
                                'Fasilitas belum berhasil disimpan.'),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEquipmentDialog(
    BuildContext context,
    String clinicId, {
    ClinicEquipmentModel? equipment,
  }) async {
    final nameCtrl = TextEditingController(text: equipment?.name ?? '');
    final quantityCtrl = TextEditingController(
      text: equipment?.quantity.toString() ?? '1',
    );
    final notesCtrl = TextEditingController(text: equipment?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    EquipmentCategory category =
        equipment?.category ?? EquipmentCategory.medical;
    var selectedCondition = equipment?.condition ?? '';
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(equipment == null ? 'Tambah peralatan' : 'Edit peralatan'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppFormField(
                      label: 'Nama alat',
                      hint: 'Stetoskop atau timbangan digital',
                      controller: nameCtrl,
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'Nama alat'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EquipmentCategory>(
                      initialValue: category,
                      items: EquipmentCategory.values
                          .map((item) => DropdownMenuItem(
                              value: item, child: Text(item.label)))
                          .toList(),
                      onChanged: (value) => setDialogState(() {
                        category = value ?? EquipmentCategory.medical;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Kategori peralatan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Jumlah',
                      hint: '1',
                      controller: quantityCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');
                        if (number == null || number < 1) {
                          return 'Jumlah harus berupa bilangan bulat minimal 1.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCondition,
                      items: const [
                        DropdownMenuItem(
                          value: '',
                          child: Text('Pilih kondisi (opsional)'),
                        ),
                        DropdownMenuItem(
                          value: 'Baik',
                          child: Text('Baik'),
                        ),
                        DropdownMenuItem(
                          value: 'Perlu Kalibrasi',
                          child: Text('Perlu Kalibrasi'),
                        ),
                        DropdownMenuItem(
                          value: 'Rusak Ringan',
                          child: Text('Rusak Ringan'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedCondition = value ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'Kondisi (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Catatan spesifikasi atau merek (opsional)',
                      hint: 'Contoh: merek, tipe, atau nomor inventaris',
                      controller: notesCtrl,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            AppButton(
              'Batal',
              kind: BtnKind.secondary,
              onPressed:
                  saving ? null : () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              equipment == null ? 'Simpan' : 'Simpan Perubahan',
              icon: Icons.save_outlined,
              kind: BtnKind.primary,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      final controller = context.read<ClinicController>();
                      final success = await controller.saveEquipment(
                        ClinicEquipmentModel(
                          id: equipment?.id ?? '',
                          clinicId: clinicId,
                          name: nameCtrl.text.trim(),
                          category: category,
                          quantity: int.parse(quantityCtrl.text.trim()),
                          condition: selectedCondition.isEmpty
                              ? null
                              : selectedCondition,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(controller.errorMessage ??
                                'Peralatan belum berhasil disimpan.'),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMedicineDialog(
      BuildContext context, String clinicId) async {
    final nameCtrl = TextEditingController();
    final strengthCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedDosageForm = '';
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah obat'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppFormField(
                      label: 'Nama obat',
                      hint: 'Parasetamol',
                      controller: nameCtrl,
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'Nama obat'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDosageForm,
                      items: const [
                        DropdownMenuItem(
                          value: '',
                          child: Text('Pilih sediaan (opsional)'),
                        ),
                        DropdownMenuItem(
                          value: 'Tablet',
                          child: Text('Tablet'),
                        ),
                        DropdownMenuItem(
                          value: 'Sirup',
                          child: Text('Sirup'),
                        ),
                        DropdownMenuItem(
                          value: 'Injeksi',
                          child: Text('Injeksi'),
                        ),
                        DropdownMenuItem(
                          value: 'Kaplet',
                          child: Text('Kaplet'),
                        ),
                        DropdownMenuItem(
                          value: 'Salep',
                          child: Text('Salep'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(
                          () => selectedDosageForm = value ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'Bentuk sediaan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Kekuatan dosis',
                      hint: '500 mg atau 10 mg/5 ml',
                      controller: strengthCtrl,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            AppButton(
              'Batal',
              kind: BtnKind.secondary,
              onPressed:
                  saving ? null : () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              'Simpan',
              icon: Icons.save_outlined,
              kind: BtnKind.primary,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      final controller = context.read<ClinicController>();
                      final success = await controller.saveMedicine(
                        ClinicMedicineModel(
                          id: '',
                          clinicId: clinicId,
                          name: nameCtrl.text.trim(),
                          dosageForm: selectedDosageForm.isEmpty
                              ? null
                              : selectedDosageForm,
                          strength: strengthCtrl.text.trim().isEmpty
                              ? null
                              : strengthCtrl.text.trim(),
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(controller.errorMessage ??
                                'Obat belum berhasil disimpan.'),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
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

  Future<void> _showOrgStructureDialog(
    BuildContext context,
    String clinicId, [
    ClinicOrgStructureModel? initialNode,
  ]) async {
    final controller = context.read<ClinicController>();
    final personCtrl =
        TextEditingController(text: initialNode?.personName ?? '');
    final positionCtrl =
        TextEditingController(text: initialNode?.position ?? '');
    final sortOrderCtrl =
        TextEditingController(text: '${initialNode?.sortOrder ?? 0}');
    final formKey = GlobalKey<FormState>();
    var selectedHealthWorkerId = initialNode?.healthWorkerId ?? '';
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initialNode == null
              ? 'Tambah jabatan organisasi'
              : 'Ubah jabatan organisasi'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppFormField(
                      label: 'Nama pejabat',
                      hint: 'dr. Budi Santoso',
                      controller: personCtrl,
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'Nama pejabat'),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Jabatan atau posisi',
                      hint: 'Kepala Klinik atau Kepala Tata Usaha',
                      controller: positionCtrl,
                      validator: (value) => AppValidators.validateRequired(
                          value, 'Jabatan atau posisi'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedHealthWorkerId,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Tidak ditautkan'),
                        ),
                        ...controller.healthWorkers.map(
                          (worker) => DropdownMenuItem(
                            value: worker.id,
                            child: Text(
                              '${worker.fullName} • ${worker.workerType.label}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (workerId) {
                        setDialogState(() {
                          selectedHealthWorkerId = workerId ?? '';
                          if (selectedHealthWorkerId.isNotEmpty) {
                            final worker = controller.healthWorkers.firstWhere(
                                (item) => item.id == selectedHealthWorkerId);
                            personCtrl.text = worker.fullName;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tautkan tenaga kesehatan (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormField(
                      label: 'Urutan penampilan',
                      hint: '0',
                      controller: sortOrderCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          AppValidators.validateNonNegativeInt(
                              value, 'Urutan penampilan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            AppButton(
              'Batal',
              kind: BtnKind.secondary,
              onPressed:
                  saving ? null : () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              'Simpan',
              icon: Icons.save_outlined,
              kind: BtnKind.primary,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      final success = await controller.saveOrgStructureNode(
                        ClinicOrgStructureModel(
                          id: initialNode?.id ?? '',
                          clinicId: clinicId,
                          personName: personCtrl.text.trim(),
                          position: positionCtrl.text.trim(),
                          healthWorkerId: selectedHealthWorkerId.isEmpty
                              ? null
                              : selectedHealthWorkerId,
                          parentId: initialNode?.parentId,
                          sortOrder: int.parse(sortOrderCtrl.text.trim()),
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(controller.errorMessage ??
                                'Struktur organisasi belum berhasil disimpan.'),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
