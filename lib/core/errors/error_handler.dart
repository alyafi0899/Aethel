import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class ErrorHandler {
  static String translate(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
      }
      if (msg.contains('user not found')) {
        return 'Akun pengguna tidak ditemukan.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email belum dikonfirmasi. Periksa kotak masuk email Anda.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Terlalu banyak percobaan. Silakan tunggu beberapa saat.';
      }
      return 'Gagal melakukan otentikasi: ${error.message}';
    }

    if (error is PostgrestException) {
      if (error.code == '42501' ||
          error.message.contains('permission denied')) {
        return 'Anda tidak memiliki izin untuk melakukan tindakan ini.';
      }
      if (error.code == '23505' ||
          error.message.contains('unique constraint')) {
        return 'Data dengan referensi atau ID tersebut sudah ada.';
      }
      return 'Gagal memproses data database: ${error.message}';
    }

    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('timeout')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    return 'Terjadi kesalahan sistem: $error';
  }
}
