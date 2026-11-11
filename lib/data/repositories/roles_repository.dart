import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class RolesRepository {
  Future<List<RoleItem>> fetchRoles();
  Future<void> updateRolePermission(
      {required String role,
      required String permissionKey,
      required bool canView,
      required bool canEdit});
}

class SupabaseRolesRepository implements RolesRepository {
  SupabaseRolesRepository({SupabaseClient? client})
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
  Future<List<RoleItem>> fetchRoles() async {
    final client = _client;
    final fallback = MockData.snapshot().roles;
    if (client == null) return fallback;

    try {
      final response = await client.from('role_permissions').select();
      if ((response as List).isEmpty) return fallback;
      return fallback;
    } catch (e) {
      debugPrint('SupabaseRolesRepository fetch error: $e');
      return fallback;
    }
  }

  @override
  Future<void> updateRolePermission(
      {required String role,
      required String permissionKey,
      required bool canView,
      required bool canEdit}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('role_permissions').upsert({
        'role': role.toLowerCase().contains('admin') ? 'admin' : 'perawat',
        'permission_key': permissionKey,
        'can_view': canView,
        'can_edit': canEdit,
      });
    } catch (e) {
      debugPrint('updateRolePermission error: $e');
    }
  }
}
