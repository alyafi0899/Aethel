import '../../clinic/models/clinic_enums.dart';

class ClinicOperationsInternalModel {
  const ClinicOperationsInternalModel({
    required this.clinicId,
    this.clinicName,
    this.totalQueues = 0,
    this.currentQueueNumber = 0,
    this.queueProcessStatus = QueueProcessStatus.closed,
    this.averageWaitTime = 0,
    this.totalRegisteredPatients = 0,
    this.totalDailyVisitors = 0,
    this.totalDoctorsAvailable = 0,
    this.activeRoomsCount = 0,
    this.availableRoomsCount = 0,
    this.dailyAppointmentsCount = 0,
    this.cancelledAppointmentsCount = 0,
    this.serviceTypes = const [],
    this.facilityStatus = FacilityOperatingStatus.closed,
    this.staffOnDutyCount = 0,
    this.totalCompletedConsultations = 0,
    this.lastUpdateTimestamp,
  });

  final String clinicId;
  final String? clinicName;

  // DIISI MANUAL pengelola (sementara)
  final int totalQueues;
  final int currentQueueNumber;
  final QueueProcessStatus queueProcessStatus;
  final int averageWaitTime; // menit
  final int totalRegisteredPatients;
  final int totalDailyVisitors;
  final int dailyAppointmentsCount;
  final int cancelledAppointmentsCount;
  final FacilityOperatingStatus facilityStatus;
  final int totalCompletedConsultations;

  // OTOMATIS dihitung server (read-only)
  final int totalDoctorsAvailable;
  final int activeRoomsCount;
  final int availableRoomsCount;
  final List<String> serviceTypes;
  final int staffOnDutyCount;
  final DateTime? lastUpdateTimestamp;

