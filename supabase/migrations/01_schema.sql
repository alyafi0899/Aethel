-- =============================================================================
-- PROMETHEON CLINIC OS - DATABASE SCHEMA (MIGRATION 01)
-- Multi-clinic ready, full healthcare operations data model with audit logging.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- -----------------------------------------------------------------------------
-- ENUMS
-- -----------------------------------------------------------------------------
CREATE TYPE app_role AS ENUM ('admin', 'perawat');
CREATE TYPE patient_registration_status AS ENUM ('registered', 'pending');
CREATE TYPE doctor_status AS ENUM ('available', 'in_consultation', 'on_break', 'unavailable');
CREATE TYPE service_status AS ENUM ('published', 'internal_only', 'draft');
CREATE TYPE room_status AS ENUM ('available', 'occupied', 'reserved', 'maintenance');
CREATE TYPE appointment_source AS ENUM ('patient_app', 'reception', 'referral', 'direct_registration');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'processing', 'failed', 'refunded');
CREATE TYPE appointment_status AS ENUM (
  'pending_confirmation',
  'confirmed',
  'awaiting_check_in',
  'checked_in',
  'waiting_for_doctor',
  'in_consultation',
  'completed',
  'cancelled'
);
CREATE TYPE intake_data_source AS ENUM ('patient_self_reported', 'receptionist_assisted', 'clinical_assisted');
CREATE TYPE triage_priority AS ENUM ('urgent', 'priority', 'routine', 'unassigned');
CREATE TYPE triage_status AS ENUM ('new_screening', 'in_review', 'escalated', 'completed');
CREATE TYPE consultation_type AS ENUM ('in_person', 'scheduled_online');
CREATE TYPE consultation_status AS ENUM ('request_received', 'doctor_accepted', 'in_consultation', 'completed');
CREATE TYPE invoice_status AS ENUM ('pending', 'processing', 'paid', 'failed', 'refunded');
CREATE TYPE notification_status AS ENUM ('draft', 'scheduled', 'queued', 'sent');
CREATE TYPE notification_recipient_type AS ENUM ('patient', 'doctor', 'staff', 'role', 'all');

-- -----------------------------------------------------------------------------
-- AUTOMATED UPDATED_AT TRIGGER FUNCTION
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- TABLES
-- -----------------------------------------------------------------------------

-- 1. Facilities
CREATE TABLE facilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  operating_hours TEXT DEFAULT '08:00 - 20:00',
  currency TEXT NOT NULL DEFAULT 'IDR',
  timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Profiles (links 1:1 with auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role app_role NOT NULL DEFAULT 'perawat',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Patients (Soft delete)
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  global_patient_id TEXT UNIQUE NOT NULL, -- e.g. PT-009821
  mrn TEXT, -- e.g. MRN-PC-20418
  full_name TEXT NOT NULL,
  dob DATE,
  phone TEXT,
  registration_status patient_registration_status NOT NULL DEFAULT 'registered',
  last_visit_at TIMESTAMPTZ,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Doctors
CREATE TABLE doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  specialty TEXT NOT NULL,
  registration_no TEXT UNIQUE NOT NULL,
  status doctor_status NOT NULL DEFAULT 'available',
  work_start TIME DEFAULT '08:00',
  work_end TIME DEFAULT '17:00',
  break_start TIME DEFAULT '12:00',
  break_end TIME DEFAULT '13:00',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Services & Doctor_Services
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  duration_min INT NOT NULL DEFAULT 30,
  price BIGINT NOT NULL DEFAULT 75000, -- Amount in IDR/currency unit
  status service_status NOT NULL DEFAULT 'published',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE doctor_services (
  doctor_id UUID REFERENCES doctors(id) ON DELETE CASCADE,
  service_id UUID REFERENCES services(id) ON DELETE CASCADE,
  PRIMARY KEY (doctor_id, service_id)
);

-- 6. Rooms
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  code TEXT NOT NULL, -- e.g. C-204
  type TEXT NOT NULL, -- e.g. Consultation room
  status room_status NOT NULL DEFAULT 'available',
  note TEXT,
  floor INT DEFAULT 1,
  maintenance_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(facility_id, code)
);

-- 7. Appointments
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  reference TEXT UNIQUE NOT NULL, -- e.g. APT-240617-048
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
  service_id UUID REFERENCES services(id) ON DELETE SET NULL,
  room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  duration_min INT NOT NULL DEFAULT 30,
  source appointment_source NOT NULL DEFAULT 'reception',
  payment_status payment_status NOT NULL DEFAULT 'pending',
  status appointment_status NOT NULL DEFAULT 'pending_confirmation',
  notes TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Clinical Intakes & Intake Answers
