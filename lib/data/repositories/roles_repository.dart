import '../models.dart';

@Deprecated('Access is governed by clinic_members and RLS policies.')
abstract class RolesRepository {
  Future<List<RoleItem>> fetchRoles();
  Future<void> updateRolePermission(
      {required String role,
      required String permissionKey,
      required bool canView,
      required bool canEdit});
}

@Deprecated('Do not write legacy role_permissions; use clinic_members.')
class SupabaseRolesRepository implements RolesRepository {
  SupabaseRolesRepository({Object? client});

  @override
  Future<List<RoleItem>> fetchRoles() => Future.error(UnsupportedError(
        'Legacy role permissions are disabled. Access is derived from clinic_members.',
      ));

  @override
  Future<void> updateRolePermission(
          {required String role,
          required String permissionKey,
          required bool canView,
          required bool canEdit}) =>
      Future.error(UnsupportedError(
        'Role permissions are managed by the active clinic membership contract.',
      ));
}
