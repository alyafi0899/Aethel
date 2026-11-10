import 'package:flutter/material.dart';

import '../core/theme/clinic_colors.dart';

enum UserRole {
  admin('Clinic Administrator', 'Full administrative & operational access', 'EC', Tone.blue),
  nurse('Charge Nurse', 'Clinical triage, patient care & operations access', 'RN', Tone.teal);

  const UserRole(this.label, this.description, this.defaultInitials, this.tone);
  final String label;
  final String description;
  final String defaultInitials;
  final Tone tone;

  bool get isAdmin => this == UserRole.admin;
  bool get isNurse => this == UserRole.nurse;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
  });

  final String name;
  final String email;
  final UserRole role;
  final String initials;

  factory UserProfile.admin() => const UserProfile(
        name: 'Elena Cruz',
        email: 'admin@prometheon.health',
        role: UserRole.admin,
        initials: 'EC',
      );

  factory UserProfile.nurse() => const UserProfile(
        name: 'Nurse Olivia Park',
        email: 'nurse.park@prometheon.health',
        role: UserRole.nurse,
        initials: 'OP',
      );
}

/// Every page of the app. Add a value here + a case in `AppShell` to add a page.
enum AppPage {
  dashboard('Dashboard', Icons.grid_view_rounded),
  operations('Operations Overview', Icons.monitor_heart_outlined),
  appointments('Appointments', Icons.calendar_today_outlined),
  triage('Triage & Screening', Icons.verified_user_outlined),
  consultations('Consultations', Icons.videocam_outlined),
  patients('Patients', Icons.groups_outlined),
  workflow('Clinical Workflow', Icons.timeline),
  doctors('Doctors', Icons.medical_services_outlined),
  nurses('Nurses & Staff', Icons.local_hospital_outlined),
  membership('Facility Membership', Icons.apartment_outlined),
  services('Services', Icons.health_and_safety_outlined),
  rooms('Rooms & Resources', Icons.meeting_room_outlined),
  scheduling('Scheduling', Icons.schedule),
  publicProfile('Public Profile', Icons.storefront_outlined),
  reviews('Ratings & Reviews', Icons.star_outline_rounded),
  billing('Billing & Payments', Icons.account_balance_wallet_outlined),
  reports('Reports', Icons.monitor_heart_outlined),
  notifications('Notifications', Icons.notifications_none_rounded),
  roles('Roles & Permissions', Icons.verified_user_outlined),
  settings('Settings', Icons.settings_outlined);

  const AppPage(this.label, this.icon);
  final String label;
  final IconData icon;
}

class NavSection {
  const NavSection(this.title, this.pages);
  final String title;
  final List<AppPage> pages;
}

class NavBadge {
  const NavBadge(this.text, {this.alert = false});
  final String text;
  final bool alert;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patient,
    required this.initials,
    required this.doctor,
    required this.service,
    required this.time,
    required this.date,
    required this.room,
    required this.source,
    required this.payment,
    required this.status,
  });

  final String id,
      patient,
      initials,
      doctor,
      service,
      time,
      date,
      room,
      source,
      payment,
      status;

  Appointment copyWith({String? status}) => Appointment(
    id: id,
    patient: patient,
    initials: initials,
    doctor: doctor,
    service: service,
    time: time,
    date: date,
    room: room,
    source: source,
    payment: payment,
    status: status ?? this.status,
  );
}

class Screening {
  const Screening({
    required this.id,
    required this.appointment,
    required this.patient,
    required this.initials,
    required this.complaint,
    required this.duration,
    required this.completion,
    required this.priority,
    required this.reviewer,
    required this.submitted,
    required this.status,
    required this.source,
    required this.redFlag,
  });

  final String id,
      appointment,
      patient,
      initials,
      complaint,
      duration,
      priority,
      reviewer,
      submitted,
      status,
      source;
  final int completion;
  final bool redFlag;
}

class Doctor {
  const Doctor({
    required this.initials,
    required this.name,
    required this.specialty,
    required this.registration,
    required this.status,
    required this.todayCount,
    required this.tone,
  });

  final String initials, name, specialty, registration, status;
  final int todayCount;
  final Tone tone;
}

class RoomItem {
  const RoomItem(this.code, this.type, this.status, this.note);
  final String code, type, status, note;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.recipient,
    required this.category,
    required this.delivery,
    required this.read,
    required this.sentAt,
  });
  final String id, title, recipient, category, delivery, read, sentAt;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.date,
    required this.patient,
    required this.appointmentId,
    required this.service,
    required this.amount,
    required this.method,
    required this.status,
  });
  final String id, date, patient, appointmentId, service, method, status;
  final double amount;
}

class PatientRecord {
  const PatientRecord({
    required this.initials,
    required this.name,
    required this.globalId,
    required this.mrn,
    required this.registration,
    required this.lastVisit,
  });
  final String initials, name, globalId, mrn, registration, lastVisit;
}

class ServiceItem {
  const ServiceItem({
    required this.name,
    required this.category,
    required this.duration,
    required this.price,
    required this.status,
    required this.doctors,
  });
  final String name, category, duration, price, status, doctors;
}

