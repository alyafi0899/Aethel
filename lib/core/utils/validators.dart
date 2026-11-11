/// Form field validation helper functions for Prometheon Clinic OS.
class AppValidators {
  /// Validates email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Format email tidak valid (contoh: admin@klinik.com).';
    }
    return null;
  }

  /// Normalizes Indonesian phone numbers (08... -> +628...) and strips symbols.
  static String normalizePhone(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('62')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  /// Validates Indonesian phone numbers (8–15 digits).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon/WhatsApp tidak boleh kosong.';
    }
    final normalized = normalizePhone(value);
    final phoneRegExp = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegExp.hasMatch(normalized)) {
      return 'Nomor telepon tidak valid (8–15 digit, contoh: 081234567890).';
    }
    return null;
  }

  /// Validates password strength (≥10 characters, letters & digits required).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong.';
    }
    if (value.length < 10) {
      return 'Kata sandi minimal 10 karakter.';
    }
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasDigit) {
      return 'Kata sandi harus mengombinasikan huruf dan angka.';
    }
    return null;
  }

  /// Validates password confirmation.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong.';
    }
    if (value != password) {
      return 'Konfirmasi kata sandi tidak cocok.';
    }
    return null;
  }

  /// Validates NPWP (15 or 16 digits after stripping dots/dashes).
  static String? validateNpwp(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'NPWP tidak boleh kosong.';
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 15 && cleaned.length != 16) {
      return 'NPWP harus terdiri dari 15 atau 16 digit angka.';
    }
    return null;
  }

  /// Validates NIK (16 digits).
  static String? validateNik(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'NIK tidak boleh kosong.';
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 16) {
      return 'NIK harus persis 16 digit angka.';
    }
    return null;
  }

  /// Validates non-empty field.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    return null;
  }

  /// Validates SIO expiry date (must be in the future).
  static String? validateSioExpiry(DateTime? date) {
    if (date == null) {
      return 'Tanggal masa berlaku SIO wajib diisi.';
    }
    final today = DateTime.now();
    final todayZero = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayZero)) {
      return 'Masa berlaku SIO sudah berakhir.';
    }
    return null;
  }

  /// Validates latitude (-90 to 90).
  static String? validateLatitude(double? lat) {
    if (lat == null) return 'Latitude wajib diisi.';
    if (lat < -90.0 || lat > 90.0) {
      return 'Nilai latitude harus di antara -90 dan 90.';
    }
    return null;
  }

  /// Validates longitude (-180 to 180).
  static String? validateLongitude(double? lng) {
    if (lng == null) return 'Longitude wajib diisi.';
    if (lng < -180.0 || lng > 180.0) {
      return 'Nilai longitude harus di antara -180 dan 180.';
    }
    return null;
  }

  /// Validates non-negative integers.
  static String? validateNonNegativeInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return '$fieldName harus bernilai 0 atau lebih.';
    }
    return null;
  }
}
