-- =============================================================================
-- PROMETHEON CLINIC OS - SEED DATA (DEVELOPMENT ONLY)
-- Reproduces sample clinic dataset identical to MockData.
-- =============================================================================

-- Create Baseline Facility
INSERT INTO facilities (id, name, description, address, phone, email, operating_hours, currency, timezone)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'Prometheon Central Clinic',
  'Comprehensive multidisciplinary healthcare with same-day appointments and connected specialist care.',
  'Jl. Sudirman No. 45, Jakarta Pusat',
  '+62 21 555 0182',
  'care@prometheon.health',
  '08:00 - 20:00',
  'IDR',
  'Asia/Jakarta'
) ON CONFLICT (id) DO NOTHING;

-- Seed Public Profile
INSERT INTO clinic_public_profile (facility_id, name, description, phone, email, rating, reviews_count, completeness_pct, is_published)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'Prometheon Central Clinic',
  'Comprehensive multidisciplinary healthcare with same-day appointments and connected specialist care.',
  '+62 21 555 0182',
  'care@prometheon.health',
  4.8,
  326,
  92,
  TRUE
) ON CONFLICT (facility_id) DO NOTHING;

-- Seed Patients
INSERT INTO patients (id, facility_id, global_patient_id, mrn, full_name, registration_status, last_visit_at) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'PT-009821', 'MRN-PC-20418', 'Amara Okafor', 'registered', NOW()),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'PT-003104', 'MRN-PC-19824', 'Daniel Mensah', 'registered', NOW()),
('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'PT-007425', 'MRN-PC-20115', 'Sofia Alvarez', 'registered', NOW() - INTERVAL '5 days'),
('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'PT-002811', 'Pending assignment', 'Ethan Brooks', 'pending', NOW() - INTERVAL '7 days')
ON CONFLICT (id) DO NOTHING;

-- Seed Doctors
INSERT INTO doctors (id, facility_id, full_name, specialty, registration_no, status) VALUES
('d0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Dr. Maya Chen', 'Cardiology', 'REG-58491', 'available'),
('d0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Dr. Noah Williams', 'General Medicine', 'REG-39204', 'in_consultation'),
('d0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Dr. Aisha Rahman', 'Pediatrics', 'REG-77520', 'available'),
('d0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Dr. James Okoye', 'Orthopedics', 'REG-23881', 'on_break'),
('d0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'Dr. Sarah Lim', 'Dermatology', 'REG-66109', 'unavailable')
ON CONFLICT (id) DO NOTHING;

-- Seed Services
INSERT INTO services (id, facility_id, name, category, duration_min, price, status) VALUES
('s0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'General consultation', 'Primary Care', 30, 75000, 'published'),
('s0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Cardiology consultation', 'Specialist Care', 45, 180000, 'published'),
('s0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Pediatric consultation', 'Pediatrics', 30, 110000, 'published'),
('s0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Radiology — Chest X-ray', 'Diagnostics', 25, 95000, 'internal_only')
ON CONFLICT (id) DO NOTHING;

-- Seed Rooms
INSERT INTO rooms (id, facility_id, code, type, status, note) VALUES
('r0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'C-201', 'Consultation room', 'available', 'Cardiology'),
('r0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'C-204', 'Consultation room', 'occupied', 'Dr. Maya Chen'),
('r0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'G-102', 'Examination room', 'occupied', 'Dr. Noah Williams'),
('r0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'G-105', 'Consultation room', 'reserved', 'APT-240617-064'),
('r0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'R-104', 'Radiology room', 'maintenance', 'Until Jun 19')
ON CONFLICT (id) DO NOTHING;

-- Seed Default Role Permissions (Matrix)
INSERT INTO role_permissions (facility_id, role, permission_key, can_view, can_create, can_edit, can_delete) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin', 'appointments', TRUE, TRUE, TRUE, TRUE),
('a0000000-0000-0000-0000-000000000001', 'admin', 'triage', TRUE, TRUE, TRUE, TRUE),
('a0000000-0000-0000-0000-000000000001', 'admin', 'billing', TRUE, TRUE, TRUE, TRUE),
('a0000000-0000-0000-0000-000000000001', 'admin', 'roles', TRUE, TRUE, TRUE, TRUE),
('a0000000-0000-0000-0000-000000000001', 'perawat', 'appointments', TRUE, TRUE, TRUE, FALSE),
('a0000000-0000-0000-0000-000000000001', 'perawat', 'triage', TRUE, TRUE, TRUE, FALSE),
('a0000000-0000-0000-0000-000000000001', 'perawat', 'clinical_detail_view', TRUE, TRUE, TRUE, FALSE),
('a0000000-0000-0000-0000-000000000001', 'perawat', 'billing', FALSE, FALSE, FALSE, FALSE),
('a0000000-0000-0000-0000-000000000001', 'perawat', 'roles', FALSE, FALSE, FALSE, FALSE)
ON CONFLICT (facility_id, role, permission_key) DO NOTHING;