CREATE TABLE clinical_intakes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID UNIQUE NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  data_source intake_data_source NOT NULL DEFAULT 'patient_self_reported',
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  primary_complaint TEXT NOT NULL,
  symptom_category TEXT,
  symptom_duration TEXT,
  onset TEXT,
  additional_notes TEXT,
  medical_history TEXT,
  medication_allergies TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE intake_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intake_id UUID NOT NULL REFERENCES clinical_intakes(id) ON DELETE CASCADE,
  question_key TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Screening Sessions
CREATE TABLE screening_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  reference TEXT UNIQUE NOT NULL, -- e.g. SCR-250617-084
  appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  intake_id UUID REFERENCES clinical_intakes(id) ON DELETE CASCADE,
  completion_pct INT NOT NULL DEFAULT 0,
  priority triage_priority NOT NULL DEFAULT 'routine',
  status triage_status NOT NULL DEFAULT 'new_screening',
  reviewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  red_flag BOOLEAN NOT NULL DEFAULT FALSE,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. Triage Assessments, History & Vitals
CREATE TABLE triage_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screening_id UUID UNIQUE NOT NULL REFERENCES screening_sessions(id) ON DELETE CASCADE,
  disposition TEXT,
  notes TEXT,
  assessed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assessed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE triage_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screening_id UUID NOT NULL REFERENCES screening_sessions(id) ON DELETE CASCADE,
  previous_status triage_status,
  new_status triage_status NOT NULL,
  changed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE vitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screening_id UUID NOT NULL REFERENCES screening_sessions(id) ON DELETE CASCADE,
  bp_sys INT,
  bp_dia INT,
  hr INT,
  spo2 INT,
  temp NUMERIC(4, 1),
  rr INT,
  recorded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Consultations
CREATE TABLE consultations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  reference TEXT UNIQUE NOT NULL, -- e.g. CON-250617-81
  appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
  type consultation_type NOT NULL DEFAULT 'in_person',
  start_time TIMESTAMPTZ NOT NULL,
  status consultation_status NOT NULL DEFAULT 'request_received',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Invoices, Payment Events & Refunds
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  reference TEXT UNIQUE NOT NULL, -- e.g. INV-20481
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  service_name TEXT NOT NULL,
  amount BIGINT NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'Cash',
  status invoice_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payment_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  provider TEXT NOT NULL,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE refund_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  requested_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. Notifications & Deliveries
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  reference TEXT UNIQUE NOT NULL, -- e.g. NTF-02580
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'General',
  priority TEXT DEFAULT 'Normal',
  recipient_type notification_recipient_type NOT NULL DEFAULT 'all',
  recipient_ref TEXT,
  channels TEXT[] DEFAULT ARRAY['push'],
  status notification_status NOT NULL DEFAULT 'sent',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  channel TEXT NOT NULL,
  delivery_status TEXT NOT NULL DEFAULT 'delivered',
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
);

-- 14. Audit Logs (Append-Only)
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. Role Permissions
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  permission_key TEXT NOT NULL,
  can_view BOOLEAN NOT NULL DEFAULT TRUE,
  can_create BOOLEAN NOT NULL DEFAULT FALSE,
  can_edit BOOLEAN NOT NULL DEFAULT FALSE,
  can_delete BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE(facility_id, role, permission_key)
);

-- 16. Clinic Public Profile & Reviews
CREATE TABLE clinic_public_profile (
  facility_id UUID PRIMARY KEY REFERENCES facilities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  phone TEXT,
  email TEXT,
  rating NUMERIC(3, 1) DEFAULT 4.8,
  reviews_count INT DEFAULT 0,
  completeness_pct INT DEFAULT 90,
  is_published BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  reviewer_name TEXT NOT NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  status TEXT NOT NULL DEFAULT 'published',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. User Preferences
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  theme_mode TEXT DEFAULT 'system',
  dense_mode BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- TRIGGERS FOR UPDATED_AT
-- -----------------------------------------------------------------------------
CREATE TRIGGER tr_facilities_updated_at BEFORE UPDATE ON facilities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_doctors_updated_at BEFORE UPDATE ON doctors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_services_updated_at BEFORE UPDATE ON services FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_rooms_updated_at BEFORE UPDATE ON rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_screening_sessions_updated_at BEFORE UPDATE ON screening_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_consultations_updated_at BEFORE UPDATE ON consultations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- INDEXES (INCLUDING TRIGRAM GIN INDEXES)
-- -----------------------------------------------------------------------------
CREATE INDEX idx_patients_name_trgm ON patients USING GIN (full_name gin_trgm_ops);
CREATE INDEX idx_patients_global_id ON patients(global_patient_id);
CREATE INDEX idx_appointments_ref ON appointments(reference);
CREATE INDEX idx_appointments_facility_starts ON appointments(facility_id, starts_at);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_screenings_ref ON screenings_sessions(reference);
CREATE INDEX idx_screenings_status ON screening_sessions(status);
CREATE INDEX idx_doctors_facility ON doctors(facility_id);
CREATE INDEX idx_audit_logs_facility ON audit_logs(facility_id, created_at DESC);
