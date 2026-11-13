import 'package:clinic_operations_platform/core/l10n/terms_id.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_document_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_emr_settings_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_equipment_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_facility_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_medicine_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_member_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_media_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_operating_hours_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_org_structure_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_service_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/health_worker_models.dart';
import 'package:clinic_operations_platform/features/clinic/models/onboarding_status_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/profile_model.dart';
import 'package:clinic_operations_platform/features/operations/models/clinic_operations_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RME labels use Indonesian terminology', () {
    expect(kEmrSectionLabel, 'Rekam Medis (RME)');
    expect(EmrAppType.prometheon.userLabel, 'Prometheon');
    expect(EmrAppType.thirdParty.userLabel, 'Aplikasi lain');
    expect(EmrAppType.internal.userLabel, 'Dikembangkan klinik sendiri');
    expect(EmrAppType.none.userLabel, 'Belum punya');
  });

  group('Domain Models Serialization Tests', () {
    test('ClinicModel json serialization', () {
      const model = ClinicModel(
        id: 'c1',
        ownerId: 'u1',
        status: ClinicStatus.draft,
        clinicName: 'Klinik Sehat Prometheon',
        legalEntityType: LegalEntityType.pt,
        phone: '+6281234567890',
        latitude: -6.200000,
        longitude: 106.816666,
      );

      final json = model.toJson();
      expect(json['id'], 'c1');
      expect(json['clinic_name'], 'Klinik Sehat Prometheon');
      expect(json['legal_entity_type'], 'pt');

      final reconstructed = ClinicModel.fromJson(json);
      expect(reconstructed.id, 'c1');
      expect(reconstructed.clinicName, 'Klinik Sehat Prometheon');
      expect(reconstructed.legalEntityType, LegalEntityType.pt);
      expect(reconstructed.status, ClinicStatus.draft);
    });

    test('ProfileModel & ClinicMemberModel json serialization', () {
      const profile = ProfileModel(
        id: 'u1',
        fullName: 'Dr. Elena Cruz',
        phone: '+628111222333',
        accountType: 'clinic',
      );
      final profileJson = profile.toJson();
      expect(profileJson['full_name'], 'Dr. Elena Cruz');
      final reconProfile = ProfileModel.fromJson(profileJson);
      expect(reconProfile.id, 'u1');
      expect(reconProfile.isClinicAccount, isTrue);

      const member = ClinicMemberModel(
        clinicId: 'c1',
        userId: 'u1',
        role: ClinicRole.owner,
      );
      final memberJson = member.toJson();
      expect(memberJson['role'], 'owner');
      final reconMember = ClinicMemberModel.fromJson(memberJson);
      expect(reconMember.role, ClinicRole.owner);
    });

    test('OnboardingStatusModel parses RPC response', () {
      final json = {
        'status': 'draft',
        'basic_data': {
          'complete': false,
          'missing': ['clinic_name', 'emr_app_name', 'doc:service_sop']
        },
        'services_facilities': {'complete': true, 'missing': []},
        'admin_legal': {'complete': true, 'missing': []},
        'emr_system': {
          'complete': false,
          'missing': ['doc:clinic_photo']
        },
        'health_workers': {'complete': true, 'missing': []},
        'ready_to_submit': false,
        'recommendations': ['emr_choice', 'media:gallery'],
      };

      final status = OnboardingStatusModel.fromJson(json);
      expect(status.status, ClinicStatus.draft);
      expect(status.basicData.complete, false);
      expect(status.basicData.missing, ['clinic_name']);
      expect(status.emrSystem.complete, isTrue);
      expect(status.emrSystem.missing, isEmpty);
      expect(status.recommendations, ['emr_choice', 'media:gallery']);
      expect(status.completedSectionsCount, 3);
      expect(status.completionProgress, 3 / 5.0);
      expect(status.readyToSubmit, false);

      final statusWithoutRecommendations = OnboardingStatusModel.fromJson({
        'status': 'draft',
      });
      expect(statusWithoutRecommendations.recommendations, isEmpty);
      expect(statusWithoutRecommendations.emrSystem.complete, isTrue);
    });

    test('RME status does not block readiness when five required sections pass',
        () {
      final status = OnboardingStatusModel.fromJson({
        'status': 'draft',
        'basic_data': {
          'complete': false,
          'missing': ['emr_app_name']
        },
        'services_facilities': {'complete': true, 'missing': []},
        'admin_legal': {'complete': true, 'missing': []},
        'emr_system': {
          'complete': false,
          'missing': ['emr_app_name', 'doc:service_sop']
        },
        'health_workers': {'complete': true, 'missing': []},
        'public_media': {'complete': true, 'missing': []},
        'ready_to_submit': false,
      });

      expect(status.emrSystem.complete, isTrue);
      expect(status.emrSystem.missing, isEmpty);
      expect(status.readyToSubmit, isTrue);
    });

    test('public media requires a non-rejected logo and cover', () {
      final status = OnboardingStatusModel.fromJson({
        'status': 'draft',
        'basic_data': {'complete': true, 'missing': []},
        'services_facilities': {'complete': true, 'missing': []},
        'admin_legal': {'complete': true, 'missing': []},
        'health_workers': {'complete': true, 'missing': []},
        'public_media': {'complete': false, 'missing': ['media:logo']},
      });

      final logoOnly = status.withPublicMediaRecords([
        const ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'c1',
          kind: MediaKind.logo,
          filePath: 'c1/logo/logo.jpg',
          reviewStatus: DocumentReviewStatus.pending,
        ),
        const ClinicMediaModel(
          id: 'gallery-1',
          clinicId: 'c1',
          kind: MediaKind.gallery,
          filePath: 'c1/gallery/gallery.jpg',
        ),
      ]);
      expect(logoOnly.publicMedia.complete, isFalse);
      expect(logoOnly.publicMedia.missing, ['media:cover']);
      expect(logoOnly.readyToSubmit, isFalse);

      final bothUploaded = status.withPublicMediaRecords([
        const ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'c1',
          kind: MediaKind.logo,
          filePath: 'c1/logo/logo.jpg',
          reviewStatus: DocumentReviewStatus.pending,
        ),
        const ClinicMediaModel(
          id: 'cover-1',
          clinicId: 'c1',
          kind: MediaKind.cover,
          filePath: 'c1/cover/cover.jpg',
          reviewStatus: DocumentReviewStatus.approved,
        ),
      ]);
      expect(bothUploaded.publicMedia.complete, isTrue);
      expect(bothUploaded.publicMedia.missing, isEmpty);
      expect(bothUploaded.readyToSubmit, isTrue);

      final rejectedLogo = bothUploaded.withPublicMediaRecords([
        const ClinicMediaModel(
          id: 'logo-1',
          clinicId: 'c1',
          kind: MediaKind.logo,
          filePath: 'c1/logo/logo.jpg',
          reviewStatus: DocumentReviewStatus.rejected,
        ),
        const ClinicMediaModel(
          id: 'cover-1',
          clinicId: 'c1',
          kind: MediaKind.cover,
          filePath: 'c1/cover/cover.jpg',
          reviewStatus: DocumentReviewStatus.pending,
        ),
      ]);
      expect(rejectedLogo.publicMedia.complete, isFalse);
      expect(rejectedLogo.publicMedia.missing, ['media:logo']);
      expect(rejectedLogo.readyToSubmit, isFalse);
    });

    test(
        'Catalog Models (Services, Facilities, Equipment, Medicines, Hours) serialization',
        () {
      const service = ClinicServiceModel(
        id: 's1',
        clinicId: 'c1',
        serviceType: 'Umum',
        description: 'Layanan konsultasi umum',
        isActive: true,
      );
      expect(ClinicServiceModel.fromJson(service.toJson()).serviceType, 'Umum');

      const facility = ClinicFacilityModel(
        id: 'f1',
        clinicId: 'c1',
        name: 'Ruang Periksa 1',
        kind: FacilityKind.consultation_room,
        status: FacilityUnitStatus.occupied,
        capacity: 0,
        notes: 'Dekat ruang tunggu',
      );
      final facilityRoundTrip = ClinicFacilityModel.fromJson(facility.toJson());
      expect(facilityRoundTrip.name, 'Ruang Periksa 1');
      expect(facilityRoundTrip.capacity, 0);
      expect(facilityRoundTrip.status, FacilityUnitStatus.occupied);
      expect(facilityRoundTrip.notes, 'Dekat ruang tunggu');

      const equipment = ClinicEquipmentModel(
        id: 'eq1',
        clinicId: 'c1',
        name: 'Stetoskop',
        category: EquipmentCategory.medical,
        quantity: 5,
        condition: 'Perlu Kalibrasi',
        notes: 'Merek contoh',
      );
      final equipmentRoundTrip =
          ClinicEquipmentModel.fromJson(equipment.toJson());
      expect(equipmentRoundTrip.quantity, 5);
      expect(equipmentRoundTrip.condition, 'Perlu Kalibrasi');
      expect(equipmentRoundTrip.notes, 'Merek contoh');

      const medicine = ClinicMedicineModel(
        id: 'm1',
        clinicId: 'c1',
        name: 'Paracetamol',
        dosageForm: 'Tablet',
        strength: '500 mg',
        isAvailable: true,
      );
      final medicineRoundTrip = ClinicMedicineModel.fromJson(medicine.toJson());
      expect(medicineRoundTrip.name, 'Paracetamol');
      expect(medicineRoundTrip.dosageForm, 'Tablet');
      expect(medicineRoundTrip.strength, '500 mg');

      const hours = ClinicOperatingHoursModel(
        id: 'h1',
        clinicId: 'c1',
        dayOfWeek: 1,
        isOpen: true,
        openTime: '08:00',
        closeTime: '17:00',
        breakStart: '12:00',
        breakEnd: '13:00',
      );
      final hoursJson = hours.toJson();
      expect(hoursJson['open_time'], '08:00:00');
      expect(hoursJson['close_time'], '17:00:00');
      expect(hoursJson['break_start'], '12:00:00');
      expect(hoursJson['break_end'], '13:00:00');
      final hoursRoundTrip = ClinicOperatingHoursModel.fromJson(hoursJson);
      expect(hoursRoundTrip.openTime, '08:00:00');
      expect(hoursRoundTrip.breakStart, '12:00:00');
      expect(hours.copyWith(clearBreakStart: true).breakStart, isNull);
    });

    test('OrgStructure, EmrSettings, and Documents serialization', () {
      const org = ClinicOrgStructureModel(
        id: 'o1',
        clinicId: 'c1',
        personName: 'Dr. Andi',
        position: 'Direktur Klinik',
        healthWorkerId: 'worker-1',
        sortOrder: 1,
      );
      final orgRoundTrip = ClinicOrgStructureModel.fromJson(org.toJson());
      expect(orgRoundTrip.position, 'Direktur Klinik');
      expect(orgRoundTrip.healthWorkerId, 'worker-1');
      expect(orgRoundTrip.sortOrder, 1);

      const emr = ClinicEmrSettingsModel(
        clinicId: 'c1',
        emrAppType: EmrAppType.prometheon,
        satusehatConnected: true,
        emrChoiceConfirmed: true,
      );
      final emrJson = emr.toJson();
      expect(emrJson['emr_app_type'], 'prometheon');
      expect(emrJson['emr_choice_confirmed'], isTrue);
      expect(emrJson.containsKey('satusehat_connected'), isFalse);
      expect(ClinicEmrSettingsModel.fromJson(emrJson).emrAppType,
          EmrAppType.prometheon);
      expect(EmrAppType.fromDb('third_party'), EmrAppType.thirdParty);
      expect(EmrAppType.thirdParty.dbValue, 'third_party');
      expect(EmrAppType.fromDb('unknown'), EmrAppType.none);

      const doc = ClinicDocumentModel(
        id: 'd1',
        clinicId: 'c1',
        docType: DocumentType.sio,
        filePath: 'c1/sio/file.pdf',
        fileName: 'sio.pdf',
        sizeBytes: 1024,
      );
      expect(
          ClinicDocumentModel.fromJson(doc.toJson()).docType, DocumentType.sio);
    });

    test('HealthWorkerModels serialization', () {
      const privateData = HealthWorkerPrivateModel(
        workerId: 'w1',
        clinicId: 'c1',
        phone: '+6281299990000',
        email: 'dr.andi@clinic.com',
        nik: '3171000022223333',
      );

      const worker = HealthWorkerModel(
        id: 'w1',
        clinicId: 'c1',
        fullName: 'Dr. Andi Pratama',
        workerType: HealthWorkerType.doctor,
        isPersonInCharge: true,
        privateData: privateData,
      );

      final json = worker.toJson();
      expect(json['full_name'], 'Dr. Andi Pratama');
      expect(json['worker_type'], 'doctor');
      expect(json['is_person_in_charge'], true);

      final recon = HealthWorkerModel.fromJson({
        ...json,
        'health_worker_private': privateData.toJson(),
      });
      expect(recon.fullName, 'Dr. Andi Pratama');
      expect(recon.privateData?.nik, '3171000022223333');

      final reconWithListRelation = HealthWorkerModel.fromJson({
        ...json,
        'health_worker_private': [privateData.toJson()],
      });
      expect(reconWithListRelation.privateData?.nik, '3171000022223333');

      final reconWithoutPrivateData = HealthWorkerModel.fromJson({
        ...json,
        'health_worker_private': <Map<String, dynamic>>[],
      });
      expect(reconWithoutPrivateData.privateData, isNull);
    });

    test('Operations Models serialization', () {
      const internalOps = ClinicOperationsInternalModel(
        clinicId: 'c1',
        clinicName: 'Prometheon Central Clinic',
        totalQueues: 10,
        currentQueueNumber: 3,
        queueProcessStatus: QueueProcessStatus.active,
        averageWaitTime: 15,
      );
      expect(
          ClinicOperationsInternalModel.fromJson(internalOps.toJson())
              .currentQueueNumber,
          3);

      const publicOps = ClinicOperationsPublicModel(
        clinicId: 'c1',
        clinicName: 'Prometheon Central Clinic',
        currentQueueNumber: 3,
        estimatedWaitTime: 15,
        clinicStatus: 'open',
      );
      expect(
          ClinicOperationsPublicModel.fromJson(publicOps.toJson())
              .estimatedWaitTime,
          15);
    });
  });
}
