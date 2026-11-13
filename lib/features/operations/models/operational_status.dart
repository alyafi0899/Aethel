import '../../clinic/models/clinic_enums.dart';

enum OperationalMode {
  open,
  breakTime,
  closed,
  maintenance;

  String get label => switch (this) {
        open => 'Buka',
        breakTime => 'Istirahat',
        closed => 'Tutup',
        maintenance => 'Pemeliharaan',
      };

  static OperationalMode fromDatabase({
    required FacilityOperatingStatus facilityStatus,
    required QueueProcessStatus queueStatus,
  }) {
    if (facilityStatus == FacilityOperatingStatus.maintenance) {
      return OperationalMode.maintenance;
    }
    if (facilityStatus == FacilityOperatingStatus.closed) {
      return OperationalMode.closed;
    }
    if (queueStatus == QueueProcessStatus.paused) {
      return OperationalMode.breakTime;
    }
    return OperationalMode.open;
  }

  static String patientFacingStatus({
    required FacilityOperatingStatus facilityStatus,
    required QueueProcessStatus queueStatus,
  }) {
    if (facilityStatus == FacilityOperatingStatus.maintenance) {
      return 'Pemeliharaan';
    }
    if (facilityStatus == FacilityOperatingStatus.closed) {
      return 'Tutup';
    }
    if (queueStatus == QueueProcessStatus.closed) {
      return 'Buka (antrean ditutup)';
    }
    if (queueStatus == QueueProcessStatus.paused) {
      return 'Istirahat';
    }
    return 'Buka';
  }

  FacilityOperatingStatus get facilityStatus => switch (this) {
        open || breakTime => FacilityOperatingStatus.open,
        closed => FacilityOperatingStatus.closed,
        maintenance => FacilityOperatingStatus.maintenance,
      };

  QueueProcessStatus get queueStatus => switch (this) {
        open => QueueProcessStatus.active,
        breakTime => QueueProcessStatus.paused,
        closed || maintenance => QueueProcessStatus.closed,
      };
}
