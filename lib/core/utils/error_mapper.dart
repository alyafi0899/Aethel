import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps technical database, auth, and storage exceptions to friendly Indonesian messages.
class ErrorMapper {
  static String mapError(Object? error) {
    if (error == null) return 'Terjadi kesalahan yang tidak diketahui.';

    if (error is AuthException) {
      return _mapAuthError(error);
    }

    if (error is PostgrestException) {
      return _mapPostgrestError(error);
    }

    if (error is StorageException) {
      return _mapStorageError(error);
    }

    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('clientexception') ||
        str.contains('network_error')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    return error.toString().replaceAll('Exception: ', '');
  }

  static String _mapAuthError(AuthException error) {
    final code = error.code ?? '';
    final msg = error.message.toLowerCase();

    if (code == 'invalid_credentials' || msg.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek kotak masuk email Anda.';
    }
    if (code == 'weak_password' || msg.contains('password should be at least')) {
      return 'Kata sandi terlalu lemah. Gunakan minimal 10 karakter kombinasi huruf dan angka.';
    }
    if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Silakan coba lagi beberapa menit kemudian.';
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'Email ini sudah terdaftar di sistem.';
    }

    return error.message;
  }

  static String _mapPostgrestError(PostgrestException error) {
    final code = error.code ?? '';
    final msg = error.message;
    final detail = error.details?.toString() ?? '';

    if (code == '42501' || msg.contains('not_authorized')) {
      return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
    }

    if (code == '23505') {
      if (detail.contains('fasyankes_code') || msg.contains('fasyankes_code')) {
        return 'Kode fasyankes ini sudah terdaftar pada klinik lain.';
      }
      if (detail.contains('clinics_owner_unique')) {
        return 'Akun Anda sudah memiliki pendaftaran klinik.';
      }
      return 'Data ini sudah terdaftar di sistem (duplikasi data).';
    }

    if (code == '23514') {
      return 'Format atau batas nilai data yang dimasukkan tidak sesuai.';
    }

    if (code == '23503') {
      return 'Data terkait tidak ditemukan atau sedang digunakan.';
    }

    if (msg.contains('onboarding_incomplete')) {
      return _parseOnboardingIncomplete(detail);
    }

    if (msg.contains('invalid_status_for_submit')) {
      return 'Status klinik saat ini tidak dapat dikirimkan untuk peninjauan.';
    }

    if (msg.contains('clinic_not_verified')) {
      return 'Klinik harus berstatus terverifikasi sebelum dapat dipublikasikan.';
    }

    if (msg.contains('rejection_reason_required')) {
      return 'Alasan penolakan wajib diisi.';
    }

    return msg.isNotEmpty ? msg : 'Terjadi kesalahan pada database.';
  }

  static String _mapStorageError(StorageException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('payload too large') || msg.contains('exceeds')) {
      return 'Ukuran berkas terlalu besar. Batas maksimal adalah 10 MB.';
    }
    if (msg.contains('mime') || msg.contains('type')) {
      return 'Format berkas tidak didukung. Gunakan PDF, JPG, PNG, atau WEBP.';
    }
    return 'Gagal mengunggah berkas. Periksa koneksi internet dan coba lagi.';
  }

  static String _parseOnboardingIncomplete(String detailJson) {
    if (detailJson.isEmpty) {
      return 'Data onboarding belum lengkap. Lengkapi semua bagian yang wajib diisi.';
    }

    try {
      final decoded = jsonDecode(detailJson) as Map<String, dynamic>;
      final missingList = <String>[];

      void collectMissing(dynamic section) {
        if (section is Map && section['missing'] is List) {
          for (final item in (section['missing'] as List)) {
            final key = item.toString();
            final label = technicalKeyToIndonesian(key);
            if (!missingList.contains(label)) {
              missingList.add(label);
            }
          }
        }
      }

      collectMissing(decoded['basic_data']);
      collectMissing(decoded['services_facilities']);
      collectMissing(decoded['admin_legal']);
      collectMissing(decoded['emr_system']);
      collectMissing(decoded['health_workers']);

      if (missingList.isNotEmpty) {
        return 'Data belum lengkap:\n• ${missingList.join('\n• ')}';
      }
    } catch (_) {}

    return 'Data onboarding belum lengkap. Silakan periksa kembali formulir Anda.';
  }

  /// Maps technical database missing key to user-friendly Indonesian label.
  static String technicalKeyToIndonesian(String key) {
    switch (key) {
      case 'clinic_name':
        return 'Nama Resmi Klinik (Data Dasar)';
      case 'legal_entity_type':
        return 'Bentuk Badan Hukum (Data Dasar)';
      case 'address_full':
        return 'Alamat Lengkap Klinik (Data Dasar)';
      case 'coordinates':
        return 'Titik Koordinat / Lokasi Geografis (Data Dasar)';
      case 'phone':
        return 'Nomor Telepon Resmi (Data Dasar)';
      case 'email':
        return 'Alamat Email Resmi (Data Dasar)';
      case 'sio_number':
        return 'Nomor Surat Izin Operasional / SIO (Data Dasar)';
      case 'sio_expiry':
        return 'Masa Berlaku SIO (Data Dasar)';
      case 'npwp':
        return 'NPWP Klinik (Data Dasar)';
      case 'fasyankes_code':
        return 'Kode Registrasi Fasyankes Kemenkes (Data Dasar)';
      case 'deed_number':
        return 'Nomor Akta Pendirian (Data Dasar)';
      case 'doc:sio':
        return 'Unggah Dokumen SIO (Data Dasar)';
      case 'doc:deed_of_establishment':
        return 'Unggah Dokumen Akta Pendirian (Data Dasar)';
      case 'services':
        return 'Jenis Layanan / Spesialisasi (Layanan & Fasilitas)';
      case 'facilities':
        return 'Fasilitas & Prasarana Klinik (Layanan & Fasilitas)';
      case 'equipment':
        return 'Peralatan Medis & Non-Medis (Layanan & Fasilitas)';
      case 'operating_hours':
        return 'Jam Operasional Klinik (Layanan & Fasilitas)';
      case 'doc:registration_request_letter':
        return 'Unggah Surat Permohonan Registrasi (Administrasi & Legal)';
      case 'doc:quality_commitment_statement':
        return 'Unggah Surat Pernyataan Komitmen Mutu (Administrasi & Legal)';
      case 'org_structure':
        return 'Struktur Organisasi Klinik (Administrasi & Legal)';
      case 'bpjs_facility_code':
        return 'Kode Fasilitas BPJS (Administrasi & Legal)';
      case 'doc:bpjs_cooperation_proof':
        return 'Unggah Bukti Kerjasama BPJS (Administrasi & Legal)';
      case 'emr_app_name':
        return 'Nama Aplikasi RME (Sistem RME)';
      case 'doc:service_sop':
        return 'Unggah Dokumen SOP Layanan (Sistem RME)';
      case 'doc:clinic_photo':
        return 'Unggah Foto Klinik (Sistem RME)';
      case 'person_in_charge':
        return 'Penanggung Jawab Klinik (Tenaga Kesehatan)';
      case 'doctor_with_str_sip':
        return 'Dokter dengan STR & SIP Aktif (Tenaga Kesehatan)';
      default:
        return key;
    }
  }

  /// Maps missing technical key to step index (1-based, 1 to 5).
  static int keyToStepIndex(String key) {
    if (key.startsWith('doc:sio') ||
        key.startsWith('doc:deed_of') ||
        key == 'clinic_name' ||
        key == 'legal_entity_type' ||
        key == 'address_full' ||
        key == 'coordinates' ||
        key == 'phone' ||
        key == 'email' ||
        key == 'sio_number' ||
        key == 'sio_expiry' ||
        key == 'npwp' ||
        key == 'fasyankes_code' ||
        key == 'deed_number') {
      return 1;
    }
    if (key == 'services' ||
        key == 'facilities' ||
        key == 'equipment' ||
        key == 'operating_hours') {
      return 2;
    }
    if (key.startsWith('doc:registration') ||
        key.startsWith('doc:quality') ||
        key.startsWith('doc:bpjs') ||
        key == 'org_structure' ||
        key == 'bpjs_facility_code') {
      return 3;
    }
    if (key == 'emr_app_name' ||
        key.startsWith('doc:service_sop') ||
        key.startsWith('doc:clinic_photo')) {
      return 4;
    }
    if (key == 'person_in_charge' || key == 'doctor_with_str_sip') {
      return 5;
    }
    return 1;
  }
}
