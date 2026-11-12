import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_enums.dart';
import '../models/feedback_model.dart';

abstract class FeedbackRepository {
  Future<List<ClinicFeedbackPrivateModel>> fetchPrivateFeedback({
    required String clinicId,
    FeedbackStatus? statusFilter,
    FeedbackCategory? categoryFilter,
  });

  Future<ClinicFeedbackPrivateModel> updateFeedbackStatusAndNote({
    required String feedbackId,
    required String clinicId,
    required FeedbackStatus status,
    String? internalNote,
  });
}

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<ClinicFeedbackPrivateModel>> fetchPrivateFeedback({
    required String clinicId,
    FeedbackStatus? statusFilter,
    FeedbackCategory? categoryFilter,
  }) async {
    dynamic query = _client
        .from('clinic_feedback_private')
        .select()
        .eq('clinic_id', clinicId);

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.dbValue);
    }
    if (categoryFilter != null) {
      query = query.eq('category', categoryFilter.dbValue);
    }

    query = query.order('created_at', ascending: false);

    final res = await query;
    return (res as List)
        .map((e) =>
            ClinicFeedbackPrivateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClinicFeedbackPrivateModel> updateFeedbackStatusAndNote({
    required String feedbackId,
    required String clinicId,
    required FeedbackStatus status,
    String? internalNote,
  }) async {
    final res = await _client
        .from('clinic_feedback_private')
        .update({
          'status': status.dbValue,
          'internal_note': internalNote,
        })
        .eq('id', feedbackId)
        .eq('clinic_id', clinicId)
        .select()
        .single();
    return ClinicFeedbackPrivateModel.fromJson(res);
  }
}

class FakeFeedbackRepository implements FeedbackRepository {
  List<ClinicFeedbackPrivateModel> mockFeedback = [];

  @override
  Future<List<ClinicFeedbackPrivateModel>> fetchPrivateFeedback({
    required String clinicId,
    FeedbackStatus? statusFilter,
    FeedbackCategory? categoryFilter,
  }) async {
    var result = List<ClinicFeedbackPrivateModel>.from(mockFeedback);
    if (statusFilter != null) {
      result = result.where((f) => f.status == statusFilter).toList();
    }
    if (categoryFilter != null) {
      result = result.where((f) => f.category == categoryFilter).toList();
    }
    return result;
  }

  @override
  Future<ClinicFeedbackPrivateModel> updateFeedbackStatusAndNote({
    required String feedbackId,
    required String clinicId,
    required FeedbackStatus status,
    String? internalNote,
  }) async {
    final idx = mockFeedback.indexWhere((f) => f.id == feedbackId);
    if (idx != -1) {
      mockFeedback[idx] = mockFeedback[idx].copyWith(
        status: status,
        internalNote: internalNote,
      );
      return mockFeedback[idx];
    }
    throw Exception('Feedback not found');
  }
}
