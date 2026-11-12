import 'package:clinic_operations_platform/core/utils/error_mapper.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_media_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/compliance_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/feedback_model.dart';
import 'package:clinic_operations_platform/features/clinic/models/review_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase B Domain Models & Mapper Tests', () {
    test('ComplianceStatusModel parses JSON correctly', () {
      final json = {
        'sio_expiry': '2026-11-20',
        'sio_days_left': 10,
        'sio_valid': true,
        'publicly_visible': true,
        'alerts': [
          {
            'id': 'a1',
            'type': 'sio_expiring',
            'severity': 'warning',
            'message': 'SIO klinik akan kedaluwarsa',
            'due_date': '2026-11-20',
            'ref_id': 'c1',
          }
        ],
      };

      final status = ComplianceStatusModel.fromJson(json);
      expect(status.sioValid, true);
      expect(status.publiclyVisible, true);
      expect(status.alerts.length, 1);
      expect(status.alerts.first.severity, AlertSeverity.warning);
      expect(status.hasWarningAlerts, true);
    });

    test('ClinicReviewStatsModel parses JSON correctly', () {
      final json = {
        'count': 10,
        'average': 4.8,
        'distribution': {'1': 0, '2': 0, '3': 1, '4': 1, '5': 8},
        'last_30_days': 5,
        'replied': 8,
        'response_rate': 80.0,
        'unanswered': 2,
      };

      final stats = ClinicReviewStatsModel.fromJson(json);
      expect(stats.count, 10);
      expect(stats.average, 4.8);
      expect(stats.responseRate, 80.0);
      expect(stats.distribution['5'], 8);
    });

    test('ClinicFeedbackPrivateModel json round-trip', () {
      const feedback = ClinicFeedbackPrivateModel(
        id: 'f1',
        clinicId: 'c1',
        encounterId: 'e1',
        category: FeedbackCategory.facility,
        message: 'AC di ruang tunggu mohon diperbaiki',
        status: FeedbackStatus.newStatus,
      );

      final json = feedback.toJson();
      expect(json['id'], 'f1');
      expect(json['category'], 'facility');
      expect(json['status'], 'new');

      final reconstructed = ClinicFeedbackPrivateModel.fromJson(json);
      expect(reconstructed.id, 'f1');
      expect(reconstructed.message, 'AC di ruang tunggu mohon diperbaiki');
    });

    test('ClinicMediaModel json round-trip', () {
      const media = ClinicMediaModel(
        id: 'm1',
        clinicId: 'c1',
        kind: MediaKind.logo,
        filePath: 'c1/logo/logo.png',
        fileName: 'logo.png',
        sizeBytes: 1024,
      );

      final json = media.toJson();
      expect(json['id'], 'm1');
      expect(json['kind'], 'logo');

      final reconstructed = ClinicMediaModel.fromJson(json);
      expect(reconstructed.kind, MediaKind.logo);
      expect(reconstructed.filePath, 'c1/logo/logo.png');
    });

    test('ErrorMapper maps new Phase B keys correctly', () {
      expect(
        ErrorMapper.technicalKeyToIndonesian('media:logo'),
        contains('Logo Klinik'),
      );
      expect(
        ErrorMapper.technicalKeyToIndonesian('doctor_profile_photo'),
        contains('Pasfoto Dokter'),
      );

      expect(ErrorMapper.keyToStepIndex('media:logo'), 1);
      expect(ErrorMapper.keyToStepIndex('doctor_profile_photo'), 5);
    });
  });
}
