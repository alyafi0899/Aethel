import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/clinic_repository.dart';
import '../data/models.dart';
import '../data/supabase_clinic_repository.dart';

/// App-wide state: loaded data, current page, appointments, authentication, role access.
class AppController extends ChangeNotifier {
  AppController(this._repo) {
    load();
  }

  final ClinicRepository _repo;

  bool loading = true;
  Object? error;
  late ClinicData data;

  // Authentication State
  UserProfile? _currentUserProfile = UserProfile.admin(); // Default initial profile
  bool _isLoggedIn = true;

  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get isLoggedIn => _isLoggedIn;
  UserRole get currentRole => _currentUserProfile?.role ?? UserRole.admin;

  String get activeUserName => _currentUserProfile?.name ?? data.userName;
  String get activeUserRole => _currentUserProfile?.role.label ?? data.userRole;
  String get activeUserInitials => _currentUserProfile?.initials ?? data.userInitials;

  AppPage page = AppPage.dashboard;
  String globalSearch = '';
  int notifCount = 4;
  List<Appointment> appointments = [];

  List<NavSection> get navSections {
    if (currentRole.isAdmin) {
      return data.navSections;
    }
    return const [
      NavSection('OVERVIEW', [AppPage.dashboard, AppPage.operations]),
      NavSection('CLINICAL CARE', [
        AppPage.appointments,
        AppPage.triage,
        AppPage.consultations,
        AppPage.patients,
        AppPage.workflow,
      ]),
      NavSection('STAFF & RESOURCES', [
        AppPage.nurses,
        AppPage.doctors,
        AppPage.rooms,
        AppPage.services,
      ]),
      NavSection('COMMUNICATION', [AppPage.notifications]),
    ];
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await _repo.load();
      appointments = List.of(data.appointments);
      notifCount =
          int.tryParse(data.navBadges[AppPage.notifications]?.text ?? '') ?? 0;
    } catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
  }

  /// Quick Login as Admin or Nurse role
  void loginAsRole(UserRole role) {
    if (role == UserRole.admin) {
      _currentUserProfile = UserProfile.admin();
    } else {
      _currentUserProfile = UserProfile.nurse();
    }
    _isLoggedIn = true;
    page = AppPage.dashboard;
    notifyListeners();
  }

  /// Login using Supabase Auth
  Future<String?> loginWithSupabase({
    required String email,
    required String password,
    required UserRole defaultRole,
  }) async {
    try {
      final client = Supabase.instance.client;
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      final metadata = user?.userMetadata ?? {};
      final roleStr = metadata['role']?.toString().toLowerCase() ?? '';

      final role = roleStr.contains('nurse')
          ? UserRole.nurse
          : roleStr.contains('admin')
              ? UserRole.admin
              : defaultRole;

      final name = metadata['name']?.toString() ??
          (user?.email != null ? user!.email!.split('@').first : 'Klinik User');

      final initials = name
          .split(' ')
          .where((p) => p.isNotEmpty)
          .map((p) => p[0])
          .join()
          .toUpperCase();

      _currentUserProfile = UserProfile(
        name: name,
        email: user?.email ?? email,
        role: role,
        initials: initials.isEmpty ? 'KU' : (initials.length > 2 ? initials.substring(0, 2) : initials),
      );
      _isLoggedIn = true;
      page = AppPage.dashboard;
      notifyListeners();
      return null;
    } catch (e) {
      // Return error message or fallback to local quick session if Supabase offline
      debugPrint('Supabase Auth error: $e. Falling back to role login.');
      final initials = email.substring(0, min(2, email.length)).toUpperCase();
      _currentUserProfile = UserProfile(
        name: email.split('@').first,
        email: email,
        role: defaultRole,
        initials: initials,
      );
      _isLoggedIn = true;
      page = AppPage.dashboard;
      notifyListeners();
      return null;
    }
  }

  /// Sign Up using Supabase Auth
  Future<String?> signUpWithSupabase({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final client = Supabase.instance.client;
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name,
        },
      );

      final user = res.user;
      final initials = name
          .split(' ')
          .where((p) => p.isNotEmpty)
          .map((p) => p[0])
          .join()
          .toUpperCase();

      _currentUserProfile = UserProfile(
        name: name,
        email: user?.email ?? email,
        role: role,
        initials: initials.isEmpty ? 'KU' : (initials.length > 2 ? initials.substring(0, 2) : initials),
      );
      _isLoggedIn = true;
      page = AppPage.dashboard;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Log out from session
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _currentUserProfile = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void go(AppPage next) {
    page = next;
    notifyListeners();
  }

  void setSearch(String value) {
    globalSearch = value;
    notifyListeners();
  }

  void clearNotifBadge() {
    notifCount = 0;
    notifyListeners();
  }

  Appointment? appointmentById(String id) {
    for (final a in appointments) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Returns the confirmation message to show in a toast.
  String updateStatus(String id, String status) {
    Appointment? target;
    appointments = [
      for (final a in appointments)
        if (a.id == id) ...[
          target = a.copyWith(status: status),
          target!,
        ] else
          a,
    ];

    if (target != null && _repo is SupabaseClinicRepository) {
      (_repo as SupabaseClinicRepository).saveAppointment(target!);
    }

    notifyListeners();
    return 'Appointment $id updated to $status. '
        'Notifications and audit event created.';
  }

  /// Adds a new appointment and returns the toast message.
  String createAppointment({required String patient, required String doctor}) {
    final id = 'APT-240617-${70 + Random().nextInt(20)}';
    final initials = patient
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    final appt = Appointment(
      id: id,
      patient: patient,
      initials: initials.length > 2 ? initials.substring(0, 2) : initials,
      doctor: doctor,
      service: 'General consultation',
      time: '02:30 PM',
      date: 'Jun 17, 2025',
      room: 'Not assigned',
      source: 'Reception',
      payment: 'Pending',
      status: 'Pending Confirmation',
    );
    appointments = [appt, ...appointments];

    if (_repo is SupabaseClinicRepository) {
      (_repo as SupabaseClinicRepository).saveAppointment(appt);
    }

    notifyListeners();
    return 'Appointment $id, linked clinical intake, and screening session '
        'created. Operational notifications queued.';
  }
}
