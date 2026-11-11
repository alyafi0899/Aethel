import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class AppointmentsRepository {
  Future<List<Appointment>> fetchAppointments(
      {int page = 1, int pageSize = 25, String? statusFilter});
  Future<void> updateStatus(String appointmentId, String newStatus);
  Future<void> createAppointment(
      {required String patientName,
      String? doctorId,
      String? serviceId,
      String? complaint});
  Future<void> reassignDoctor(String appointmentId, String doctorId);
  Future<void> reallocateRoom(String appointmentId, String roomId);
  Future<void> cancelAppointment(String appointmentId, String reason);
}

class SupabaseAppointmentsRepository implements AppointmentsRepository {
  SupabaseAppointmentsRepository({SupabaseClient? client})
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
  Future<List<Appointment>> fetchAppointments(
      {int page = 1, int pageSize = 25, String? statusFilter}) async {
    final client = _client;
    if (client == null) return MockData.appointments;

    try {
      final fromIndex = (page - 1) * pageSize;
      final toIndex = fromIndex + pageSize - 1;

      var query = client.from('appointments').select();
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'All') {
        query =
            query.eq('status', statusFilter.toLowerCase().replaceAll(' ', '_'));
      }

      final response = await query
          .order('starts_at', ascending: false)
          .range(fromIndex, toIndex);
      if ((response as List).isEmpty) return MockData.appointments;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Appointment(
          id: map['id']?.toString() ?? '',
          patient: map['patient_name']?.toString() ??
              map['patient']?.toString() ??
              'Pasien',
          initials: map['initials']?.toString() ?? 'PT',
          doctor: map['doctor_name']?.toString() ??
              map['doctor']?.toString() ??
              'Unassigned',
          service: map['service']?.toString() ?? 'General consultation',
          time: map['starts_at'] != null
              ? map['starts_at'].toString().substring(11, 16)
              : '09:00 AM',
          date: map['starts_at'] != null
              ? map['starts_at'].toString().substring(0, 10)
              : '2025-06-17',
          room: map['room']?.toString() ?? 'Not assigned',
          source: map['source']?.toString() ?? 'Reception',
          payment: map['payment_status']?.toString() ?? 'Pending',
          status: map['status']?.toString() ?? 'Pending Confirmation',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseAppointmentsRepository fetch error: $e');
      return MockData.appointments;
    }
  }

  @override
  Future<void> updateStatus(String appointmentId, String newStatus) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('update_appointment_status', params: {
        'p_appointment_id': appointmentId,
        'p_new_status': newStatus.toLowerCase().replaceAll(' ', '_'),
      });
    } catch (e) {
      debugPrint('updateStatus RPC error: $e');
    }
  }

  @override
  Future<void> createAppointment(
      {required String patientName,
      String? doctorId,
      String? serviceId,
      String? complaint}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.rpc('create_appointment_with_intake', params: {
        'p_patient_name': patientName,
        'p_doctor_id': doctorId,
        'p_service_id': serviceId,
        'p_primary_complaint': complaint ?? 'General consultation',
      });
    } catch (e) {
      debugPrint('createAppointment RPC error: $e');
    }
  }

  @override
  Future<void> reassignDoctor(String appointmentId, String doctorId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .from('appointments')
          .update({'doctor_id': doctorId}).eq('id', appointmentId);
    } catch (e) {
      debugPrint('reassignDoctor error: $e');
    }
  }

  @override
  Future<void> reallocateRoom(String appointmentId, String roomId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .from('appointments')
          .update({'room_id': roomId}).eq('id', appointmentId);
    } catch (e) {
      debugPrint('reallocateRoom error: $e');
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    await updateStatus(appointmentId, 'cancelled');
  }
}
