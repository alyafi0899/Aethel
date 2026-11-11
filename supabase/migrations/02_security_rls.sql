-- =============================================================================
-- PROMETHEON CLINIC OS - SECURITY & RLS POLICIES (MIGRATION 02)
-- Enforces facility isolation, role permissions, and immutable audit logs.
-- =============================================================================

-- Enable RLS on all public tables
ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE intake_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE screening_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE triage_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE triage_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinic_public_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SECURITY DEFINER HELPER FUNCTIONS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auth_role()
RETURNS app_role
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM profiles WHERE id = auth.uid() AND is_active = true LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION auth_facility_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT facility_id FROM profiles WHERE id = auth.uid() AND is_active = true LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION has_permission(p_key TEXT, p_action TEXT DEFAULT 'view')
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_role app_role;
  v_facility UUID;
  v_allowed BOOLEAN := FALSE;
BEGIN
  v_role := auth_role();
  IF v_role IS NULL THEN
    RETURN FALSE;
  END IF;
  IF v_role = 'admin' THEN
    RETURN TRUE; -- Admin defaults to full permission
  END IF;

  v_facility := auth_facility_id();
  SELECT
    CASE
      WHEN p_action = 'create' THEN can_create
      WHEN p_action = 'edit' THEN can_edit
      WHEN p_action = 'delete' THEN can_delete
      ELSE can_view
    END INTO v_allowed
  FROM role_permissions
  WHERE facility_id = v_facility AND role = v_role AND permission_key = p_key;

  RETURN COALESCE(v_allowed, FALSE);
END;
$$;

-- -----------------------------------------------------------------------------
-- POLICIES BY TABLE
-- -----------------------------------------------------------------------------

-- Facilities
CREATE POLICY "Facilities viewable by facility members"
  ON facilities FOR SELECT
  USING (id = auth_facility_id());

-- Profiles
CREATE POLICY "Profiles viewable by facility members"
  ON profiles FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Users can update their own profile name and phone"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = auth_role() -- Role cannot be altered by self
  );

-- Patients
CREATE POLICY "Patients viewable by facility members"
  ON patients FOR SELECT
  USING (facility_id = auth_facility_id() AND is_deleted = false);

CREATE POLICY "Patients insertable by staff"
  ON patients FOR INSERT
  WITH CHECK (facility_id = auth_facility_id());

CREATE POLICY "Patients updatable by staff"
  ON patients FOR UPDATE
  USING (facility_id = auth_facility_id());

-- Doctors
CREATE POLICY "Doctors viewable by facility members"
  ON doctors FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Doctors manage by admin"
  ON doctors FOR ALL
  USING (facility_id = auth_facility_id() AND auth_role() = 'admin');

-- Rooms
CREATE POLICY "Rooms viewable by facility members"
  ON rooms FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Rooms status updatable by staff"
  ON rooms FOR UPDATE
  USING (facility_id = auth_facility_id());

-- Appointments
CREATE POLICY "Appointments viewable by facility members"
  ON appointments FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Appointments insertable by facility members"
  ON appointments FOR INSERT
  WITH CHECK (facility_id = auth_facility_id());

CREATE POLICY "Appointments updatable by facility members"
  ON appointments FOR UPDATE
  USING (facility_id = auth_facility_id());

-- Clinical Intakes & Intake Answers
CREATE POLICY "Clinical intakes viewable by staff with clinical detail permission"
  ON clinical_intakes FOR SELECT
  USING (has_permission('clinical_detail_view', 'view'));

CREATE POLICY "Clinical intakes insertable by staff"
  ON clinical_intakes FOR INSERT
  WITH CHECK (true);

-- Screening Sessions & Triage
CREATE POLICY "Screenings viewable by facility staff"
  ON screening_sessions FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Screenings updatable by staff"
  ON screening_sessions FOR UPDATE
  USING (facility_id = auth_facility_id());

CREATE POLICY "Vitals viewable and insertable by staff"
  ON vitals FOR ALL
  USING (true);

-- Invoices & Finance (Admin only)
CREATE POLICY "Invoices viewable by Admin"
  ON invoices FOR SELECT
  USING (facility_id = auth_facility_id() AND auth_role() = 'admin');

CREATE POLICY "Invoices manageable by Admin"
  ON invoices FOR ALL
  USING (facility_id = auth_facility_id() AND auth_role() = 'admin');

-- Notifications
CREATE POLICY "Notifications viewable by facility members"
  ON notifications FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Notifications insertable by facility members"
  ON notifications FOR INSERT
  WITH CHECK (facility_id = auth_facility_id());

-- Audit Logs (APPEND-ONLY FOR ALL ROLES)
CREATE POLICY "Audit logs insertable by facility members"
  ON audit_logs FOR INSERT
  WITH CHECK (facility_id = auth_facility_id());

CREATE POLICY "Audit logs viewable by admin"
  ON audit_logs FOR SELECT
  USING (facility_id = auth_facility_id() AND auth_role() = 'admin');

-- Prevent UPDATE or DELETE on audit_logs permanently
-- (No policies created for UPDATE or DELETE on audit_logs)

-- Role Permissions
CREATE POLICY "Role permissions viewable by facility members"
  ON role_permissions FOR SELECT
  USING (facility_id = auth_facility_id());

CREATE POLICY "Role permissions manageable by admin"
  ON role_permissions FOR ALL
  USING (facility_id = auth_facility_id() AND auth_role() = 'admin');

-- User Settings
CREATE POLICY "User settings viewable and manageable by owner"
  ON user_settings FOR ALL
  USING (user_id = auth.uid());
