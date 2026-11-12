import 'package:clinic_operations_platform/features/clinic/models/clinic_document_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_emr_settings_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_equipment_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_facility_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_medicine_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_member_model.dart';
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
          'missing': ['clinic_name']
        },
        'services_facilities': {'complete': true, 'missing': []},
        'admin_legal': {'complete': true, 'missing': []},
        'emr_system': {'complete': true, 'missing': []},
        'health_workers': {'complete': true, 'missing': []},
        'ready_to_submit': false,
      };

      final status = OnboardingStatusModel.fromJson(json);
      expect(status.status, ClinicStatus.draft);
      expect(status.basicData.complete, false);
      expect(status.basicData.missing, ['clinic_name']);
      expect(status.completedSectionsCount, 4);
      expect(status.completionProgress, 4 / 6.0);
      expect(status.readyToSubmit, false);
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
        status: FacilityUnitStatus.available,
        capacity: 2,
      );
      expect(ClinicFacilityModel.fromJson(facility.toJson()).name,
          'Ruang Periksa 1');

      const equipment = ClinicEquipmentModel(
        id: 'eq1',
        clinicId: 'c1',
        name: 'Stetoskop',
        category: EquipmentCategory.medical,
        quantity: 5,
      );
      expect(ClinicEquipmentModel.fromJson(equipment.toJson()).quantity, 5);

      const medicine = ClinicMedicineModel(
        id: 'm1',
        clinicId: 'c1',
        name: 'Paracetamol',
        dosageForm: 'Tablet',
        strength: '500 mg',
        isAvailable: true,
      );
      expect(
          ClinicMedicineModel.fromJson(medicine.toJson()).name, 'Paracetamol');

      const hours = ClinicOperatingHoursModel(
        id: 'h1',
        clinicId: 'c1',
        dayOfWeek: 1,
        isOpen: true,
        openTime: '08:00',
        closeTime: '17:00',
      );
      expect(
          ClinicOperatingHoursModel.fromJson(hours.toJson()).openTime, '08:00');
    });

    test('OrgStructure, EmrSettings, and Documents serialization', () {
      const org = ClinicOrgStructureModel(
        id: 'o1',
        clinicId: 'c1',
        personName: 'Dr. Andi',
        position: 'Direktur Klinik',
        sortOrder: 1,
      );
      expect(ClinicOrgStructureModel.fromJson(org.toJson()).position,
          'Direktur Klinik');

      const emr = ClinicEmrSettingsModel(
        clinicId: 'c1',
        emrAppName: 'Prometheon RME',
        emrAppType: EmrAppType.internal,
        satusehatConnected: true,
      );
      expect(ClinicEmrSettingsModel.fromJson(emr.toJson()).emrAppName,
          'Prometheon RME');

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
