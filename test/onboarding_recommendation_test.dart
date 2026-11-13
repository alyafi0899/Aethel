import 'package:clinic_operations_platform/features/clinic/models/onboarding_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps recommendation keys to Indonesian labels and profile tabs', () {
    final expected = {
      'emr_choice': (
        'Pilih sistem rekam medis klinik',
        OnboardingRecommendationDestination.emrSettings,
        3,
      ),
      'emr_app_name': (
        'Isi nama aplikasi RME',
        OnboardingRecommendationDestination.emrSettings,
        3,
      ),
      'satusehat_organization_id': (
        'Isi ID organisasi SATUSEHAT',
        OnboardingRecommendationDestination.emrSettings,
        3,
      ),
      'doc:service_sop': (
        'Unggah SOP layanan',
        OnboardingRecommendationDestination.documentsAndLegal,
        2,
      ),
      'media:gallery': (
        'Tambah foto galeri',
        OnboardingRecommendationDestination.publicGallery,
        4,
      ),
    };

    for (final entry in expected.entries) {
      final recommendation = OnboardingRecommendation.fromKey(entry.key)!;
      expect(recommendation.label, entry.value.$1);
      expect(recommendation.destination, entry.value.$2);
      expect(recommendation.profileTabIndex, entry.value.$3);
    }

    expect(
      OnboardingRecommendation.fromKey('media:gallery')!.wizardStepIndex,
      1,
    );
    expect(OnboardingRecommendation.fromKey('unknown'), isNull);
  });
}
