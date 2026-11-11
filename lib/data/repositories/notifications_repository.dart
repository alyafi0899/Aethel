import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> fetchNotifications();
  Future<void> sendNotification(
      {required String title, required String body, String? category});
}

class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final client = _client;
    if (client == null) return MockData.notifications;

    try {
      final response = await client
          .from('notifications')
          .select()
          .order('sent_at', ascending: false);
      if ((response as List).isEmpty) return MockData.notifications;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return NotificationItem(
          id: map['reference']?.toString() ??
              map['id']?.toString() ??
              'NTF-000',
          title: map['title']?.toString() ?? 'Pemberitahuan',
          recipient: map['recipient_ref']?.toString() ?? 'All staff',
          category: map['category']?.toString() ?? 'Operational Alert',
          delivery: map['status']?.toString() ?? 'Delivered',
          read: '100% read',
          sentAt: map['sent_at'] != null
              ? map['sent_at'].toString().substring(11, 16)
              : '10:00 AM',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseNotificationsRepository fetch error: $e');
      return MockData.notifications;
    }
  }

  @override
  Future<void> sendNotification(
      {required String title, required String body, String? category}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('send_notification', params: {
        'p_title': title,
        'p_body': body,
        'p_category': category ?? 'General',
      });
    } catch (e) {
      debugPrint('sendNotification RPC error: $e');
    }
  }
}
