-- =============================================================================
-- PROMETHEON CLINIC OS - BUSINESS LOGIC & RPC PROCEDURES (MIGRATION 03)
-- Atomic transactions with automatic audit logging for all mutations.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CREATE APPOINTMENT WITH INTAKE & SCREENING SESSION
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_appointment_with_intake(
  p_patient_name TEXT,
  p_doctor_id UUID DEFAULT NULL,
  p_service_id UUID DEFAULT NULL,
  p_starts_at TIMESTAMPTZ DEFAULT NOW(),
  p_primary_complaint TEXT DEFAULT 'General consultation',
  p_source appointment_source DEFAULT 'reception'
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_facility_id UUID;
  v_actor_id UUID;
  v_patient_id UUID;
  v_appointment_id UUID;
  v_intake_id UUID;
  v_screening_id UUID;
  v_apt_ref TEXT;
  v_scr_ref TEXT;
  v_seq INT;
  v_date_str TEXT;
BEGIN
  v_facility_id := auth_facility_id();
  v_actor_id := auth.uid();

  IF v_facility_id IS NULL THEN
    RAISE EXCEPTION 'User has no associated facility.';
  END IF;

  v_date_str := TO_CHAR(NOW(), 'YYMMDD');
  v_seq := FLOOR(RANDOM() * 899 + 100)::INT;
  v_apt_ref := 'APT-' || v_date_str || '-' || v_seq::TEXT;
  v_scr_ref := 'SCR-' || v_date_str || '-' || (v_seq + 10)::TEXT;

  -- Find or Create Patient
  SELECT id INTO v_patient_id FROM patients
  WHERE facility_id = v_facility_id AND LOWER(full_name) = LOWER(p_patient_name) AND is_deleted = false
  LIMIT 1;

  IF v_patient_id IS NULL THEN
    INSERT INTO patients (facility_id, global_patient_id, full_name)
    VALUES (v_facility_id, 'PT-' || (FLOOR(RANDOM() * 899000 + 100000)::TEXT), p_patient_name)
    RETURNING id INTO v_patient_id;
  END IF;

  -- Insert Appointment
  INSERT INTO appointments (
    facility_id, reference, patient_id, doctor_id, service_id, starts_at, source, status, created_by
  ) VALUES (
    v_facility_id, v_apt_ref, v_patient_id, p_doctor_id, p_service_id, p_starts_at, p_source, 'pending_confirmation', v_actor_id
  ) RETURNING id INTO v_appointment_id;

  -- Insert Clinical Intake
  INSERT INTO clinical_intakes (
    appointment_id, primary_complaint, data_source, author_id
  ) VALUES (
    v_appointment_id, p_primary_complaint, 'receptionist_assisted', v_actor_id
  ) RETURNING id INTO v_intake_id;

  -- Insert Screening Session
  INSERT INTO screening_sessions (
    facility_id, reference, appointment_id, intake_id, completion_pct, priority, status
  ) VALUES (
    v_facility_id, v_scr_ref, v_appointment_id, v_intake_id, 80, 'routine', 'new_screening'
  ) RETURNING id INTO v_screening_id;

  -- Log Audit Event
  INSERT INTO audit_logs (facility_id, actor_id, action, entity, entity_id, payload)
  VALUES (
    v_facility_id, v_actor_id, 'CREATE_APPOINTMENT', 'appointments', v_appointment_id::TEXT,
    jsonb_build_object('reference', v_apt_ref, 'patient_name', p_patient_name)
  );

  RETURN jsonb_build_object(
    'appointment_id', v_appointment_id,
    'appointment_reference', v_apt_ref,
    'screening_id', v_screening_id,
    'screening_reference', v_scr_ref
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. UPDATE APPOINTMENT STATUS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_appointment_status(
  p_appointment_id UUID,
  p_new_status appointment_status
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_facility_id UUID;
  v_actor_id UUID;
  v_old_status appointment_status;
  v_ref TEXT;
BEGIN
  v_facility_id := auth_facility_id();
  v_actor_id := auth.uid();

  SELECT status, reference INTO v_old_status, v_ref FROM appointments
  WHERE id = p_appointment_id AND facility_id = v_facility_id;

  IF v_old_status IS NULL THEN
    RAISE EXCEPTION 'Appointment not found or unauthorized.';
  END IF;

  UPDATE appointments
  SET status = p_new_status, updated_at = NOW()
  WHERE id = p_appointment_id;

  -- Audit Log
  INSERT INTO audit_logs (facility_id, actor_id, action, entity, entity_id, payload)
  VALUES (
    v_facility_id, v_actor_id, 'UPDATE_APPOINTMENT_STATUS', 'appointments', p_appointment_id::TEXT,
    jsonb_build_object('reference', v_ref, 'old_status', v_old_status, 'new_status', p_new_status)
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. TRIAGE ACTIONS (REVIEW, ESCALATE, COMPLETE)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION triage_action(
  p_screening_id UUID,
  p_action TEXT, -- 'start_review', 'escalate', 'complete'
  p_disposition TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_facility_id UUID;
  v_actor_id UUID;
  v_old_status triage_status;
  v_new_status triage_status;
  v_red_flag BOOLEAN := FALSE;
BEGIN
  v_facility_id := auth_facility_id();
  v_actor_id := auth.uid();

  SELECT status INTO v_old_status FROM screening_sessions
  WHERE id = p_screening_id AND facility_id = v_facility_id;

  IF v_old_status IS NULL THEN
    RAISE EXCEPTION 'Screening session not found.';
  END IF;

  IF p_action = 'start_review' THEN
    v_new_status := 'in_review';
  ELSIF p_action = 'escalate' THEN
    v_new_status := 'escalated';
    v_red_flag := TRUE;
  ELSIF p_action = 'complete' THEN
    v_new_status := 'completed';
  ELSE
    RAISE EXCEPTION 'Invalid triage action.';
  END IF;

  UPDATE screening_sessions
  SET status = v_new_status,
      reviewer_id = v_actor_id,
      red_flag = CASE WHEN v_red_flag THEN TRUE ELSE red_flag END,
      completion_pct = CASE WHEN v_new_status = 'completed' THEN 100 ELSE completion_pct END,
      updated_at = NOW()
  WHERE id = p_screening_id;

  -- Insert history
  INSERT INTO triage_status_history (screening_id, previous_status, new_status, changed_by, notes)
  VALUES (p_screening_id, v_old_status, v_new_status, v_actor_id, p_notes);

  -- Upsert assessment if disposition provided
  IF p_disposition IS NOT NULL OR p_notes IS NOT NULL THEN
    INSERT INTO triage_assessments (screening_id, disposition, notes, assessed_by)
    VALUES (p_screening_id, p_disposition, p_notes, v_actor_id)
    ON CONFLICT (screening_id) DO UPDATE
    SET disposition = EXCLUDED.disposition, notes = EXCLUDED.notes, assessed_at = NOW();
  END IF;

  -- Audit log
  INSERT INTO audit_logs (facility_id, actor_id, action, entity, entity_id, payload)
  VALUES (
    v_facility_id, v_actor_id, 'TRIAGE_ACTION_' || UPPER(p_action), 'screening_sessions', p_screening_id::TEXT,
    jsonb_build_object('old_status', v_old_status, 'new_status', v_new_status, 'red_flag', v_red_flag)
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. RECORD VITALS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION record_vitals(
  p_screening_id UUID,
  p_bp_sys INT,
  p_bp_dia INT,
  p_hr INT,
  p_spo2 INT,
  p_temp NUMERIC,
  p_rr INT
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_facility_id UUID;
  v_actor_id UUID;
BEGIN
  v_facility_id := auth_facility_id();
  v_actor_id := auth.uid();

  INSERT INTO vitals (screening_id, bp_sys, bp_dia, hr, spo2, temp, rr, recorded_by)
  VALUES (p_screening_id, p_bp_sys, p_bp_dia, p_hr, p_spo2, p_temp, p_rr, v_actor_id);

  UPDATE screening_sessions
  SET completion_pct = GREATEST(completion_pct, 90), updated_at = NOW()
  WHERE id = p_screening_id;

  INSERT INTO audit_logs (facility_id, actor_id, action, entity, entity_id, payload)
  VALUES (
    v_facility_id, v_actor_id, 'RECORD_VITALS', 'vitals', p_screening_id::TEXT,
    jsonb_build_object('bp', p_bp_sys::TEXT || '/' || p_bp_dia::TEXT, 'hr', p_hr, 'temp', p_temp)
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. SEND NOTIFICATION
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION send_notification(
  p_title TEXT,
  p_body TEXT,
  p_category TEXT DEFAULT 'General',
  p_recipient_type notification_recipient_type DEFAULT 'all',
  p_recipient_ref TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_facility_id UUID;
  v_actor_id UUID;
  v_notif_id UUID;
  v_ref TEXT;
BEGIN
  v_facility_id := auth_facility_id();
  v_actor_id := auth.uid();
  v_ref := 'NTF-' || (FLOOR(RANDOM() * 89999 + 10000)::TEXT);

  INSERT INTO notifications (
    facility_id, reference, title, body, category, recipient_type, recipient_ref, status, created_by
  ) VALUES (
    v_facility_id, v_ref, p_title, p_body, p_category, p_recipient_type, p_recipient_ref, 'sent', v_actor_id
  ) RETURNING id INTO v_notif_id;

  INSERT INTO audit_logs (facility_id, actor_id, action, entity, entity_id, payload)
  VALUES (
    v_facility_id, v_actor_id, 'SEND_NOTIFICATION', 'notifications', v_notif_id::TEXT,
    jsonb_build_object('reference', v_ref, 'title', p_title)
  );

  RETURN v_notif_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. AGGREGATION VIEWS & DASHBOARD RPC
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dashboard_summary(p_facility_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_total_appointments INT := 0;
  v_today_appointments INT := 0;
  v_pending_requests INT := 0;
  v_completed_today INT := 0;
  v_available_doctors INT := 0;
  v_revenue_today BIGINT := 0;
BEGIN
  SELECT COUNT(*) INTO v_total_appointments FROM appointments WHERE facility_id = p_facility_id;
  SELECT COUNT(*) INTO v_today_appointments FROM appointments WHERE facility_id = p_facility_id AND DATE(starts_at) = p_date;
  SELECT COUNT(*) INTO v_pending_requests FROM appointments WHERE facility_id = p_facility_id AND status = 'pending_confirmation';
  SELECT COUNT(*) INTO v_completed_today FROM appointments WHERE facility_id = p_facility_id AND status = 'completed' AND DATE(starts_at) = p_date;
  SELECT COUNT(*) INTO v_available_doctors FROM doctors WHERE facility_id = p_facility_id AND status = 'available';
  SELECT COALESCE(SUM(amount), 0) INTO v_revenue_today FROM invoices WHERE facility_id = p_facility_id AND status = 'paid' AND DATE(created_at) = p_date;

  RETURN jsonb_build_object(
    'total_appointments', v_total_appointments,
    'today_appointments', v_today_appointments,
    'pending_requests', v_pending_requests,
    'completed_today', v_completed_today,
    'available_doctors', v_available_doctors,
    'revenue_today', v_revenue_today
  );
END;
$$;
