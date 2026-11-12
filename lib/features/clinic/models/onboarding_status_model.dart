import 'clinic_enums.dart';

class OnboardingSectionStatus {
  const OnboardingSectionStatus({
    this.complete = false,
    this.missing = const [],
  });

  final bool complete;
  final List<String> missing;

  factory OnboardingSectionStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OnboardingSectionStatus();
    return OnboardingSectionStatus(
      complete: (json['complete'] as bool?) ?? false,
      missing: json['missing'] != null
          ? (json['missing'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class OnboardingStatusModel {
  const OnboardingStatusModel({
    required this.status,
    this.basicData = const OnboardingSectionStatus(),
    this.servicesFacilities = const OnboardingSectionStatus(),
    this.adminLegal = const OnboardingSectionStatus(),
    this.emrSystem = const OnboardingSectionStatus(),
    this.healthWorkers = const OnboardingSectionStatus(),
    this.publicMedia = const OnboardingSectionStatus(),
    this.readyToSubmit = false,
  });

  final ClinicStatus status;
  final OnboardingSectionStatus basicData;
  final OnboardingSectionStatus servicesFacilities;
  final OnboardingSectionStatus adminLegal;
  final OnboardingSectionStatus emrSystem;
  final OnboardingSectionStatus healthWorkers;
  final OnboardingSectionStatus publicMedia;
  final bool readyToSubmit;

  int get completedSectionsCount {
    var count = 0;
    if (basicData.complete) count++;
    if (servicesFacilities.complete) count++;
    if (adminLegal.complete) count++;
    if (emrSystem.complete) count++;
    if (healthWorkers.complete) count++;
    if (publicMedia.complete) count++;
    return count;
  }

  double get completionProgress => completedSectionsCount / 6.0;

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusModel(
      status: ClinicStatus.fromDb(json['status'] as String?),
      basicData: OnboardingSectionStatus.fromJson(
          json['basic_data'] as Map<String, dynamic>?),
      servicesFacilities: OnboardingSectionStatus.fromJson(
          json['services_facilities'] as Map<String, dynamic>?),
      adminLegal: OnboardingSectionStatus.fromJson(
          json['admin_legal'] as Map<String, dynamic>?),
      emrSystem: OnboardingSectionStatus.fromJson(
          json['emr_system'] as Map<String, dynamic>?),
      healthWorkers: OnboardingSectionStatus.fromJson(
          json['health_workers'] as Map<String, dynamic>?),
      publicMedia: OnboardingSectionStatus.fromJson(
          json['public_media'] as Map<String, dynamic>?),
      readyToSubmit: (json['ready_to_submit'] as bool?) ?? false,
    );
  }
}
