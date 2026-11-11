import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_model.dart';

import 'package:clinic_operations_platform/features/clinic/models/onboarding_status_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Models Tests', () {
    test('ClinicModel json serialization', () {
      final model = ClinicModel(
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
      expect(status.completionProgress, 0.8);
      expect(status.readyToSubmit, false);
    });
  });
}
