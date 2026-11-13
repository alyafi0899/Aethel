import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_mapper.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/models/clinic_operations_models.dart';
import '../data/clinic_catalog_repository.dart';
import '../data/clinic_profile_repository.dart';
import '../data/compliance_repository.dart';
import '../data/document_repository.dart';
import '../data/feedback_repository.dart';
import '../data/legal_consent_repository.dart';
import '../data/media_repository.dart';
import '../data/reviews_repository.dart';
import '../data/staff_repository.dart';
import '../models/clinic_document_model.dart';
import '../models/clinic_emr_settings_model.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_equipment_model.dart';
import '../models/clinic_facility_model.dart';
import '../models/clinic_media_model.dart';
import '../models/clinic_medicine_model.dart';
import '../models/clinic_model.dart';
import '../models/clinic_operating_hours_model.dart';
import '../models/clinic_org_structure_model.dart';
import '../models/clinic_service_model.dart';
import '../models/compliance_model.dart';
import '../models/feedback_model.dart';
import '../models/health_worker_models.dart';
import '../models/legal_consent_model.dart';
import '../models/onboarding_status_model.dart';
import '../models/review_models.dart';

class ClinicController extends ChangeNotifier {
  ClinicController({
    ClinicProfileRepository? profileRepo,
    ClinicCatalogRepository? catalogRepo,
    StaffRepository? staffRepo,
    DocumentRepository? documentRepo,
    OperationsRepository? operationsRepo,
    MediaRepository? mediaRepo,
    ComplianceRepository? complianceRepo,
    ReviewsRepository? reviewsRepo,
    FeedbackRepository? feedbackRepo,
    LegalConsentRepository? legalRepo,
  })  : _profileRepo = profileRepo ?? _defaultProfileRepo(),
        _catalogRepo = catalogRepo ?? _defaultCatalogRepo(),
        _staffRepo = staffRepo ?? _defaultStaffRepo(),
        _documentRepo = documentRepo ?? _defaultDocumentRepo(),
        _operationsRepo = operationsRepo ?? _defaultOperationsRepo(),
        _mediaRepo = mediaRepo ?? _defaultMediaRepo(),
        _complianceRepo = complianceRepo ?? _defaultComplianceRepo(),
        _reviewsRepo = reviewsRepo ?? _defaultReviewsRepo(),
        _feedbackRepo = feedbackRepo ?? _defaultFeedbackRepo(),
        _legalRepo = legalRepo ?? _defaultLegalRepo() {
    _startComplianceTimer();
  }

  static bool get _isSupabaseInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static ClinicProfileRepository _defaultProfileRepo() => _isSupabaseInitialized
      ? SupabaseClinicProfileRepository()
      : FakeClinicProfileRepository();
  static ClinicCatalogRepository _defaultCatalogRepo() => _isSupabaseInitialized
      ? SupabaseClinicCatalogRepository()
      : FakeClinicCatalogRepository();
  static StaffRepository _defaultStaffRepo() => _isSupabaseInitialized
      ? SupabaseStaffRepository()
      : FakeStaffRepository();
  static DocumentRepository _defaultDocumentRepo() => _isSupabaseInitialized
      ? SupabaseDocumentRepository()
      : FakeDocumentRepository();
  static OperationsRepository _defaultOperationsRepo() => _isSupabaseInitialized
      ? SupabaseOperationsRepository()
      : FakeOperationsRepository();
  static MediaRepository _defaultMediaRepo() => _isSupabaseInitialized
      ? SupabaseMediaRepository()
      : FakeMediaRepository();
  static ComplianceRepository _defaultComplianceRepo() => _isSupabaseInitialized
      ? SupabaseComplianceRepository()
      : FakeComplianceRepository();
  static ReviewsRepository _defaultReviewsRepo() => _isSupabaseInitialized
      ? SupabaseReviewsRepository()
      : FakeReviewsRepository();
  static FeedbackRepository _defaultFeedbackRepo() => _isSupabaseInitialized
      ? SupabaseFeedbackRepository()
      : FakeFeedbackRepository();
  static LegalConsentRepository _defaultLegalRepo() => _isSupabaseInitialized
      ? SupabaseLegalConsentRepository()
      : FakeLegalConsentRepository();

