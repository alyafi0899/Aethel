import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'clinic_repository.dart';
import 'mock_data.dart';
import 'models.dart';

/// Repository connected to Supabase for data persistence and live sync.
/// Falls back gracefully to baseline data if Supabase tables are empty or not yet created.
class SupabaseClinicRepository implements ClinicRepository {
  SupabaseClinicRepository({SupabaseClient? client})
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
  Future<ClinicData> load() async {
    final baseSnapshot = MockData.snapshot();
    final client = _client;

    if (client == null) {
      return baseSnapshot;
    }

    try {
      final appointments = await _fetchAppointments(baseSnapshot.appointments);
      final screenings = await _fetchScreenings(baseSnapshot.screenings);
      final doctors = await _fetchDoctors(baseSnapshot.doctors);
      final patients = await _fetchPatients(baseSnapshot.patients);

      return ClinicData(
        facilityName: baseSnapshot.facilityName,
        userName: baseSnapshot.userName,
        userInitials: baseSnapshot.userInitials,
        userRole: baseSnapshot.userRole,
        todayLabel: baseSnapshot.todayLabel,
        todayShort: baseSnapshot.todayShort,
        totalAppointments: appointments.length,
        navSections: baseSnapshot.navSections,
        navBadges: {
          ...baseSnapshot.navBadges,
          AppPage.appointments: NavBadge('${appointments.length}'),
        },
        metrics: baseSnapshot.metrics,
        appointments: appointments,
        screenings: screenings,
        doctors: doctors,
        rooms: baseSnapshot.rooms,
        notifications: baseSnapshot.notifications,
        invoices: baseSnapshot.invoices,
        patients: patients,
        services: baseSnapshot.services,
        consultations: baseSnapshot.consultations,
        activity: baseSnapshot.activity,
        availability: baseSnapshot.availability,
        appointmentSummary: baseSnapshot.appointmentSummary,
        roomStats: baseSnapshot.roomStats,
        resourceStats: baseSnapshot.resourceStats,
        notificationStats: baseSnapshot.notificationStats,
        triageStats: baseSnapshot.triageStats,
        consultStats: baseSnapshot.consultStats,
        finance: baseSnapshot.finance,
        weekly: baseSnapshot.weekly,
        kpis: baseSnapshot.kpis,
        opsStates: baseSnapshot.opsStates,
        roles: baseSnapshot.roles,
        permissionNames: baseSnapshot.permissionNames,
        profile: baseSnapshot.profile,
      );
    } catch (e) {
      debugPrint('SupabaseClinicRepository: using fallback baseline data due to: $e');
      return baseSnapshot;
    }
  }

  Future<List<Appointment>> _fetchAppointments(List<Appointment> fallback) async {
    try {
      final response = await _client!.from('appointments').select();
      if (response.isEmpty) return fallback;
      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Appointment(
          id: map['id']?.toString() ?? '',
          patient: map['patient']?.toString() ?? '',
          initials: map['initials']?.toString() ?? '',
          doctor: map['doctor']?.toString() ?? '',
          service: map['service']?.toString() ?? '',
          time: map['time']?.toString() ?? '',
          date: map['date']?.toString() ?? '',
          room: map['room']?.toString() ?? '',
          source: map['source']?.toString() ?? '',
          payment: map['payment']?.toString() ?? '',
          status: map['status']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return fallback;
    }
  }

  Future<List<Screening>> _fetchScreenings(List<Screening> fallback) async {
    try {
      final response = await _client!.from('screenings').select();
      if (response.isEmpty) return fallback;
      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Screening(
          id: map['id']?.toString() ?? '',
          appointment: map['appointment']?.toString() ?? '',
          patient: map['patient']?.toString() ?? '',
          initials: map['initials']?.toString() ?? '',
          complaint: map['complaint']?.toString() ?? '',
          duration: map['duration']?.toString() ?? '',
          completion: (map['completion'] as num?)?.toInt() ?? 100,
          priority: map['priority']?.toString() ?? 'Routine',
          reviewer: map['reviewer']?.toString() ?? 'Unassigned',
          submitted: map['submitted']?.toString() ?? '',
          status: map['status']?.toString() ?? 'New Screening',
          source: map['source']?.toString() ?? '',
          redFlag: map['red_flag'] == true || map['redFlag'] == true,
        );
      }).toList();
    } catch (_) {
      return fallback;
    }
  }

  Future<List<Doctor>> _fetchDoctors(List<Doctor> fallback) async {
    try {
      final response = await _client!.from('doctors').select();
      if (response.isEmpty) return fallback;
      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Doctor(
          initials: map['initials']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          specialty: map['specialty']?.toString() ?? '',
          registration: map['registration']?.toString() ?? '',
          status: map['status']?.toString() ?? 'Available',
          todayCount: (map['today_count'] as num?)?.toInt() ?? 0,
          tone: badgeTone(map['status']?.toString() ?? ''),
        );
      }).toList();
    } catch (_) {
      return fallback;
    }
  }

  Future<List<PatientRecord>> _fetchPatients(List<PatientRecord> fallback) async {
    try {
      final response = await _client!.from('patients').select();
      if (response.isEmpty) return fallback;
      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return PatientRecord(
          initials: map['initials']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          globalId: map['global_id']?.toString() ?? map['id']?.toString() ?? '',
          mrn: map['mrn']?.toString() ?? '',
          registration: map['registration']?.toString() ?? 'Registered',
          lastVisit: map['last_visit']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return fallback;
    }
  }

  /// Pushes an updated appointment status to Supabase if connected
  Future<void> saveAppointment(Appointment appt) async {
    if (_client == null) return;
    try {
      await _client.from('appointments').upsert({
        'id': appt.id,
        'patient': appt.patient,
        'initials': appt.initials,
        'doctor': appt.doctor,
        'service': appt.service,
        'time': appt.time,
        'date': appt.date,
        'room': appt.room,
        'source': appt.source,
        'payment': appt.payment,
        'status': appt.status,
      });
    } catch (e) {
      debugPrint('Supabase saveAppointment error: $e');
    }
  }
}
