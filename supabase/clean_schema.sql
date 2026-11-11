-- =============================================================================
-- PROMETHEON CLINIC OS - CLEAN EMPTY SCHEMA FOR SUPABASE SQL EDITOR
-- 100% Fail-Safe script: Copy & Paste directly into Supabase Dashboard SQL Editor.
-- Leaves all tables clean and empty with automatic user profile creation trigger.
-- =============================================================================

-- 1. DROP EXISTING TABLES & TRIGGERS (CLEAN SLATE)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user CASCADE;

DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS role_permissions CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS refund_requests CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS vitals CASCADE;
DROP TABLE IF EXISTS triage_assessments CASCADE;
DROP TABLE IF EXISTS screening_sessions CASCADE;
DROP TABLE IF EXISTS clinical_intakes CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS facilities CASCADE;

-- 2. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 3. TABLES DEFINITION

-- Facilities
CREATE TABLE facilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  operating_hours TEXT DEFAULT '08:00 - 20:00',
  currency TEXT DEFAULT 'IDR',
  timezone TEXT DEFAULT 'Asia/Jakarta',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Default Facility
INSERT INTO facilities (id, name, address, phone, email)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'Prometheon Central Clinic',
  'Jl. Sudirman No. 45, Jakarta Pusat',
  '+62 21 555 0182',
  'care@prometheon.health'
);

-- Profiles (Linked to auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'perawat', -- 'admin' or 'perawat'
  is_active BOOLEAN DEFAULT TRUE,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Patients
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  global_patient_id TEXT,
  mrn TEXT,
  full_name TEXT NOT NULL,
  dob DATE,
  phone TEXT,
  registration_status TEXT DEFAULT 'registered',
  last_visit_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Doctors
CREATE TABLE doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  specialty TEXT NOT NULL,
  registration_no TEXT,
  status TEXT DEFAULT 'available',
  work_start TIME DEFAULT '08:00',
  work_end TIME DEFAULT '17:00',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Services
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  duration_min INT DEFAULT 30,
  price BIGINT DEFAULT 75000,
  status TEXT DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rooms
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  code TEXT NOT NULL,
  type TEXT NOT NULL,
  status TEXT DEFAULT 'available',
  note TEXT,
  floor INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Appointments
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  reference TEXT,
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
  patient_name TEXT,
  initials TEXT,
  doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
  doctor_name TEXT,
  service_id UUID REFERENCES services(id) ON DELETE SET NULL,
  service TEXT DEFAULT 'General consultation',
  room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
  room TEXT DEFAULT 'Not assigned',
  time TEXT DEFAULT '09:00 AM',
  date TEXT DEFAULT 'Jun 17, 2025',
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  duration_min INT DEFAULT 30,
  source TEXT DEFAULT 'Reception',
  payment_status TEXT DEFAULT 'Pending',
  payment TEXT DEFAULT 'Pending',
  status TEXT DEFAULT 'Pending Confirmation',
  notes TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clinical Intakes
CREATE TABLE clinical_intakes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  data_source TEXT DEFAULT 'patient_self_reported',
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  primary_complaint TEXT NOT NULL,
  symptom_category TEXT,
  symptom_duration TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Screening Sessions
CREATE TABLE screening_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  reference TEXT,
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  intake_id UUID REFERENCES clinical_intakes(id) ON DELETE CASCADE,
  patient_name TEXT,
  initials TEXT,
  primary_complaint TEXT,
  duration TEXT,
  completion_pct INT DEFAULT 0,
  priority TEXT DEFAULT 'routine',
  status TEXT DEFAULT 'new_screening',
  reviewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewer_name TEXT DEFAULT 'Unassigned',
  red_flag BOOLEAN DEFAULT FALSE,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Triage Assessments
CREATE TABLE triage_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screening_id UUID REFERENCES screening_sessions(id) ON DELETE CASCADE,
  disposition TEXT,
  notes TEXT,
  assessed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assessed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vitals
CREATE TABLE vitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screening_id UUID REFERENCES screening_sessions(id) ON DELETE CASCADE,
  bp_sys INT,
  bp_dia INT,
  hr INT,
  spo2 INT,
  temp NUMERIC(4, 1),
  rr INT,
  recorded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoices
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  reference TEXT,
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
  patient_name TEXT,
  service_name TEXT NOT NULL,
  amount BIGINT NOT NULL,
  payment_method TEXT DEFAULT 'Cash',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Refund Requests
CREATE TABLE refund_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  reference TEXT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT DEFAULT 'General',
  recipient_type TEXT DEFAULT 'all',
  recipient_ref TEXT,
  status TEXT DEFAULT 'sent',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Role Permissions
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE DEFAULT 'a0000000-0000-0000-0000-000000000001',
  role TEXT NOT NULL,
  permission_key TEXT NOT NULL,
  can_view BOOLEAN DEFAULT TRUE,
  can_edit BOOLEAN DEFAULT FALSE
);

-- User Settings
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  theme_mode TEXT DEFAULT 'system',
  dense_mode BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. AUTO-CREATE USER PROFILE TRIGGER FOR SUPABASE AUTH
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, facility_id, full_name, role)
  VALUES (
    NEW.id,
    'a0000000-0000-0000-0000-000000000001',
    COALESCE(NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1), 'Staff User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'perawat')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. ROW LEVEL SECURITY & PERMISSIVE POLICIES FOR AUTHENTICATED USERS
ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE screening_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE triage_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated facilities" ON facilities FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated profiles" ON profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated patients" ON patients FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated doctors" ON doctors FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated services" ON services FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated rooms" ON rooms FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated appointments" ON appointments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated clinical_intakes" ON clinical_intakes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated screening_sessions" ON screening_sessions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated triage_assessments" ON triage_assessments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated vitals" ON vitals FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated invoices" ON invoices FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated refund_requests" ON refund_requests FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated notifications" ON notifications FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated audit_logs" ON audit_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated role_permissions" ON role_permissions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated user_settings" ON user_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);
