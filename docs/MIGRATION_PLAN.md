# Prometheon Clinic OS - Supabase Migration & Data Mapping Plan

This document defines the complete architectural migration plan for converting the static mock-based Prometheon Clinic OS into a live, production-ready healthcare operations platform powered by Supabase.

---

## 1. Data Points & Domain Models Mapping

| Existing Model | Supabase Table / View / RPC | Key Columns & Notes |
|---|---|---|
| `Facility` | `facilities` | `id`, `name`, `address`, `phone`, `email`, `operating_hours`, `currency` (default IDR), `timezone` (Asia/Jakarta) |
| `UserProfile` | `profiles` | `id` (FK `auth.users.id`), `facility_id`, `full_name`, `role` (`'admin' \| 'perawat'`), `is_active`, `phone` |
| `Appointment` | `appointments` | `id`, `facility_id`, `reference` (`APT-yymmdd-nnn`), `patient_id`, `doctor_id`, `service_id`, `room_id`, `starts_at`, `duration_min`, `source`, `payment_status`, `status` (lifecycle enum), `notes`, `created_by` |
| `Screening` | `screening_sessions` | `id`, `facility_id`, `reference` (`SCR-yymmdd-nnn`), `appointment_id`, `intake_id`, `completion_pct`, `priority`, `status`, `reviewer_id`, `red_flag`, `submitted_at` |
| `ClinicalIntake` | `clinical_intakes` & `intake_answers` | `id`, `appointment_id`, `data_source`, `author_id`, `primary_complaint`, `symptom_category`, `symptom_duration`, `onset`, `medical_history`, `medication_allergies` |
| `Triage` | `triage_assessments`, `triage_status_history`, `vitals` | `id`, `screening_id`, `bp_sys`, `bp_dia`, `hr`, `spo2`, `temp`, `rr`, `disposition`, `assessed_by` |
| `Doctor` | `doctors` | `id`, `facility_id`, `profile_id`, `full_name`, `specialty`, `registration_no`, `status` (`'available' \| 'in_consultation' \| 'on_break' \| 'unavailable'`), `work_start`, `work_end` |
| `RoomItem` | `rooms` | `id`, `facility_id`, `code`, `type`, `status` (`'available' \| 'occupied' \| 'reserved' \| 'maintenance'`), `note`, `floor`, `maintenance_until` |
| `PatientRecord` | `patients` | `id`, `facility_id`, `global_patient_id` (`PT-xxxxxx`), `mrn`, `full_name`, `dob`, `phone`, `registration_status`, `last_visit_at`, `is_deleted` |
| `ServiceItem` | `services` & `doctor_services` | `id`, `facility_id`, `name`, `category`, `duration_min`, `price` (bigint IDR), `status` |
| `ConsultationItem` | `consultations` | `id`, `facility_id`, `reference` (`CON-yymmdd-nnn`), `appointment_id`, `doctor_id`, `type`, `start_time`, `status` |
| `Invoice` | `invoices`, `payment_events`, `refund_requests` | `id`, `facility_id`, `reference` (`INV-xxxxx`), `appointment_id`, `patient_id`, `service_name`, `amount`, `payment_method`, `status` |
| `NotificationItem` | `notifications` & `notification_deliveries` | `id`, `facility_id`, `reference` (`NTF-xxxxx`), `title`, `body`, `category`, `priority`, `recipient_type`, `recipient_ref`, `channels`, `status` |
| `AuditLog` | `audit_logs` | Append-only: `id`, `actor_id`, `action`, `entity`, `entity_id`, `payload` (jsonb), `created_at` |
| `RoleItem` & Permissions | `role_permissions` | `id`, `role`, `permission_key`, `can_view`, `can_create`, `can_edit`, `can_delete` |
| `ClinicProfile` & `Reviews` | `clinic_public_profile` & `reviews` | `name`, `description`, `phone`, `email`, `rating`, `reviews_count`, `is_published` |

---

## 2. Summary Strips & Aggregation Views / RPCs

- `dashboard_summary(facility_id, date)`: 6 metric cards (total appointments, today's count, pending requests, completed, available doctors, revenue today).
- `doctor_availability_stats(facility_id)`: Rostered, available, consulting, on break, unavailable.
- `room_stats(facility_id)`: Available, occupied, maintenance counts.
- `triage_stats(facility_id)`: New screenings, in review, escalated, completed, median review time.
- `notification_stats(facility_id)`: Events created, queued, delivery success %, read rate %, failed deliveries.
- `finance_summary(facility_id, month)`: Net revenue, growth %, today, outstanding, refunded, sparkline data.
- `weekly_performance(facility_id)`: Mon-Sun completed vs cancelled appointments.
- `kpi_summary(facility_id, from, to)`: Completion %, room utilization %, no-show rate %, delivery %, conversion %.
- `ops_states(facility_id)`: Derived live health status for network, scheduling, payment gateway, radiology, staff coverage, notifications.

---

## 3. UI Buttons & Mutating Actions Mapping

| UI Action / Button | Component / Sheet | Target RPC / Supabase Method |
|---|---|---|
| "Quick Action" / "Create Appointment" | `QuickActionDialog`, `AppointmentFormDialog` | `create_appointment_with_intake(...)` RPC |
| "Update Status" (Checked-in, Waiting, In Consultation, Completed, Cancelled) | `AppointmentDrawer`, `AppointmentsPage` | `update_appointment_status(id, new_status)` RPC |
| "Reassign Doctor" / "Reallocate Room" | `AppointmentDrawer` | `reassign_doctor(...)`, `reallocate_room(...)` RPCs |
| "Cancel Appointment" | `AppointmentDrawer` | `cancel_appointment(id, reason)` RPC |
| "Start Review", "Record Vitals", "Assessment", "Escalate" | `ClinicalReviewPanel`, `EmergencyDialog`, `TriagePage` | `triage_action(...)` RPCs |
| "Record Payment", "Request Refund", "Create Invoice" | `FinancePage` | `billing_action(...)` RPCs + Edge Function `payment-webhook` |
| "Send Notification" | `NotificationFormDialog`, `NotificationsPage` | `send_notification(...)` RPC |
| "Register Patient" / "Edit Patient" | `PatientsPage` | `save_patient(...)` RPC |
| "Add Doctor" / "Update Doctor Status" | `DoctorsPage` | `save_doctor(...)` RPC |
| "Add Service" / "Publish Service" | `ServicesPage` | `save_service(...)` RPC |
| "Add Room" / "Set Maintenance" | `ResourcesPage` | `save_room(...)` RPC |
| "Add Nurse / Staff User" | `PermissionsPage` (Nurses & Staff tab) | Edge Function `admin-create-user` |
| "Toggle Permission Checkbox" | `PermissionsPage` | `update_role_permissions(...)` RPC |
| "Publish Clinic Profile" / "Moderate Review" | `MarketplacePage` | `update_clinic_profile(...)`, `moderate_review(...)` RPCs |

---

## 4. Modular Repository Refactoring Architecture

Instead of one monolithic repository, `ClinicRepository` is partitioned into feature repositories:
- `AppointmentsRepository`
- `TriageRepository`
- `DoctorsRepository`
- `RoomsRepository`
- `NotificationsRepository`
- `BillingRepository`
- `PatientsRepository`
- `ServicesRepository`
- `ConsultationsRepository`
- `ReportsRepository`
- `ProfileRepository`
- `RolesRepository`

All repositories implement standard interfaces and support dual implementations (`Mock*Repository` for tests/demo mode and `Supabase*Repository` for live production).
