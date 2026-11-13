import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:clinic_operations_platform/features/operations/models/operational_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pemetaan status operasional', () {
    test('Buka menyimpan layanan buka dan antrean aktif', () {
      expect(OperationalMode.open.facilityStatus, FacilityOperatingStatus.open);
      expect(OperationalMode.open.queueStatus, QueueProcessStatus.active);
    });

    test('Istirahat menyimpan layanan buka dan antrean jeda', () {
      expect(OperationalMode.breakTime.facilityStatus,
          FacilityOperatingStatus.open);
      expect(OperationalMode.breakTime.queueStatus, QueueProcessStatus.paused);
    });

    test('Tutup menyimpan layanan tutup dan antrean tutup', () {
      expect(OperationalMode.closed.facilityStatus,
          FacilityOperatingStatus.closed);
      expect(OperationalMode.closed.queueStatus, QueueProcessStatus.closed);
    });

    test('status buka dengan antrean tutup tetap terbaca sebagai Buka', () {
      expect(
        OperationalMode.fromDatabase(
          facilityStatus: FacilityOperatingStatus.open,
          queueStatus: QueueProcessStatus.closed,
        ),
        OperationalMode.open,
      );
      expect(
        OperationalMode.patientFacingStatus(
          facilityStatus: FacilityOperatingStatus.open,
          queueStatus: QueueProcessStatus.closed,
        ),
        'Buka (antrean ditutup)',
      );
    });

    test('pemeliharaan dikenali terlepas dari status antrean', () {
      expect(
        OperationalMode.fromDatabase(
          facilityStatus: FacilityOperatingStatus.maintenance,
          queueStatus: QueueProcessStatus.closed,
        ),
        OperationalMode.maintenance,
      );
      expect(
          OperationalMode.maintenance.queueStatus, QueueProcessStatus.closed);
    });
  });
}