  final ClinicProfileRepository _profileRepo;
  final ClinicCatalogRepository _catalogRepo;
  final StaffRepository _staffRepo;
  final DocumentRepository _documentRepo;
  final OperationsRepository _operationsRepo;
  final MediaRepository _mediaRepo;
  final ComplianceRepository _complianceRepo;
  final ReviewsRepository _reviewsRepo;
  final FeedbackRepository _feedbackRepo;
  final LegalConsentRepository _legalRepo;

  Timer? _complianceTimer;

  bool _loading = false;
  String? _errorMessage;

  ClinicModel? _clinic;
  OnboardingStatusModel _onboardingStatus = const OnboardingStatusModel(
    status: ClinicStatus.draft,
  );
  ClinicEmrSettingsModel? _emrSettings;
  String? _emrInitializationError;
  List<ClinicServiceModel> _services = [];
  List<ClinicFacilityModel> _facilities = [];
  List<ClinicEquipmentModel> _equipment = [];
  List<ClinicMedicineModel> _medicines = [];
  List<ClinicOperatingHoursModel> _operatingHours = [];
  List<ClinicOrgStructureModel> _orgStructure = [];
  List<HealthWorkerModel> _healthWorkers = [];
  List<ClinicDocumentModel> _clinicDocuments = [];
  List<ClinicMediaModel> _mediaList = [];
  ComplianceStatusModel _complianceStatus = const ComplianceStatusModel();
  ClinicReviewStatsModel _reviewStats = const ClinicReviewStatsModel();
  List<ClinicReviewManageModel> _reviews = [];
  List<ClinicFeedbackPrivateModel> _feedbackList = [];
  List<LegalConsentModel> _userConsents = [];

  ClinicOperationsInternalModel? _internalOperations;
  ClinicOperationsPublicModel? _publicPreview;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  ClinicModel? get clinic => _clinic;
  OnboardingStatusModel get onboardingStatus => _onboardingStatus;
  ClinicEmrSettingsModel? get emrSettings => _emrSettings;
  String? get emrInitializationError => _emrInitializationError;
  List<ClinicServiceModel> get services => _services;
  List<ClinicFacilityModel> get facilities => _facilities;
  List<ClinicEquipmentModel> get equipment => _equipment;
  List<ClinicMedicineModel> get medicines => _medicines;
  List<ClinicOperatingHoursModel> get operatingHours => _operatingHours;
  List<ClinicOrgStructureModel> get orgStructure => _orgStructure;
  List<HealthWorkerModel> get healthWorkers => _healthWorkers;
  List<ClinicDocumentModel> get clinicDocuments => _clinicDocuments;
  List<ClinicMediaModel> get mediaList => _mediaList;
  ComplianceStatusModel get complianceStatus => _complianceStatus;
  ClinicReviewStatsModel get reviewStats => _reviewStats;
  List<ClinicReviewManageModel> get reviews => _reviews;
  List<ClinicFeedbackPrivateModel> get feedbackList => _feedbackList;
  List<LegalConsentModel> get userConsents => _userConsents;

  ClinicOperationsInternalModel? get internalOperations => _internalOperations;
  ClinicOperationsPublicModel? get publicPreview => _publicPreview;

  String? get clinicId => _clinic?.id;

  int get unreadFeedbackCount =>
      _feedbackList.where((f) => f.status == FeedbackStatus.newStatus).length;
  int get openAlertsCount => _complianceStatus.alerts.length;

  void _startComplianceTimer() {
    _complianceTimer?.cancel();
    if (_isSupabaseInitialized) {
      _complianceTimer = Timer.periodic(const Duration(hours: 6), (_) {
        refreshCompliance();
      });
    }
  }