  factory ClinicOperationsInternalModel.fromJson(Map<String, dynamic> json) {
    return ClinicOperationsInternalModel(
      clinicId: json['clinic_id'] as String,
      clinicName: json['clinic_name'] as String?,
      totalQueues: (json['total_queues'] as num?)?.toInt() ?? 0,
      currentQueueNumber: (json['current_queue_number'] as num?)?.toInt() ?? 0,
      queueProcessStatus:
          QueueProcessStatus.fromDb(json['queue_process_status'] as String?),
      averageWaitTime: (json['average_wait_time'] as num?)?.toInt() ?? 0,
      totalRegisteredPatients:
          (json['total_registered_patients'] as num?)?.toInt() ?? 0,
      totalDailyVisitors: (json['total_daily_visitors'] as num?)?.toInt() ?? 0,
      totalDoctorsAvailable:
          (json['total_doctors_available'] as num?)?.toInt() ?? 0,
      activeRoomsCount: (json['active_rooms_count'] as num?)?.toInt() ?? 0,
      availableRoomsCount:
          (json['available_rooms_count'] as num?)?.toInt() ?? 0,
      dailyAppointmentsCount:
          (json['daily_appointments_count'] as num?)?.toInt() ?? 0,
      cancelledAppointmentsCount:
          (json['cancelled_appointments_count'] as num?)?.toInt() ?? 0,
      serviceTypes: json['service_types'] != null
          ? (json['service_types'] as List).map((e) => e.toString()).toList()
          : const [],
      facilityStatus:
          FacilityOperatingStatus.fromDb(json['facility_status'] as String?),
      staffOnDutyCount: (json['staff_on_duty_count'] as num?)?.toInt() ?? 0,
      totalCompletedConsultations:
          (json['total_completed_consultations'] as num?)?.toInt() ?? 0,
      lastUpdateTimestamp: json['last_update_timestamp'] != null
          ? DateTime.tryParse(json['last_update_timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'total_queues': totalQueues,
      'current_queue_number': currentQueueNumber,
      'queue_process_status': queueProcessStatus.dbValue,
      'average_wait_time': averageWaitTime,
      'total_registered_patients': totalRegisteredPatients,
      'total_daily_visitors': totalDailyVisitors,
      'daily_appointments_count': dailyAppointmentsCount,
      'cancelled_appointments_count': cancelledAppointmentsCount,
      'facility_status': facilityStatus.dbValue,
      'total_completed_consultations': totalCompletedConsultations,
    };
  }

  ClinicOperationsInternalModel copyWith({
    String? clinicId,
    String? clinicName,
    int? totalQueues,
    int? currentQueueNumber,
    QueueProcessStatus? queueProcessStatus,
    int? averageWaitTime,
    int? totalRegisteredPatients,
    int? totalDailyVisitors,
    int? totalDoctorsAvailable,
    int? activeRoomsCount,
    int? availableRoomsCount,
    int? dailyAppointmentsCount,
    int? cancelledAppointmentsCount,
    List<String>? serviceTypes,
    FacilityOperatingStatus? facilityStatus,
    int? staffOnDutyCount,
    int? totalCompletedConsultations,
    DateTime? lastUpdateTimestamp,
  }) {
    return ClinicOperationsInternalModel(
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      totalQueues: totalQueues ?? this.totalQueues,
      currentQueueNumber: currentQueueNumber ?? this.currentQueueNumber,
      queueProcessStatus: queueProcessStatus ?? this.queueProcessStatus,
      averageWaitTime: averageWaitTime ?? this.averageWaitTime,
      totalRegisteredPatients:
          totalRegisteredPatients ?? this.totalRegisteredPatients,
      totalDailyVisitors: totalDailyVisitors ?? this.totalDailyVisitors,
      totalDoctorsAvailable:
          totalDoctorsAvailable ?? this.totalDoctorsAvailable,
      activeRoomsCount: activeRoomsCount ?? this.activeRoomsCount,
      availableRoomsCount: availableRoomsCount ?? this.availableRoomsCount,
      dailyAppointmentsCount:
          dailyAppointmentsCount ?? this.dailyAppointmentsCount,
      cancelledAppointmentsCount:
          cancelledAppointmentsCount ?? this.cancelledAppointmentsCount,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      facilityStatus: facilityStatus ?? this.facilityStatus,
      staffOnDutyCount: staffOnDutyCount ?? this.staffOnDutyCount,
      totalCompletedConsultations:
          totalCompletedConsultations ?? this.totalCompletedConsultations,
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp,
    );
  }
}

class AvailableDoctorPublicInfo {
  const AvailableDoctorPublicInfo({
    required this.name,
    this.title,
    this.specialization,
  });

  final String name;
  final String? title;
  final String? specialization;

  factory AvailableDoctorPublicInfo.fromJson(Map<String, dynamic> json) {
    return AvailableDoctorPublicInfo(
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'Dokter',
      title: json['title'] as String? ?? json['title_degree'] as String?,
      specialization: json['specialization'] as String?,
    );
  }
}

class ClinicOperationsPublicModel {
  const ClinicOperationsPublicModel({
    required this.clinicId,
    this.clinicName,
    this.serviceTypes = const [],
    this.currentQueueNumber = 0,
    this.estimatedWaitTime = 0,
    this.availableDoctors = const [],
    this.nextAvailableSlot,
    this.clinicStatus = 'closed',
    this.todayOperationalHours,
    this.locationCoordinates,
    this.contactNumber,
    this.lastUpdateTimestamp,
  });

  final String clinicId;
  final String? clinicName;
  final List<String> serviceTypes;
  final int currentQueueNumber;
  final int estimatedWaitTime; // menit
  final List<AvailableDoctorPublicInfo> availableDoctors;
  final DateTime? nextAvailableSlot; // SELALU null di tahap ini
  final String clinicStatus; // 'open' | 'closed'
  final Map<String, dynamic>? todayOperationalHours;
  final Map<String, dynamic>? locationCoordinates; // {latitude, longitude}
  final String? contactNumber;
  final DateTime? lastUpdateTimestamp;

  factory ClinicOperationsPublicModel.fromJson(Map<String, dynamic> json) {
    return ClinicOperationsPublicModel(
      clinicId: json['clinic_id'] as String,
      clinicName: json['clinic_name'] as String?,
      serviceTypes: json['service_types'] != null
          ? (json['service_types'] as List).map((e) => e.toString()).toList()
          : const [],
      currentQueueNumber: (json['current_queue_number'] as num?)?.toInt() ?? 0,
      estimatedWaitTime: (json['estimated_wait_time'] as num?)?.toInt() ?? 0,
      availableDoctors: json['available_doctors'] != null
          ? (json['available_doctors'] as List)
              .map((e) =>
                  AvailableDoctorPublicInfo.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      nextAvailableSlot: json['next_available_slot'] != null
          ? DateTime.tryParse(json['next_available_slot'] as String)
          : null,
      clinicStatus: json['clinic_status'] as String? ?? 'closed',
      todayOperationalHours: json['today_operational_hours'] != null
          ? Map<String, dynamic>.from(json['today_operational_hours'] as Map)
          : null,
      locationCoordinates: json['location_coordinates'] != null
          ? Map<String, dynamic>.from(json['location_coordinates'] as Map)
          : null,
      contactNumber: json['contact_number'] as String?,
      lastUpdateTimestamp: json['last_update_timestamp'] != null
          ? DateTime.tryParse(json['last_update_timestamp'] as String)
          : null,
    );
  }
}
