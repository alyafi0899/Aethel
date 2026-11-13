enum OnboardingRecommendationDestination {
  emrSettings,
  documentsAndLegal,
  publicGallery,
}

class OnboardingRecommendation {
  const OnboardingRecommendation({
    required this.key,
    required this.label,
    required this.destination,
    required this.profileTabIndex,
    required this.wizardStepIndex,
  });

  final String key;
  final String label;
  final OnboardingRecommendationDestination destination;
  final int profileTabIndex;
  final int wizardStepIndex;

  static const Map<String, OnboardingRecommendation> byKey = {
    'emr_choice': OnboardingRecommendation(
      key: 'emr_choice',
      label: 'Pilih sistem rekam medis klinik',
      destination: OnboardingRecommendationDestination.emrSettings,
      profileTabIndex: 3,
      wizardStepIndex: 4,
    ),
    'emr_app_name': OnboardingRecommendation(
      key: 'emr_app_name',
      label: 'Isi nama aplikasi RME',
      destination: OnboardingRecommendationDestination.emrSettings,
      profileTabIndex: 3,
      wizardStepIndex: 4,
    ),
    'satusehat_organization_id': OnboardingRecommendation(
      key: 'satusehat_organization_id',
      label: 'Isi ID organisasi SATUSEHAT',
      destination: OnboardingRecommendationDestination.emrSettings,
      profileTabIndex: 3,
      wizardStepIndex: 4,
    ),
    'doc:service_sop': OnboardingRecommendation(
      key: 'doc:service_sop',
      label: 'Unggah SOP layanan',
      destination: OnboardingRecommendationDestination.documentsAndLegal,
      profileTabIndex: 2,
      wizardStepIndex: 3,
    ),
    'media:gallery': OnboardingRecommendation(
      key: 'media:gallery',
      label: 'Tambah foto galeri',
      destination: OnboardingRecommendationDestination.publicGallery,
      profileTabIndex: 4,
      wizardStepIndex: 1,
    ),
  };

  static OnboardingRecommendation? fromKey(String key) => byKey[key];
}