  Future<void> loadClinicForUser(String userId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedClinic = await _profileRepo.fetchClinicByOwnerId(userId);
      if (fetchedClinic != null) {
        await loadClinicData(fetchedClinic.id);
        await loadUserConsents(userId);
      } else {
        _clinic = null;
      }
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadClinicData(String id) async {
    _loading = true;
    _errorMessage = null;
    _emrInitializationError = null;
    notifyListeners();

    try {
      _clinic = await _profileRepo.fetchClinicById(id);
      _emrSettings = null;
      try {
        _emrSettings = await _profileRepo.fetchEmrSettings(id);
        await ensurePrometheonEmrSettings();
      } catch (error) {
        _emrInitializationError = ErrorMapper.mapError(error);
      }
      _onboardingStatus = await _profileRepo.getOnboardingStatus(id);
      _services = await _catalogRepo.fetchServices(id);
      _facilities = await _catalogRepo.fetchFacilities(id);
      _equipment = await _catalogRepo.fetchEquipment(id);
      _medicines = await _catalogRepo.fetchMedicines(id);
      _operatingHours = await _catalogRepo.fetchOperatingHours(id);
      _orgStructure = await _profileRepo.fetchOrgStructure(id);
      _healthWorkers = await _staffRepo.fetchHealthWorkers(id);
      _clinicDocuments = await _documentRepo.fetchClinicDocuments(id);
      _mediaList = await _mediaRepo.fetchMedia(id);
      _onboardingStatus =
          _onboardingStatus.withPublicMediaRecords(_mediaList);

      await refreshCompliance();

      try {
        _reviewStats = await _reviewsRepo.fetchReviewStats(id);
        _reviews = await _reviewsRepo.fetchReviewsManage(clinicId: id);
        _feedbackList = await _feedbackRepo.fetchPrivateFeedback(clinicId: id);
        _internalOperations = await _operationsRepo.fetchInternalOperations(id);
        _publicPreview = await _operationsRepo.fetchPublicPreview(id);
      } catch (_) {}
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> ensurePrometheonEmrSettings() async {
    final currentClinicId = clinicId;
    if (currentClinicId == null) {
      _emrInitializationError = 'Data klinik belum tersedia.';
      notifyListeners();
      return false;
    }

    try {
      final settings =
          _emrSettings ?? await _profileRepo.fetchEmrSettings(currentClinicId);
      _emrSettings = settings;
      if (settings.emrAppType == EmrAppType.internal &&
          settings.emrAppName == kPrometheonEmrAppName &&
          settings.emrChoiceConfirmed) {
        _emrInitializationError = null;
        return true;
      }

      _emrSettings = await _profileRepo.updateEmrSettings(
        settings.copyWith(
          clinicId: currentClinicId,
          emrAppType: EmrAppType.internal,
          emrAppName: kPrometheonEmrAppName,
          emrChoiceConfirmed: true,
        ),
      );
      _emrInitializationError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _emrInitializationError = ErrorMapper.mapError(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCompliance() async {
    if (clinicId == null) return;
    try {
      _complianceStatus =
          await _complianceRepo.fetchComplianceStatus(clinicId!);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadUserConsents(String userId) async {
    try {
      _userConsents = await _legalRepo.fetchUserConsents(userId);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> recordLegalConsents(String userId) async {
    try {
      await _legalRepo.recordConsents(userId: userId, version: kLegalVersion);
      await loadUserConsents(userId);
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshMedia() async {
    if (clinicId == null) return false;
    try {
      _mediaList = await _mediaRepo.fetchMedia(clinicId!);
      final statusRefreshed = await refreshOnboardingStatus();
      notifyListeners();
      return statusRefreshed;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshReviews() async {
    if (clinicId == null) return false;
    try {
      _reviewStats = await _reviewsRepo.fetchReviewStats(clinicId!);
      _reviews = await _reviewsRepo.fetchReviewsManage(clinicId: clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> replyToReview(
      {required String reviewId, required String body}) async {
    if (clinicId == null) return false;
    try {
      await _reviewsRepo.replyToReview(
          reviewId: reviewId, clinicId: clinicId!, body: body);
      await refreshReviews();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportReview({
    required String reviewId,
    required ReportReason reason,
    String? details,
  }) async {
    if (clinicId == null) return false;
    try {
      await _reviewsRepo.reportReview(
        reviewId: reviewId,
        clinicId: clinicId!,
        reason: reason,
        details: details,
      );
      await refreshReviews();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshFeedback() async {
    if (clinicId == null) return false;
    try {
      _feedbackList =
          await _feedbackRepo.fetchPrivateFeedback(clinicId: clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFeedbackStatus({
    required String feedbackId,
    required FeedbackStatus status,
    String? internalNote,
  }) async {
    if (clinicId == null) return false;
    try {
      await _feedbackRepo.updateFeedbackStatusAndNote(
        feedbackId: feedbackId,
        clinicId: clinicId!,
        status: status,
        internalNote: internalNote,
      );
      await refreshFeedback();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshOnboardingStatus() async {
    if (clinicId == null) return false;
    try {
      final status = await _profileRepo.getOnboardingStatus(clinicId!);
      _onboardingStatus = status.withPublicMediaRecords(_mediaList);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = ErrorMapper.mapError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBasicData(ClinicModel updated) async {
    if (clinicId == null) return false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clinic = await _profileRepo.updateClinicBasicData(updated);
      await refreshOnboardingStatus();
      await refreshCompliance();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleServiceCategories(List<String> activeCategories) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.toggleServiceCategories(clinicId!, activeCategories);
      _services = await _catalogRepo.fetchServices(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveFacility(ClinicFacilityModel facility) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.saveFacility(facility.copyWith(clinicId: clinicId));
      _facilities = await _catalogRepo.fetchFacilities(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFacility(String id) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.deleteFacility(id);
      _facilities = await _catalogRepo.fetchFacilities(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveEquipment(ClinicEquipmentModel equipmentItem) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo
          .saveEquipment(equipmentItem.copyWith(clinicId: clinicId));
      _equipment = await _catalogRepo.fetchEquipment(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEquipment(String id) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.deleteEquipment(id);
      _equipment = await _catalogRepo.fetchEquipment(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveMedicine(ClinicMedicineModel medicine) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.saveMedicine(medicine.copyWith(clinicId: clinicId));
      _medicines = await _catalogRepo.fetchMedicines(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.deleteMedicine(id);
      _medicines = await _catalogRepo.fetchMedicines(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> importMedicinesFromCsv(String csvContent) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.importMedicinesFromCsv(clinicId!, csvContent);
      _medicines = await _catalogRepo.fetchMedicines(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOperatingHours(
      List<ClinicOperatingHoursModel> hours) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.updateOperatingHours(hours);
      _operatingHours = await _catalogRepo.fetchOperatingHours(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> copyHoursToWeekdays(ClinicOperatingHoursModel source) async {
    if (clinicId == null) return false;
    try {
      await _catalogRepo.copyHoursToWeekdays(clinicId!, source);
      _operatingHours = await _catalogRepo.fetchOperatingHours(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveOrgStructureNode(ClinicOrgStructureModel node) async {
    if (clinicId == null) return false;
    try {
      await _profileRepo
          .saveOrgStructureNode(node.copyWith(clinicId: clinicId));
      _orgStructure = await _profileRepo.fetchOrgStructure(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrgStructureNode(String id) async {
    if (clinicId == null) return false;
    try {
      await _profileRepo.deleteOrgStructureNode(id);
      _orgStructure = await _profileRepo.fetchOrgStructure(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmrSettings(ClinicEmrSettingsModel settings) async {
    if (clinicId == null) return false;
    try {
      _emrSettings = await _profileRepo
          .updateEmrSettings(settings.copyWith(clinicId: clinicId));
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSatusehatSecret(String secret) async {
    if (clinicId == null) return false;
    try {
      await _profileRepo.saveIntegrationSecret(
        clinicId: clinicId!,
        provider: 'satusehat',
        secret: secret,
      );
      _emrSettings = await _profileRepo.fetchEmrSettings(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      var safeMessage = ErrorMapper.mapError(e);
      if (secret.isNotEmpty) {
        safeMessage = safeMessage.replaceAll(secret, '[kode disamarkan]');
        final encodedSecret = Uri.encodeComponent(secret);
        if (encodedSecret != secret) {
          safeMessage =
              safeMessage.replaceAll(encodedSecret, '[kode disamarkan]');
        }
      }
      _errorMessage = safeMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveHealthWorker({
    required HealthWorkerModel worker,
    HealthWorkerPrivateModel? privateData,
  }) async {
    if (clinicId == null) return false;
    try {
      await _staffRepo.saveHealthWorker(
        worker: worker.copyWith(clinicId: clinicId),
        privateData: privateData,
      );
      _healthWorkers = await _staffRepo.fetchHealthWorkers(clinicId!);
      await refreshOnboardingStatus();
      await refreshCompliance();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHealthWorkerDutyStatus(
      String workerId, DutyStatus status) async {
    if (clinicId == null) return false;
    try {
      await _staffRepo.updateDutyStatus(
        workerId: workerId,
        clinicId: clinicId!,
        status: status,
      );
      _healthWorkers = await _staffRepo.fetchHealthWorkers(clinicId!);
      await refreshOperations();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleHealthWorkerActive(String workerId, bool isActive) async {
    if (clinicId == null) return false;
    try {
      await _staffRepo.toggleActiveStatus(
        workerId: workerId,
        clinicId: clinicId!,
        isActive: isActive,
      );
      _healthWorkers = await _staffRepo.fetchHealthWorkers(clinicId!);
      await refreshOnboardingStatus();
      await refreshCompliance();
      await refreshOperations();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshClinicDocuments() async {
    if (clinicId == null) return false;
    try {
      _clinicDocuments = await _documentRepo.fetchClinicDocuments(clinicId!);
      await refreshOnboardingStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshHomeTaskData() async {
    if (clinicId == null) return false;
    final id = clinicId!;
    final results = await Future.wait<bool>([
      _loadHomeTaskSource(() async {
        _clinicDocuments = await _documentRepo.fetchClinicDocuments(id);
      }),
      _loadHomeTaskSource(() async {
        _mediaList = await _mediaRepo.fetchMedia(id);
      }),
      _loadHomeTaskSource(() async {
        _healthWorkers = await _staffRepo.fetchHealthWorkers(id);
      }),
      _loadHomeTaskSource(() async {
        _complianceStatus = await _complianceRepo.fetchComplianceStatus(id);
      }),
      _loadHomeTaskSource(() async {
        _reviewStats = await _reviewsRepo.fetchReviewStats(id);
        _reviews = await _reviewsRepo.fetchReviewsManage(clinicId: id);
      }),
      _loadHomeTaskSource(() async {
        _feedbackList = await _feedbackRepo.fetchPrivateFeedback(clinicId: id);
      }),
      _loadHomeTaskSource(() async {
        _internalOperations = await _operationsRepo.fetchInternalOperations(id);
        _publicPreview = await _operationsRepo.fetchPublicPreview(id);
      }),
    ]);
    notifyListeners();
    return results.every((success) => success);
  }

  Future<bool> _loadHomeTaskSource(Future<void> Function() load) async {
    try {
      await load();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      return false;
    }
  }

  Future<bool> submitClinicForReview() async {
    if (clinicId == null) return false;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mediaList = await _mediaRepo.fetchMedia(clinicId!);
      final latestStatus = await _profileRepo.getOnboardingStatus(clinicId!);
      _onboardingStatus =
          latestStatus.withPublicMediaRecords(_mediaList);
      if (!_onboardingStatus.readyToSubmit) {
        final missing = _onboardingStatus.requiredMissingItems
            .map(ErrorMapper.technicalKeyToIndonesian)
            .toSet();
        _errorMessage = missing.isEmpty
            ? 'Data onboarding belum lengkap. Periksa kembali setiap bagian.'
            : 'Data belum lengkap:\n• ${missing.join('\n• ')}';
        _loading = false;
        notifyListeners();
        return false;
      }

      _onboardingStatus = await _profileRepo.submitClinicForReview(clinicId!);
      _onboardingStatus =
          _onboardingStatus.withPublicMediaRecords(_mediaList);
      _clinic = await _profileRepo.fetchClinicById(clinicId!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setClinicPublished(bool published) async {
    if (clinicId == null) return false;
    try {
      await _profileRepo.setClinicPublished(
        clinicId: clinicId!,
        published: published,
      );
      _clinic = await _profileRepo.fetchClinicById(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshOperations() async {
    if (clinicId == null) return false;
    try {
      await _operationsRepo.refreshClinicOperations(clinicId!);
      _internalOperations =
          await _operationsRepo.fetchInternalOperations(clinicId!);
      _publicPreview = await _operationsRepo.fetchPublicPreview(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInternalOperations(
      ClinicOperationsInternalModel ops) async {
    if (clinicId == null) return false;
    try {
      _internalOperations = await _operationsRepo.updateInternalOperations(
        ops.copyWith(clinicId: clinicId),
      );
      _publicPreview = await _operationsRepo.fetchPublicPreview(clinicId!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _complianceTimer?.cancel();
    super.dispose();
  }
}
