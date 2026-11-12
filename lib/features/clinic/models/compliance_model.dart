import 'clinic_enums.dart';

class ClinicAlertModel {
  const ClinicAlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.dueDate,
    required this.refId,
  });

  final String id;
  final String
      type; // sio_expiring|sio_expired|str_expiring|str_expired|sip_expiring|sip_expired
  final AlertSeverity severity;
  final String message;
  final DateTime? dueDate;
  final String refId;

  factory ClinicAlertModel.fromJson(Map<String, dynamic> json) {
    return ClinicAlertModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: AlertSeverity.fromDb(json['severity'] as String?),
      message: json['message'] as String? ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      refId: json['ref_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity.dbValue,
      'message': message,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'ref_id': refId,
    };
  }
}

class ComplianceStatusModel {
  const ComplianceStatusModel({
    this.sioExpiry,
    this.sioDaysLeft,
    this.sioValid = true,
    this.publiclyVisible = false,
    this.alerts = const [],
  });

  final DateTime? sioExpiry;
  final int? sioDaysLeft;
  final bool sioValid;
  final bool publiclyVisible;
  final List<ClinicAlertModel> alerts;

  bool get hasCriticalAlerts =>
      alerts.any((a) => a.severity == AlertSeverity.critical);
  bool get hasWarningAlerts =>
      alerts.any((a) => a.severity == AlertSeverity.warning);

  factory ComplianceStatusModel.fromJson(Map<String, dynamic> json) {
    return ComplianceStatusModel(
      sioExpiry: json['sio_expiry'] != null
          ? DateTime.tryParse(json['sio_expiry'] as String)
          : null,
      sioDaysLeft: (json['sio_days_left'] as num?)?.toInt(),
      sioValid: (json['sio_valid'] as bool?) ?? true,
      publiclyVisible: (json['publicly_visible'] as bool?) ?? false,
      alerts: json['alerts'] != null
          ? (json['alerts'] as List)
              .map((e) => ClinicAlertModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sio_expiry': sioExpiry?.toIso8601String().split('T').first,
      'sio_days_left': sioDaysLeft,
      'sio_valid': sioValid,
      'publicly_visible': publiclyVisible,
      'alerts': alerts.map((a) => a.toJson()).toList(),
    };
  }
}