class ConsultationItem {
  const ConsultationItem({
    required this.id,
    required this.appointmentId,
    required this.patient,
    required this.doctor,
    required this.type,
    required this.startTime,
    required this.status,
  });
  final String id, appointmentId, patient, doctor, type, startTime, status;
}

class Metric {
  const Metric({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.tone,
    required this.target,
  });
  final String label, value, sub;
  final IconData icon;
  final Tone tone;
  final AppPage target;
}

/// "Big number + caption" tile used by many summary strips.
class StatTile {
  const StatTile(this.value, this.label, this.tone, [this.icon]);
  final String value, label;
  final Tone tone;
  final IconData? icon;
}

class ActivityItem {
  const ActivityItem(this.icon, this.title, this.subtitle, this.time);
  final IconData icon;
  final String title, subtitle, time;
}

class Kpi {
  const Kpi(
    this.label,
    this.value,
    this.delta, {
    this.goodWhenNegative = false,
  });
  final String label, value, delta;
  final bool goodWhenNegative;
}

class OpsState {
  const OpsState(this.title, this.status, this.detail, this.tone);
  final String title, status, detail;
  final Tone tone;
}

class RoleItem {
  const RoleItem(this.name, this.members, this.icon);
  final String name;
  final int members;
  final IconData icon;
}

class DoctorAvailability {
  const DoctorAvailability({
    required this.rostered,
    required this.available,
    required this.consulting,
    required this.onBreak,
    required this.unavailable,
  });
  final int rostered, available, consulting, onBreak, unavailable;
}

class FinanceSummary {
  const FinanceSummary({
    required this.netRevenue,
    required this.growth,
    required this.today,
    required this.outstanding,
    required this.refunded,
    required this.spark,
  });
  final String netRevenue, growth, today, outstanding, refunded;
  final List<double> spark;
}

class WeeklyBar {
  const WeeklyBar(this.day, this.completed, this.cancelled);
  final String day;
  final double completed, cancelled; // 0..100
}

class ClinicProfile {
  const ClinicProfile({
    required this.name,
    required this.description,
    required this.phone,
    required this.email,
    required this.completeness,
    required this.rating,
    required this.reviews,
  });
  final String name, description, phone, email, rating;
  final int completeness, reviews;
}

/// The complete data set the UI renders. A real backend repository only has
/// to build one of these (see `ClinicRepository`).
class ClinicData {
  const ClinicData({
    required this.facilityName,
    required this.userName,
    required this.userInitials,
    required this.userRole,
    required this.todayLabel,
    required this.todayShort,
    required this.navSections,
    required this.navBadges,
    required this.metrics,
    required this.appointments,
    required this.screenings,
    required this.doctors,
    required this.rooms,
    required this.notifications,
    required this.invoices,
    required this.patients,
    required this.services,
    required this.consultations,
    required this.activity,
    required this.availability,
    required this.appointmentSummary,
    required this.roomStats,
    required this.resourceStats,
    required this.notificationStats,
    required this.triageStats,
    required this.consultStats,
    required this.finance,
    required this.weekly,
    required this.kpis,
    required this.opsStates,
    required this.roles,
    required this.permissionNames,
    required this.profile,
    required this.totalAppointments,
  });

  final String facilityName, userName, userInitials, userRole;
  final String todayLabel, todayShort;
  final List<NavSection> navSections;
  final Map<AppPage, NavBadge> navBadges;
  final List<Metric> metrics;
  final List<Appointment> appointments;
  final List<Screening> screenings;
  final List<Doctor> doctors;
  final List<RoomItem> rooms;
  final List<NotificationItem> notifications;
  final List<Invoice> invoices;
  final List<PatientRecord> patients;
  final List<ServiceItem> services;
  final List<ConsultationItem> consultations;
  final List<ActivityItem> activity;
  final DoctorAvailability availability;
  final List<StatTile> appointmentSummary;
  final List<StatTile> roomStats;
  final List<StatTile> resourceStats;
  final List<StatTile> notificationStats;
  final List<StatTile> triageStats;
  final List<StatTile> consultStats;
  final FinanceSummary finance;
  final List<WeeklyBar> weekly;
  final List<Kpi> kpis;
  final List<OpsState> opsStates;
  final List<RoleItem> roles;
  final List<String> permissionNames;
  final ClinicProfile profile;
  final int totalAppointments;
}

/// Maps a status string to a colour tone. Edit the patterns to re-theme
/// every badge in the app at once.
Tone badgeTone(String value) {
  bool has(String pattern) => RegExp(pattern).hasMatch(value);
  if (has('Paid|Completed|Available|Confirmed|Delivered|Published|Active')) {
    return Tone.green;
  }
  if (has('Pending|Waiting|Break|Processing|Scheduled')) return Tone.amber;
  if (has('Consultation|Checked|Queued|Online')) return Tone.blue;
  if (has('Failed|Cancelled|Unavailable|Maintenance|Critical')) return Tone.red;
  return Tone.gray;
}
