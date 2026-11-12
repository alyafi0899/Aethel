import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_enums.dart';
import '../models/review_models.dart';

abstract class ReviewsRepository {
  Future<ClinicReviewStatsModel> fetchReviewStats(String clinicId);
  Future<List<ClinicReviewManageModel>> fetchReviewsManage({
    required String clinicId,
    int offset = 0,
    int limit = 20,
    int? ratingFilter,
    bool? unansweredOnly,
    String? sortBy, // 'newest' | 'highest' | 'lowest'
  });
  Future<ClinicReviewReplyModel> replyToReview({
    required String reviewId,
    required String clinicId,
    required String body,
  });
  Future<ReviewReportModel> reportReview({
    required String reviewId,
    required String clinicId,
    required ReportReason reason,
    String? details,
  });
}

class SupabaseReviewsRepository implements ReviewsRepository {
  SupabaseReviewsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ClinicReviewStatsModel> fetchReviewStats(String clinicId) async {
    final res = await _client.rpc(
      'clinic_review_stats',
      params: {'p_clinic_id': clinicId},
    );
    return ClinicReviewStatsModel.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<List<ClinicReviewManageModel>> fetchReviewsManage({
    required String clinicId,
    int offset = 0,
    int limit = 20,
    int? ratingFilter,
    bool? unansweredOnly,
    String? sortBy,
  }) async {
    dynamic query = _client
        .from('clinic_reviews_manage')
        .select()
        .eq('clinic_id', clinicId);

    if (ratingFilter != null) {
      query = query.eq('rating', ratingFilter);
    }
    if (unansweredOnly == true) {
      query = query.eq('replied', false);
    }

    if (sortBy == 'highest') {
      query = query.order('rating', ascending: false);
    } else if (sortBy == 'lowest') {
      query = query.order('rating', ascending: true);
    } else {
      query = query.order('created_at', ascending: false);
    }

    query = query.range(offset, offset + limit - 1);

    final res = await query;
    return (res as List)
        .map((e) => ClinicReviewManageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicReviewReplyModel> replyToReview({
    required String reviewId,
    required String clinicId,
    required String body,
  }) async {
    final res = await _client
        .from('clinic_review_replies')
        .insert({
          'review_id': reviewId,
          'clinic_id': clinicId,
          'body': body,
        })
        .select()
        .single();
    return ClinicReviewReplyModel.fromJson(res);
  }

  @override
  Future<ReviewReportModel> reportReview({
    required String reviewId,
    required String clinicId,
    required ReportReason reason,
    String? details,
  }) async {
    final res = await _client
        .from('review_reports')
        .insert({
          'review_id': reviewId,
          'clinic_id': clinicId,
          'reason': reason.dbValue,
          'details': details,
          'status': 'open',
        })
        .select()
        .single();
    return ReviewReportModel.fromJson(res);
  }
}

class FakeReviewsRepository implements ReviewsRepository {
  ClinicReviewStatsModel mockStats =
      const ClinicReviewStatsModel(count: 2, average: 4.5);
  List<ClinicReviewManageModel> mockReviews = [];

  @override
  Future<ClinicReviewStatsModel> fetchReviewStats(String clinicId) async =>
      mockStats;

  @override
  Future<List<ClinicReviewManageModel>> fetchReviewsManage({
    required String clinicId,
    int offset = 0,
    int limit = 20,
    int? ratingFilter,
    bool? unansweredOnly,
    String? sortBy,
  }) async =>
      mockReviews;

  @override
  Future<ClinicReviewReplyModel> replyToReview({
    required String reviewId,
    required String clinicId,
    required String body,
  }) async {
    final reply = ClinicReviewReplyModel(
      reviewId: reviewId,
      clinicId: clinicId,
      body: body,
      createdAt: DateTime.now(),
    );
    final idx = mockReviews.indexWhere((r) => r.reviewId == reviewId);
    if (idx != -1) {
      mockReviews[idx] = ClinicReviewManageModel(
        reviewId: mockReviews[idx].reviewId,
        clinicId: mockReviews[idx].clinicId,
        rating: mockReviews[idx].rating,
        comment: mockReviews[idx].comment,
        createdAt: mockReviews[idx].createdAt,
        replied: true,
        replyBody: body,
        replyCreatedAt: DateTime.now(),
        hasOpenReport: mockReviews[idx].hasOpenReport,
      );
    }
    return reply;
  }

  @override
  Future<ReviewReportModel> reportReview({
    required String reviewId,
    required String clinicId,
    required ReportReason reason,
    String? details,
  }) async {
    final report = ReviewReportModel(
      id: 'rep-1',
      reviewId: reviewId,
      clinicId: clinicId,
      reason: reason,
      details: details,
      status: ReportStatus.open,
    );
    final idx = mockReviews.indexWhere((r) => r.reviewId == reviewId);
    if (idx != -1) {
      mockReviews[idx] = ClinicReviewManageModel(
        reviewId: mockReviews[idx].reviewId,
        clinicId: mockReviews[idx].clinicId,
        rating: mockReviews[idx].rating,
        comment: mockReviews[idx].comment,
        createdAt: mockReviews[idx].createdAt,
        replied: mockReviews[idx].replied,
        replyBody: mockReviews[idx].replyBody,
        replyCreatedAt: mockReviews[idx].replyCreatedAt,
        hasOpenReport: true,
      );
    }
    return report;
  }
}
