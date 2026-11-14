class StaffAccess {
  const StaffAccess({
    required this.clinicId,
    required this.userId,
    required this.role,
    required this.clinicalAccess,
  });

  final String clinicId;
  final String userId;
  final String role;
  final bool clinicalAccess;

  bool get canViewClinical =>
      role == 'doctor' || role == 'nurse' || clinicalAccess;

  bool get canActAsDoctor =>
      role == 'doctor' ||
      ((role == 'owner' || role == 'admin') && clinicalAccess);

  bool get canManageClinic => role == 'owner' || role == 'admin';

  bool get canManageBilling => canManageClinic || role == 'cashier';

  bool get canReceiveQueue =>
      canManageClinic ||
      role == 'receptionist' ||
      role == 'nurse' ||
      role == 'doctor' ||
      role == 'cashier';

  bool get canRecordTriage =>
      role == 'nurse' || role == 'doctor' || canActAsDoctor;
}
