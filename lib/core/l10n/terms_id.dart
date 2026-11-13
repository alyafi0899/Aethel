import '../../features/clinic/models/clinic_enums.dart';

extension ClinicStatusTerms on ClinicStatus {
  String get userLabel => switch (this) {
        ClinicStatus.draft => 'Belum dikirim',
        ClinicStatus.submitted => 'Menunggu ditinjau',
        ClinicStatus.under_review => 'Sedang ditinjau',
        ClinicStatus.verified => 'Terverifikasi',
        ClinicStatus.rejected => 'Perlu diperbaiki',
        ClinicStatus.suspended => 'Dinonaktifkan',
      };
}
