import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class RoomsRepository {
  Future<List<RoomItem>> fetchRooms();
  Future<void> updateRoomStatus(String roomId, String newStatus,
      {String? note});
  Future<void> saveRoom(RoomItem room);
}

class SupabaseRoomsRepository implements RoomsRepository {
  SupabaseRoomsRepository({SupabaseClient? client})
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
  Future<List<RoomItem>> fetchRooms() async {
    final client = _client;
    if (client == null) return MockData.rooms;

    try {
      final response = await client.from('rooms').select().order('code');
      if ((response as List).isEmpty) return MockData.rooms;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return RoomItem(
          map['code']?.toString() ?? 'R-00',
          map['type']?.toString() ?? 'Consultation room',
          map['status']?.toString() ?? 'Available',
          map['note']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseRoomsRepository fetch error: $e');
      return MockData.rooms;
    }
  }

  @override
  Future<void> updateRoomStatus(String roomId, String newStatus,
      {String? note}) async {
    final client = _client;
    if (client == null) return;
    try {
      final updates = <String, dynamic>{
        'status': newStatus.toLowerCase().replaceAll(' ', '_'),
      };
      if (note != null) updates['note'] = note;
      await client.from('rooms').update(updates).eq('id', roomId);
    } catch (e) {
      debugPrint('updateRoomStatus error: $e');
    }
  }

  @override
  Future<void> saveRoom(RoomItem room) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('rooms').upsert({
        'code': room.code,
        'type': room.type,
        'status': room.status.toLowerCase().replaceAll(' ', '_'),
        'note': room.note,
      });
    } catch (e) {
      debugPrint('saveRoom error: $e');
    }
  }
}
