import 'package:clinic_operations_platform/core/utils/formatters.dart';
import 'package:clinic_operations_platform/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidators Tests', () {
    test('validateEmail handles valid and invalid emails', () {
      expect(AppValidators.validateEmail('admin@clinic.com'), isNull);
      expect(AppValidators.validateEmail('user.name+tag@domain.co.id'), isNull);
      expect(AppValidators.validateEmail('invalid-email'), isNotNull);
      expect(AppValidators.validateEmail('admin@'), isNotNull);
      expect(AppValidators.validateEmail(''), isNotNull);
      expect(AppValidators.validateEmail(null), isNotNull);
    });

    test('normalizePhone formats Indonesian numbers correctly', () {
      expect(AppValidators.normalizePhone('081234567890'), '+6281234567890');
      expect(AppValidators.normalizePhone('+6281234567890'), '+6281234567890');
      expect(AppValidators.normalizePhone('6281234567890'), '+6281234567890');
      expect(AppValidators.normalizePhone('0812-3456-7890'), '+6281234567890');
    });

    test('validatePhone handles length and digit rules', () {
      expect(AppValidators.validatePhone('081234567890'), isNull);
      expect(AppValidators.validatePhone('+62812345678'), isNull);
      expect(AppValidators.validatePhone('123'), isNotNull);
      expect(AppValidators.validatePhone(''), isNotNull);
      expect(AppValidators.validatePhone(null), isNotNull);
    });

    test('validatePassword requires 10 chars with letters and numbers', () {
      expect(AppValidators.validatePassword('Password123'), isNull);
      expect(AppValidators.validatePassword('SecurePass99'), isNull);
      expect(AppValidators.validatePassword('pass123'), isNotNull); // <10 chars
      expect(AppValidators.validatePassword('12345678901'),
          isNotNull); // no letters
      expect(AppValidators.validatePassword('abcdefghijk'),
          isNotNull); // no numbers
      expect(AppValidators.validatePassword(null), isNotNull);
    });

    test('validateConfirmPassword checks equality', () {
      expect(AppValidators.validateConfirmPassword('Pass123456', 'Pass123456'),
          isNull);
      expect(AppValidators.validateConfirmPassword('Pass123456', 'Different'),
          isNotNull);
      expect(
          AppValidators.validateConfirmPassword('', 'Pass123456'), isNotNull);
      expect(
          AppValidators.validateConfirmPassword(null, 'Pass123456'), isNotNull);
    });

    test('validateNpwp and validateNik format checks', () {
      expect(AppValidators.validateNik('3171234567890001'), isNull);
      expect(AppValidators.validateNik('12345'), isNotNull);
      expect(AppValidators.validateNik(null, required: true), isNotNull);
      expect(AppValidators.validateNik(null, required: false), isNull);

      expect(AppValidators.validateNpwp('01.234.567.8-901.000'), isNull);
      expect(AppValidators.validateNpwp('012345678901000'), isNull);
      expect(AppValidators.validateNpwp('123'), isNotNull);
      expect(AppValidators.validateNpwp(null, required: false), isNull);
      expect(AppValidators.validateNpwp(null, required: true), isNotNull);
    });

    test('validateRequired validates non-empty strings', () {
      expect(AppValidators.validateRequired('Klinik Sehat', 'Nama'), isNull);
      expect(AppValidators.validateRequired('', 'Nama'), isNotNull);
      expect(AppValidators.validateRequired('   ', 'Nama'), isNotNull);
      expect(AppValidators.validateRequired(null, 'Nama'), isNotNull);
    });

    test('validateSioExpiry requires date in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final pastDate = DateTime.now().subtract(const Duration(days: 10));

      expect(AppValidators.validateSioExpiry(futureDate), isNull);
      expect(AppValidators.validateSioExpiry(pastDate), isNotNull);
      expect(AppValidators.validateSioExpiry(null), isNotNull);
    });

    test('validateLatitude and validateLongitude boundary checks', () {
      expect(AppValidators.validateLatitude(-6.200000), isNull);
      expect(AppValidators.validateLatitude(90.0), isNull);
      expect(AppValidators.validateLatitude(-90.0), isNull);
      expect(AppValidators.validateLatitude(-95.0), isNotNull);
      expect(AppValidators.validateLatitude(91.0), isNotNull);
      expect(AppValidators.validateLatitude(null), isNotNull);

      expect(AppValidators.validateLongitude(106.816666), isNull);
      expect(AppValidators.validateLongitude(180.0), isNull);
      expect(AppValidators.validateLongitude(-180.0), isNull);
      expect(AppValidators.validateLongitude(181.0), isNotNull);
      expect(AppValidators.validateLongitude(-185.0), isNotNull);
      expect(AppValidators.validateLongitude(null), isNotNull);
    });

    test('validateNonNegativeInt checks non-negative integers', () {
      expect(AppValidators.validateNonNegativeInt('0', 'Kapasitas'), isNull);
      expect(AppValidators.validateNonNegativeInt('15', 'Kapasitas'), isNull);
      expect(
          AppValidators.validateNonNegativeInt('-5', 'Kapasitas'), isNotNull);
      expect(
          AppValidators.validateNonNegativeInt('abc', 'Kapasitas'), isNotNull);
      expect(AppValidators.validateNonNegativeInt('', 'Kapasitas'), isNotNull);
    });
  });

  group('AppFormatters Tests', () {
    test('maskNik and maskNpwp masks properly', () {
      expect(AppFormatters.maskNik('3171234567890001'), '•••• •••• •••• 0001');
      expect(AppFormatters.maskNpwp('012345678901000'), '•••• •••• •••• 1000');
      expect(AppFormatters.maskNik(null), '-');
      expect(AppFormatters.maskNpwp(''), '-');
    });

    test('formatFileSize converts bytes correctly', () {
      expect(AppFormatters.formatFileSize(500), '500 B');
      expect(AppFormatters.formatFileSize(2048), '2.0 KB');
      expect(AppFormatters.formatFileSize(1048576 * 3), '3.0 MB');
    });

    test('formatRupiah formats IDR currency correctly', () {
      expect(AppFormatters.formatRupiah(75000), 'Rp 75.000');
      expect(AppFormatters.formatRupiah(1500000), 'Rp 1.500.000');
      expect(AppFormatters.formatRupiah(null), 'Rp 0');
    });
  });
}
