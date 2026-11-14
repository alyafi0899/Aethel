import 'package:flutter/foundation.dart';

import '../../../domain/staff_access.dart';
import '../../clinic/models/clinic_member_model.dart';

class CurrentStaffController extends ChangeNotifier {
  StaffAccess? _access;

  StaffAccess? get access => _access;
  bool get loading => false;
  bool get canViewClinical => _access?.canViewClinical ?? false;
  bool get canActAsDoctor => _access?.canActAsDoctor ?? false;
  bool get canManageBilling => _access?.canManageBilling ?? false;
  bool get canReceiveQueue => _access?.canReceiveQueue ?? false;
  bool get canRecordTriage => _access?.canRecordTriage ?? false;
  String? get clinicId => _access?.clinicId;

  void syncMembership(ClinicMemberModel? membership) {
    final next = membership == null
        ? null
        : StaffAccess(
            clinicId: membership.clinicId,
            userId: membership.userId,
            role: membership.role.dbValue,
            clinicalAccess: membership.clinicalAccess,
          );
    if (_access?.clinicId == next?.clinicId &&
        _access?.userId == next?.userId &&
        _access?.role == next?.role &&
        _access?.clinicalAccess == next?.clinicalAccess) {
      return;
    }
    _access = next;
    notifyListeners();
  }
}
