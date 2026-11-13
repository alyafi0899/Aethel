import '../../features/clinic/models/clinic_enums.dart';

const kEmrSectionLabel = 'Rekam Medis (RME)';
const kPrometheonEmrLabel = 'Prometheon';
const kThirdPartyEmrLabel = 'Aplikasi lain';
const kInternalEmrLabel = 'Dikembangkan klinik sendiri';
const kNoEmrLabel = 'Belum punya';

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

extension EmrAppTypeTerms on EmrAppType {
  String get userLabel => switch (this) {
        EmrAppType.prometheon => kPrometheonEmrLabel,
        EmrAppType.thirdParty => kThirdPartyEmrLabel,
        EmrAppType.internal => kInternalEmrLabel,
        EmrAppType.none => kNoEmrLabel,
      };
}
