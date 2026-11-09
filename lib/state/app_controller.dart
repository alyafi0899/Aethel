import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/clinic_repository.dart';
import '../data/models.dart';

/// App-wide state: loaded data, current page, appointments, search.
class AppController extends ChangeNotifier {
  AppController(this._repo) {
    load();
  }

  final ClinicRepository _repo;

  bool loading = true;
  Object? error;
  late ClinicData data;

  AppPage page = AppPage.dashboard;
  String globalSearch = '';
  int notifCount = 4;
  List<Appointment> appointments = [];

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
    appointments = [
      for (final a in appointments)
        if (a.id == id) a.copyWith(status: status) else a,
    ];
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
    notifyListeners();
    return 'Appointment $id, linked clinical intake, and screening session '
        'created. Operational notifications queued.';
  }
}
