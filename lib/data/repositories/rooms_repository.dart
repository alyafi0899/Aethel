import '../models.dart';

@Deprecated('Use ClinicController clinic catalog repository.')
abstract class RoomsRepository {
  Future<List<RoomItem>> fetchRooms();
  Future<void> updateRoomStatus(String roomId, String newStatus,
      {String? note});
  Future<void> saveRoom(RoomItem room);
}

@Deprecated('Use clinic_facilities and the clinic catalog repository.')
class SupabaseRoomsRepository implements RoomsRepository {
  SupabaseRoomsRepository({Object? client});

  @override
  Future<List<RoomItem>> fetchRooms() => Future.error(UnsupportedError(
        'Legacy rooms API is disabled. Use the clinic facilities module.',
      ));

  @override
  Future<void> updateRoomStatus(String roomId, String newStatus,
          {String? note}) =>
      Future.error(UnsupportedError(
        'Manage facility status through the clinic catalog module.',
      ));

  @override
  Future<void> saveRoom(RoomItem room) => Future.error(UnsupportedError(
        'Manage facilities through the clinic catalog module.',
      ));
}
