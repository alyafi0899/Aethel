import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/feature_flags.dart';
import '../core/utils/error_mapper.dart';
import '../data/clinic_repository.dart';
import '../data/models.dart';

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
  UserProfile? _currentUserProfile;
  bool _isLoggedIn = false;

  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get isLoggedIn => _isLoggedIn;
  UserRole get currentRole => _currentUserProfile?.role ?? UserRole.admin;

  String get activeUserName => _currentUserProfile?.name ?? data.userName;
  String get activeUserRole => _currentUserProfile?.role.label ?? data.userRole;
  String get activeUserInitials =>
      _currentUserProfile?.initials ?? data.userInitials;

  AppPage page = AppPage.dashboard;
  int profileTab = 0;
  int reviewsTab = 0;
  bool focusUnansweredReviews = false;
  String globalSearch = '';
  int notifCount = 4;
  List<Appointment> appointments = [];

  List<NavSection> get navSections {
    return const [
      NavSection('RINGKASAN', [AppPage.dashboard, AppPage.operations]),
      NavSection('ALUR PASIEN', [
        AppPage.appointments,
        AppPage.triage,
        AppPage.consultations,
        AppPage.patients,
        AppPage.workflow,
      ]),
      NavSection('MANAJEMEN SDM', [
        AppPage.doctors,
        AppPage.nurses,
        AppPage.membership,
      ]),
      NavSection('LAYANAN & FASILITAS', [
        AppPage.rooms,
        AppPage.services,
        AppPage.scheduling,
      ]),
      NavSection('PROFIL PUBLIK', [AppPage.publicProfile, AppPage.reviews]),
      NavSection('KEUANGAN', [AppPage.billing, AppPage.reports]),
      NavSection('KOMUNIKASI', [AppPage.notifications]),
      NavSection('ADMINISTRASI KLINIK', [
        AppPage.clinicProfile,
        AppPage.clinicStaff,
        AppPage.clinicOperationsInternal,
        AppPage.clinicOperationsPublic,
        AppPage.clinicCompliance,
        AppPage.roles,
        AppPage.settings,
      ]),
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
    if (!kUseMockData) {
      throw StateError('Login simulasi hanya tersedia saat USE_MOCK=true.');
    }
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
        initials: initials.isEmpty
            ? 'KU'
            : (initials.length > 2 ? initials.substring(0, 2) : initials),
      );
      _isLoggedIn = true;
      page = AppPage.dashboard;
      notifyListeners();
      return null;
    } catch (e) {
      return ErrorMapper.mapError(e);
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
        initials: initials.isEmpty
            ? 'KU'
            : (initials.length > 2 ? initials.substring(0, 2) : initials),
      );
      _isLoggedIn = true;
      page = AppPage.dashboard;
      notifyListeners();
      return null;
    } catch (e) {
      return ErrorMapper.mapError(e);
    }
  }

  /// Log out from session
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _currentUserProfile = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void go(AppPage next) {
    switch (next) {
      case AppPage.clinicServices:
      case AppPage.rooms:
      case AppPage.services:
        profileTab = 1;
        next = AppPage.clinicProfile;
        break;
      case AppPage.clinicLegal:
        profileTab = 2;
        next = AppPage.clinicProfile;
        break;
      case AppPage.clinicEmr:
        profileTab = 3;
        next = AppPage.clinicProfile;
        break;
      case AppPage.clinicOperationsPublic:
        profileTab = 4;
        next = AppPage.clinicProfile;
        break;
      case AppPage.clinicCompliance:
        profileTab = 5;
        next = AppPage.clinicProfile;
        break;
      case AppPage.clinicFeedback:
        reviewsTab = 1;
        next = AppPage.clinicReviews;
        break;
      default:
        break;
    }
    page = next;
    notifyListeners();
  }

  void selectProfileTab(int index) {
    profileTab = index;
    notifyListeners();
  }

  void selectReviewsTab(int index) {
    reviewsTab = index;
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

  String updateStatus(String id, String status) {
    throw UnsupportedError(
      'Perubahan status harus dilakukan melalui alur kunjungan aktif.',
    );
  }

  String createAppointment({required String patient, required String doctor}) {
    throw UnsupportedError(
      'Pendaftaran harus dilakukan melalui alur kunjungan aktif.',
    );
  }

  Appointment? appointmentById(String id) {
    for (final a in appointments) {
      if (a.id == id) return a;
    }
    return null;
  }
}
