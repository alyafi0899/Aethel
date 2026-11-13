import 'clinic_enums.dart';
import 'clinic_media_model.dart';

const _optionalLegacyOnboardingKeys = {
  'emr_app_name',
  'doc:service_sop',
  'doc:clinic_photo',
};

class OnboardingSectionStatus {
  const OnboardingSectionStatus({
    this.complete = false,
    this.missing = const [],
  });

  final bool complete;
  final List<String> missing;

  factory OnboardingSectionStatus.fromMissing(List<String> missing) {
    return OnboardingSectionStatus(
      complete: missing.isEmpty,
      missing: missing,
    );
  }

  factory OnboardingSectionStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OnboardingSectionStatus();
    final rawMissing = json['missing'];
    final missing = rawMissing is List
        ? rawMissing
            .map((item) => item.toString())
            .where((key) => !_optionalLegacyOnboardingKeys.contains(key))
            .toList()
        : const <String>[];
    return OnboardingSectionStatus(
      complete: (json['complete'] as bool?) == true ||
          (rawMissing is List && missing.isEmpty),
      missing: missing,
    );
  }
}

class OnboardingStatusModel {
  const OnboardingStatusModel({
    required this.status,
    this.basicData = const OnboardingSectionStatus(),
    this.servicesFacilities = const OnboardingSectionStatus(),
    this.adminLegal = const OnboardingSectionStatus(),
    this.healthWorkers = const OnboardingSectionStatus(),
    this.publicMedia = const OnboardingSectionStatus(),
    this.recommendations = const [],
  }) : emrSystem = const OnboardingSectionStatus(complete: true);

  final ClinicStatus status;
  final OnboardingSectionStatus basicData;
  final OnboardingSectionStatus servicesFacilities;
  final OnboardingSectionStatus adminLegal;
  final OnboardingSectionStatus emrSystem;
  final OnboardingSectionStatus healthWorkers;
  final OnboardingSectionStatus publicMedia;
  final List<String> recommendations;

  bool get readyToSubmit =>
      basicData.complete &&
      servicesFacilities.complete &&
      adminLegal.complete &&
      healthWorkers.complete &&
      publicMedia.complete;

  int get completedSectionsCount {
    var count = 0;
    if (basicData.complete) count++;
    if (servicesFacilities.complete) count++;
    if (adminLegal.complete) count++;
    if (healthWorkers.complete) count++;
    if (publicMedia.complete) count++;
    return count;
  }

  double get completionProgress => completedSectionsCount / 5.0;

  List<String> get requiredMissingItems => [
        ...basicData.missing,
        ...servicesFacilities.missing,
        ...adminLegal.missing,
        ...healthWorkers.missing,
        ...publicMedia.missing,
      ];

  OnboardingStatusModel withPublicMediaRecords(
    List<ClinicMediaModel> media,
  ) {
    final availableKinds = media
        .where(
          (item) => item.reviewStatus != DocumentReviewStatus.rejected,
        )
        .map((item) => item.kind)
        .toSet();
    final missing = [
      if (!availableKinds.contains(MediaKind.logo)) 'media:logo',
      if (!availableKinds.contains(MediaKind.cover)) 'media:cover',
    ];

    return OnboardingStatusModel(
      status: status,
      basicData: basicData,
      servicesFacilities: servicesFacilities,
      adminLegal: adminLegal,
      healthWorkers: healthWorkers,
      publicMedia: OnboardingSectionStatus.fromMissing(missing),
      recommendations: recommendations,
    );
  }

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    final recommendationData = json['recommendations'];
    return OnboardingStatusModel(
      status: ClinicStatus.fromDb(json['status'] as String?),
      basicData: OnboardingSectionStatus.fromJson(
          json['basic_data'] as Map<String, dynamic>?),
      servicesFacilities: OnboardingSectionStatus.fromJson(
          json['services_facilities'] as Map<String, dynamic>?),
      adminLegal: OnboardingSectionStatus.fromJson(
          json['admin_legal'] as Map<String, dynamic>?),
      healthWorkers: OnboardingSectionStatus.fromJson(
          json['health_workers'] as Map<String, dynamic>?),
      publicMedia: OnboardingSectionStatus.fromJson(
          json['public_media'] as Map<String, dynamic>?),
      recommendations: recommendationData is List
          ? recommendationData.map((item) => item.toString()).toList()
          : const [],
    );
  }
}
