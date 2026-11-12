import 'package:intl/intl.dart';

/// Formatting utilities for Indonesian currency, dates, masked PII, and phones.
class AppFormatters {
  /// Formats currency in IDR (e.g. 75000 -> "Rp 75.000").
  static String formatRupiah(int? amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount).replaceAll('\u00A0', ' ');
  }

  /// Formats currency in IDR (alias for formatRupiah).
  static String formatCurrency(int amount) => formatRupiah(amount);

  /// Masks sensitive NIK (16 digits) to display only the last 4 digits.
  static String maskNik(String? nik) {
    if (nik == null || nik.isEmpty) return '-';
    final cleaned = nik.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 4) return '••••';
    final last4 = cleaned.substring(cleaned.length - 4);
    return '•••• •••• •••• $last4';
  }

  /// Masks sensitive NPWP (15-16 digits) to display only the last 4 digits.
  static String maskNpwp(String? npwp) {
    if (npwp == null || npwp.isEmpty) return '-';
    final cleaned = npwp.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 4) return '••••';
    final last4 = cleaned.substring(cleaned.length - 4);
    return '•••• •••• •••• $last4';
  }

  /// Formats date to Indonesian standard string (e.g. "17 Jun 2025").
  static String formatDate(DateTime? date, {String fallback = '-'}) {
    if (date == null) return fallback;
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  /// Formats date to full Indonesian text (e.g. "17 Juni 2025").
  static String formatDateFull(DateTime? date, {String fallback = '-'}) {
    if (date == null) return fallback;
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  /// Formats date & time to Indonesian standard string (e.g. "17 Jun 2025, 09:30").
  static String formatDateTime(DateTime? dateTime, {String fallback = '-'}) {
    if (dateTime == null) return fallback;
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  /// Formats file size in bytes to human-readable string (KB/MB).
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
