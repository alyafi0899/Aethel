import 'package:clinic_operations_platform/core/utils/error_mapper.dart';
import 'package:clinic_operations_platform/core/utils/formatters.dart';
import 'package:clinic_operations_platform/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidators Tests', () {
    test('validateEmail handles valid and invalid emails', () {
      expect(AppValidators.validateEmail('admin@clinic.com'), isNull);
      expect(AppValidators.validateEmail('invalid-email'), isNotNull);
      expect(AppValidators.validateEmail(''), isNotNull);
    });

    test('normalizePhone formats Indonesian numbers correctly', () {
      expect(AppValidators.normalizePhone('081234567890'), '+6281234567890');
      expect(AppValidators.normalizePhone('+6281234567890'), '+6281234567890');
      expect(AppValidators.normalizePhone('6281234567890'), '+6281234567890');
    });

    test('validatePhone handles length and digit rules', () {
      expect(AppValidators.validatePhone('081234567890'), isNull);
      expect(AppValidators.validatePhone('123'), isNotNull);
      expect(AppValidators.validatePhone(''), isNotNull);
    });

    test('validatePassword requires 10 chars with letters and numbers', () {
      expect(AppValidators.validatePassword('Password123'), isNull);
      expect(AppValidators.validatePassword('pass123'), isNotNull); // <10 chars
      expect(AppValidators.validatePassword('12345678901'),
          isNotNull); // no letters
      expect(AppValidators.validatePassword('abcdefghijk'),
          isNotNull); // no numbers
    });

    test('validateNpwp and validateNik format checks', () {
      expect(AppValidators.validateNik('3171234567890001'), isNull);
      expect(AppValidators.validateNik('12345'), isNotNull);

      expect(AppValidators.validateNpwp('01.234.567.8-901.000'), isNull);
      expect(AppValidators.validateNpwp('123'), isNotNull);
    });
  });

  group('AppFormatters Tests', () {
    test('maskNik and maskNpwp masks properly', () {
      expect(AppFormatters.maskNik('3171234567890001'), '•••• •••• •••• 0001');
      expect(AppFormatters.maskNpwp('012345678901000'), '•••• •••• •••• 1000');
    });

    test('formatFileSize converts bytes correctly', () {
      expect(AppFormatters.formatFileSize(500), '500 B');
      expect(AppFormatters.formatFileSize(2048), '2.0 KB');
      expect(AppFormatters.formatFileSize(1048576 * 3), '3.0 MB');
    });
  });

  group('ErrorMapper Tests', () {
    test('technicalKeyToIndonesian maps onboarding keys', () {
      expect(
        ErrorMapper.technicalKeyToIndonesian('clinic_name'),
        contains('Nama Resmi Klinik'),
      );
      expect(
        ErrorMapper.technicalKeyToIndonesian('person_in_charge'),
        contains('Penanggung Jawab Klinik'),
      );
    });

    test('keyToStepIndex returns correct 1-based wizard step', () {
      expect(ErrorMapper.keyToStepIndex('clinic_name'), 1);
      expect(ErrorMapper.keyToStepIndex('services'), 2);
      expect(ErrorMapper.keyToStepIndex('org_structure'), 3);
      expect(ErrorMapper.keyToStepIndex('emr_app_name'), 4);
      expect(ErrorMapper.keyToStepIndex('person_in_charge'), 5);
    });
  });
}
