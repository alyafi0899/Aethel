import 'clinic_enums.dart';

class ClinicReviewManageModel {
  const ClinicReviewManageModel({
    required this.reviewId,
    required this.clinicId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.replied = false,
    this.replyBody,
    this.replyCreatedAt,
    this.hasOpenReport = false,
    this.reportDismissed = false,
  });

  final String reviewId;
  final String clinicId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final bool replied;
  final String? replyBody;
  final DateTime? replyCreatedAt;
  final bool hasOpenReport;
  final bool reportDismissed;

  factory ClinicReviewManageModel.fromJson(Map<String, dynamic> json) {
    return ClinicReviewManageModel(
      reviewId: json['review_id'] as String,
      clinicId: json['clinic_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      replied: (json['replied'] as bool?) ?? false,
      replyBody: json['reply_body'] as String?,
      replyCreatedAt: json['reply_created_at'] != null
          ? DateTime.tryParse(json['reply_created_at'] as String)
          : null,
      hasOpenReport: (json['has_open_report'] as bool?) ?? false,
      reportDismissed: (json['report_dismissed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'clinic_id': clinicId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
      'replied': replied,
      'reply_body': replyBody,
      'reply_created_at': replyCreatedAt?.toIso8601String(),
      'has_open_report': hasOpenReport,
      'report_dismissed': reportDismissed,
    };
  }
}

class ClinicReviewStatsModel {
  const ClinicReviewStatsModel({
    this.count = 0,
    this.average = 0.0,
    this.distribution = const {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
    this.last30Days = 0,
    this.replied = 0,
    this.responseRate = 0.0,
    this.unanswered = 0,
  });

  final int count;
  final double average;
  final Map<String, int> distribution;
  final int last30Days;
  final int replied;
  final double responseRate;
  final int unanswered;

  factory ClinicReviewStatsModel.fromJson(Map<String, dynamic> json) {
    final distMap = <String, int>{};
    if (json['distribution'] != null) {
      final rawMap = json['distribution'] as Map;
      rawMap.forEach((key, value) {
        distMap[key.toString()] = (value as num).toInt();
      });
    }

    return ClinicReviewStatsModel(
      count: (json['count'] as num?)?.toInt() ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      distribution: distMap,
      last30Days: (json['last_30_days'] as num?)?.toInt() ?? 0,
      replied: (json['replied'] as num?)?.toInt() ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0.0,
      unanswered: (json['unanswered'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'average': average,
      'distribution': distribution,
      'last_30_days': last30Days,
      'replied': replied,
      'response_rate': responseRate,
      'unanswered': unanswered,
    };
  }
}

class ClinicReviewReplyModel {
  const ClinicReviewReplyModel({
    required this.reviewId,
    required this.clinicId,
    required this.body,
    this.repliedBy,
    this.createdAt,
  });

  final String reviewId;
  final String clinicId;
  final String body;
  final String? repliedBy;
  final DateTime? createdAt;

  factory ClinicReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ClinicReviewReplyModel(
      reviewId: json['review_id'] as String,
      clinicId: json['clinic_id'] as String,
      body: json['body'] as String,
      repliedBy: json['replied_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'clinic_id': clinicId,
      'body': body,
    };
  }
}

class ReviewReportModel {
  const ReviewReportModel({
    required this.id,
    required this.reviewId,
    required this.clinicId,
    required this.reason,
    this.details,
    this.status = ReportStatus.open,
    this.resolutionNote,
    this.createdAt,
  });

  final String id;
  final String reviewId;
  final String clinicId;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final String? resolutionNote;
  final DateTime? createdAt;

  factory ReviewReportModel.fromJson(Map<String, dynamic> json) {
    return ReviewReportModel(
      id: json['id'] as String,
      reviewId: json['review_id'] as String,
      clinicId: json['clinic_id'] as String,
      reason: ReportReason.fromDb(json['reason'] as String?),
      details: json['details'] as String?,
      status: ReportStatus.fromDb(json['status'] as String?),
      resolutionNote: json['resolution_note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'clinic_id': clinicId,
      'reason': reason.dbValue,
      'details': details,
    };
  }
}
