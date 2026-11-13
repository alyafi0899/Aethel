import 'package:clinic_operations_platform/core/utils/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ErrorMapper Unit Tests', () {
    test('mapError handles null error', () {
      expect(ErrorMapper.mapError(null),
          equals('Terjadi kesalahan yang tidak diketahui.'));
    });

    test('mapError maps AuthException correctly', () {
      expect(
        ErrorMapper.mapError(
          const AuthException('Invalid login credentials',
              code: 'invalid_credentials'),
        ),
        equals('Email atau kata sandi salah.'),
      );

      expect(
        ErrorMapper.mapError(
          const AuthException('Email not confirmed',
              code: 'email_not_confirmed'),
        ),
        equals('Email belum dikonfirmasi. Cek kotak masuk email Anda.'),
      );

      expect(
        ErrorMapper.mapError(
          const AuthException('Password should be at least 10 chars',
              code: 'weak_password'),
        ),
        contains('Kata sandi terlalu lemah'),
      );

      expect(
        ErrorMapper.mapError(
          const AuthException('Email rate limit exceeded',
              code: 'over_email_send_rate_limit'),
        ),
        contains('Terlalu banyak percobaan'),
      );

      expect(
        ErrorMapper.mapError(
          const AuthException('User already registered',
              code: 'user_already_exists'),
        ),
        equals('Email ini sudah terdaftar di sistem.'),
      );

      expect(
        ErrorMapper.mapError(
          const AuthException('Database error saving new user'),
        ),
        contains('0003_profiles_account_type.sql'),
      );
    });

    test('mapError maps PostgrestException correctly', () {
      expect(
        ErrorMapper.mapError(
          const PostgrestException(message: 'Permission denied', code: '42501'),
        ),
        equals('Anda tidak memiliki izin untuk melakukan aksi ini.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(
            message:
                "Could not find the 'emr_choice_confirmed' column of 'clinic_emr_settings' in the schema cache",
            code: 'PGRST204',
          ),
        ),
        contains('0004_emr_choice_confirmed_schema_cache.sql'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
            details: 'Key (fasyankes_code)=(FK123) already exists',
          ),
        ),
        equals('Kode fasyankes ini sudah terdaftar pada klinik lain.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(
            message: 'duplicate key value',
            code: '23505',
            details: 'clinics_owner_unique constraint',
          ),
        ),
        equals('Akun Anda sudah memiliki pendaftaran klinik.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(
              message: 'check constraint failed', code: '23514'),
        ),
        equals('Format atau batas nilai data yang dimasukkan tidak sesuai.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(
              message: 'foreign key constraint failed', code: '23503'),
        ),
        equals('Data terkait tidak ditemukan atau sedang digunakan.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(
            message: 'onboarding_incomplete',
            details: '{"basic_data":{"missing":["clinic_name","sio_number"]}}',
          ),
        ),
        contains('Data belum lengkap:'),
      );
      expect(
        ErrorMapper.mapError(
          const PostgrestException(
            message: 'onboarding_incomplete',
            details:
                '{"emr_system":{"complete":false,"missing":["emr_app_name"]}}',
          ),
        ),
        contains('0005_align_onboarding_submit_readiness.sql'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(message: 'invalid_status_for_submit'),
        ),
        equals(
            'Status klinik saat ini tidak dapat dikirimkan untuk peninjauan.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(message: 'clinic_not_verified'),
        ),
        equals('Kode API hanya dapat disimpan setelah klinik terverifikasi.'),
      );

      expect(
        ErrorMapper.mapError(
          const PostgrestException(message: 'rejection_reason_required'),
        ),
        equals('Alasan penolakan wajib diisi.'),
      );
    });

    test('mapError maps StorageException correctly', () {
      expect(
        ErrorMapper.mapError(
          const StorageException('Payload too large'),
        ),
        contains('5 MB'),
      );

      expect(
        ErrorMapper.mapError(
          const StorageException('Invalid mime type'),
        ),
        contains('Format berkas tidak didukung'),
      );
    });

    test('mapError maps network errors correctly', () {
      expect(
        ErrorMapper.mapError(Exception('SocketException: Failed host lookup')),
        contains('Gagal terhubung ke server'),
      );

      expect(
        ErrorMapper.mapError(Exception('ClientException: Connection refused')),
        contains('Gagal terhubung ke server'),
      );
    });

    test('technicalKeyToIndonesian maps all technical keys', () {
      expect(ErrorMapper.technicalKeyToIndonesian('clinic_name'),
          contains('Nama Resmi Klinik'));
      expect(ErrorMapper.technicalKeyToIndonesian('sio_number'),
          contains('Nomor Surat Izin Operasional'));
      expect(ErrorMapper.technicalKeyToIndonesian('doc:sio'),
          contains('Unggah Dokumen SIO'));
      expect(ErrorMapper.technicalKeyToIndonesian('services'),
          contains('Jenis Layanan'));
      expect(ErrorMapper.technicalKeyToIndonesian('operating_hours'),
          contains('Jam Operasional'));
      expect(
          ErrorMapper.technicalKeyToIndonesian(
              'doc:registration_request_letter'),
          contains('Surat Permohonan Registrasi'));
      expect(ErrorMapper.technicalKeyToIndonesian('person_in_charge'),
          contains('Penanggung Jawab Klinik'));
      expect(ErrorMapper.technicalKeyToIndonesian('unknown_key'),
          equals('unknown_key'));
    });

    test('keyToStepIndex returns correct wizard step', () {
      expect(ErrorMapper.keyToStepIndex('clinic_name'), 1);
      expect(ErrorMapper.keyToStepIndex('sio_number'), 1);
      expect(ErrorMapper.keyToStepIndex('doc:sio'), 1);

      expect(ErrorMapper.keyToStepIndex('services'), 2);
      expect(ErrorMapper.keyToStepIndex('facilities'), 2);
      expect(ErrorMapper.keyToStepIndex('operating_hours'), 2);

      expect(ErrorMapper.keyToStepIndex('doc:registration_request_letter'), 3);
      expect(ErrorMapper.keyToStepIndex('org_structure'), 3);
      expect(ErrorMapper.keyToStepIndex('bpjs_facility_code'), 3);

      expect(ErrorMapper.keyToStepIndex('person_in_charge'), 5);
      expect(ErrorMapper.keyToStepIndex('doctor_with_str_sip'), 5);
    });
  });
}
