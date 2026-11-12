-- =====================================================================
--  PROMETHEON CLINIC OS - QA & TEST DATA SETUP SCRIPT
--  Jalankan di Supabase SQL Editor setelah pendaftaran klinik disetujui.
--  Ganti placeholder:
--    <CLINIC_ID>        : UUID klinik Anda (dapat dilihat di tabel clinics)
--    <PATIENT_USER_ID>  : UUID akun pasien (buat via Supabase Auth)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CATATAN PEMBUATAN AKUN PASIEN
-- ---------------------------------------------------------------------
-- A. Buka Supabase Dashboard > Authentication > Users > "Add user".
-- B. Buat akun pasien baru (misal: pasien.test@gmail.com).
-- C. Salin UUID pengguna tersebut dan ganti <PATIENT_USER_ID> di bawah.


-- ---------------------------------------------------------------------
-- 2. DUMMY ENCOUNTER 1 (Kunjungan Selesai untuk Ulasan)
-- ---------------------------------------------------------------------
INSERT INTO public.encounters (id, clinic_id, patient_user_id, status, completed_at)
VALUES (
  gen_random_uuid(),
  '<CLINIC_ID>',
  '<PATIENT_USER_ID>',
  'completed',
  NOW() - INTERVAL '2 days'
)
ON CONFLICT DO NOTHING;

-- Salin ID encounter dari perintah di atas atau ambil ID encounter terbaru:
-- SELECT id FROM public.encounters WHERE clinic_id = '<CLINIC_ID>' LIMIT 1;


-- ---------------------------------------------------------------------
-- 3. DUMMY CLINIC REVIEWS (Ulasan & Rating Pasien)
-- ---------------------------------------------------------------------
-- Catatan: SQL Editor berjalan sebagai admin (service_role), sehingga
-- patient_user_id WAJIB diisi eksplisit.

INSERT INTO public.clinic_reviews (clinic_id, encounter_id, patient_user_id, rating, comment, status)
SELECT
  '<CLINIC_ID>',
  e.id,
  '<PATIENT_USER_ID>',
  5,
  'Pelayanan di klinik ini sangat memuaskan, dokter dan perawat ramah serta profesional.',
  'published'
FROM public.encounters e
WHERE e.clinic_id = '<CLINIC_ID>' AND e.patient_user_id = '<PATIENT_USER_ID>'
LIMIT 1
ON CONFLICT DO NOTHING;


-- ---------------------------------------------------------------------
-- 4. DUMMY ENCOUNTER 2 & PRIVATE FEEDBACK (Masukan Privat Pasien)
-- ---------------------------------------------------------------------
WITH new_enc AS (
  INSERT INTO public.encounters (clinic_id, patient_user_id, status, completed_at)
  VALUES ('<CLINIC_ID>', '<PATIENT_USER_ID>', 'completed', NOW() - INTERVAL '1 day')
  RETURNING id, clinic_id, patient_user_id
)
INSERT INTO public.clinic_feedback_private (clinic_id, encounter_id, patient_user_id, category, message, status)
SELECT
  n.clinic_id,
  n.id,
  n.patient_user_id,
  'facility',
  'Mohon pendingin ruangan (AC) di ruang tunggu utama disesuaikan temperaturnya karena agak hangat saat jam sibuk.',
  'new'
FROM new_enc n
ON CONFLICT DO NOTHING;
