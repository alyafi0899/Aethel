# Kontrak Integrasi PROMETHEON (klinik - pasien - dokter)

Satu backend Supabase, tiga aplikasi. Semua perubahan alur pasien terjadi lewat **RPC** (fungsi database);
aplikasi tidak menulis langsung ke tabel alur. Skema: `0001`-`0006`. Dokumen ini adalah satu-satunya
acuan yang dipakai aplikasi klinik, aplikasi pasien, dan aplikasi dokter/perawat.

## 1. Aktor & peran
| Aktor | Akun | Cara dikenali |
|---|---|---|
| Pasien | aplikasi pasien | `profiles.account_type = 'patient'` |
| Admin klinik | aplikasi klinik | `clinic_members.role` = `owner` / `admin` |
| Resepsionis, Kasir | aplikasi klinik | `clinic_members.role` = `receptionist` / `cashier` |
| Perawat, Dokter | aplikasi dokter/perawat (atau aplikasi klinik untuk klinik kecil) | `clinic_members.role` = `nurse` / `doctor`; dokter tertaut ke `health_workers.user_id` |
| Admin platform | konsol internal | tabel `platform_admins` |
- Akses data klinis (anamnesis, vital, triase, rekam medis, resep, ringkasan pulang): peran `doctor`/`nurse`,
  atau anggota dengan `clinic_members.clinical_access = true`. Admin klinik biasa HANYA melihat status operasional.
- Bertindak sebagai dokter: peran `doctor` (atau owner/admin yang diberi `clinical_access`) dan tertaut ke `health_workers`.

## 2. Mesin tahap kunjungan (`encounters.stage`)
```
registered -> queued -> checked_in -> screening -> triage -> waiting_doctor -> in_consultation -> awaiting_payment -> completed
     \__________\____________\____________\___________\______________\--> cancelled      (no_show: dari registered/queued)
```
Transisi sah: registered->{queued,checked_in,cancelled,no_show}; queued->{checked_in,screening,cancelled,no_show};
checked_in->{screening,triage,waiting_doctor,cancelled}; screening->{triage,waiting_doctor,cancelled};
triage->{waiting_doctor,cancelled}; waiting_doctor->{in_consultation,cancelled}; in_consultation->awaiting_payment;
awaiting_payment->completed. Transisi lain ditolak (`invalid_stage_transition`, detail `dari->ke`).
`encounters.status` (`scheduled|in_progress|completed|cancelled`) mengikuti tahap. Kunjungan `completed` membuka hak
pasien menulis ulasan (aturan 0002).
Jenis kunjungan: `visit_kind` = `in_person | online_scheduled | direct_ask` (Tanya Dokter). Sumber: `source` =
`patient_app | walk_in | reception | referral | telehealth`.

Tiket antrean (`queue_tickets`): satu nomor per kunjungan per hari (mis. `U-001`, huruf dari jenis layanan), berpindah
"stasiun": `screening` -> `doctor` -> `cashier`; status `waiting|called|serving|skipped|done|cancelled`; prioritas
`emergency` > `priority` > `normal`. Penomoran atomik (aman untuk banyak pemanggil sekaligus).

## 3. RPC menurut aktor
Semua mengembalikan `jsonb` snapshot kunjungan: `{encounter_id, reference, clinic_id, stage, status, service_type, source,
visit_kind, triage_priority, has_red_flag, ticket:{ticket_id, display_code, number, station, status, priority,
ahead_count, estimated_wait_min, now_serving}}` kecuali disebut lain.

### Pasien (aplikasi pasien)
| RPC | Fungsi |
|---|---|
| `register_visit(p_clinic_id, p_service_type, p_patient=null, p_source=null, p_visit_kind='in_person', p_scheduled_at=null, p_complaint=null, p_take_queue=true, p_priority='normal')` | Daftar kunjungan. Pasien: klinik harus terverifikasi, dipublikasikan, SIO aktif; antrean sekarang butuh `facility_status='open'` dan `queue_process_status='active'`. Keluhan memicu aturan red-flag di server. |
| `take_queue(p_encounter_id)` | Ambil nomor untuk kunjungan terjadwal (`registered`). |
| `check_in_visit(p_encounter_id)` | Konfirmasi hadir (membuat tiket bila belum ada). |
| `submit_intake(p_encounter_id, p_data)` | Isi skrining mandiri: `chief_complaint, symptom_category, duration_text, onset, pain_assessment{}, medical_history, medication_allergies, additional_notes`. |
| `cancel_visit(p_encounter_id, p_reason)` | Batalkan (pasien hanya sampai `checked_in`). |
| `patient_visit_status(p_encounter_id)` | Status lengkap: snapshot + `clinic_name, clinic_status, invoice{reference,status,total}, has_prescription, record_signed`. |
| `trigger_emergency_call(p_clinic_id, p_location, p_message)` | Panggilan darurat ke klinik (maks 3 per jam per klinik). |
Baca langsung (RLS, milik sendiri): `encounters`, `queue_tickets`, `visit_events`, `visit_intakes`, `visit_vitals`,
`visit_consultations`, `visit_discharges`, `prescriptions`+`prescription_items`, `medical_records` (status signed/amended) dan
`medical_record_versions` (hanya sampai `signed_version`), `visit_invoices` (bukan draft)+`visit_invoice_items`+`visit_payments`.
Publik (tanpa login): view `clinic_operations_public`, `clinic_public_profile`, `clinic_reviews_public`.

### Klinik: resepsionis / admin (owner, admin, receptionist, nurse)
`register_visit` (mode staf: `p_patient = {id}` atau `{full_name, phone, gender, birth_date, user_id?}`, `p_source` = `walk_in|reception|referral`),
`take_queue`, `check_in_visit`, `cancel_visit`, `mark_no_show(p_encounter_id)`, `submit_intake`,
`queue_call_next(p_clinic_id, p_station='screening'|'doctor'|'cashier', p_queue_code=null)` -> info tiket atau `null`,
`queue_update_ticket(p_ticket_id, 'skipped'|'waiting'|'serving')`, `emergency_update(p_alert_id, 'acknowledged'|'dispatched'|'resolved'|'false_alarm', p_note)`,
`inbox_mark_read(p_ids uuid[])`.
Baca: `clinic_visit_board` (papan alur: tanpa data klinis), `encounters`, `clinic_patients`, `queue_tickets`, `visit_events`,
`clinic_inbox`, `emergency_alerts`, `visit_consultations` (metadata). Tagihan hanya untuk owner/admin/kasir.

### Perawat (nurse) / Dokter (doctor)
- `record_triage(p_encounter_id, p_priority='urgent|priority|routine', p_notes, p_vitals{bp_systolic,bp_diastolic,heart_rate,spo2,temperature_c,resp_rate,weight_kg,height_cm}, p_red_flag, p_ready_for_doctor)` - perawat/dokter.
- Dokter: `consultation_start(p_encounter_id)`, `save_medical_record(p_encounter_id, p_content{subjective,objective,assessment,plan,supporting_tests[],doctor_notes}, p_diagnoses[{code,label,type}], p_change_reason)`
  (versi baru tiap simpan; sesudah ditandatangani, ubah = amandemen dengan alasan), `sign_medical_record(p_encounter_id)`,
  `issue_prescription(p_encounter_id, p_items[{medicine_id?,medicine_name,dose,frequency,duration_days,quantity,instructions}], p_pharmacy_notes)`,
  `complete_consultation(p_encounter_id, p_discharge{summary,follow_up_at,follow_up_note,emergency_contact_info})` -> `{invoice_id, ...snapshot}`
  (butuh rekam medis berstatus `signed`; menyiapkan tagihan draft dari harga layanan).
- Baca data klinis klinik: `visit_intakes`, `visit_triage`, `visit_vitals`, `medical_records`, `medical_record_versions`, `prescriptions`, `visit_discharges`.
- Versi rekam medis dan `visit_events` bersifat tidak dapat diubah (`immutable_record`).

### Kasir / admin (owner, admin, cashier)
`update_invoice_items(p_encounter_id, p_items[{description,quantity,unit_price,item_type}], p_discount)` (hanya draft),
`issue_invoice(p_invoice_id)` (total 0 langsung lunas), `record_offline_payment(p_invoice_id, p_amount, p_method, p_note)`
(`cash|bank_transfer|debit_card|credit_card|qris|ewallet|bpjs|insurance`), `void_invoice(p_invoice_id, p_reason)` (owner/admin).
Tagihan lunas otomatis menyelesaikan kunjungan (`awaiting_payment` -> `completed`).

### Pengelola operasional (owner/admin)
`update_clinic_operational_status(p_clinic_id, p_facility_status, p_queue_process_status)` mengubah status fasilitas dan antrean. Metrik seperti nomor dilayani, jumlah antrean, dan estimasi tunggu dihitung dari kunjungan/tiket dan tidak boleh diedit langsung. Migrasi `0007_operational_status_access.sql` mencabut izin update tabel dari klien dan membatasi RPC ke owner/admin.

### Server (Edge Function, service role)
`apply_payment_event(p_invoice_id, p_provider='midtrans|xendit|other', p_provider_ref, p_amount, p_method, p_status='pending|succeeded|failed', p_idempotency_key)`
- idempoten per `p_idempotency_key`; hanya `service_role`. Pembayaran online HANYA menjadi lunas lewat jalur ini.

## 4. Realtime (Supabase Realtime, RLS berlaku)
Tabel terdaftar: `clinic_inbox`, `encounters`, `queue_tickets`, `emergency_alerts`. Filter per klinik: `clinic_id=eq.<id>`
(pasien: `patient_user_id=eq.<uid>` pada `encounters`).
Jenis notifikasi `clinic_inbox.kind`: `queue_registered, visit_scheduled, walk_in, patient_checked_in, triage_escalated,
visit_cancelled, payment_pending, payment_received, payment_failed, emergency_call`. `severity`: `info|warning|critical`.
Isi notifikasi sengaja tidak memuat detail klinis.

## 5. Layer statistik (otomatis)
`clinic_operations_internal` dihitung ulang tiap ada perubahan kunjungan/tiket/pasien: `total_queues, current_queue_number,
average_wait_time, total_registered_patients, total_daily_visitors, daily_appointments_count, cancelled_appointments_count,
total_completed_consultations` (+ dokter/ruang/layanan seperti sebelumnya). Pengelola mengubah `queue_process_status` dan
`facility_status` melalui RPC `update_clinic_operational_status`; nilai statistik tidak dapat diubah dari klien. Layer publik:
view `clinic_operations_public`.

## 6. Kode error (pesan `exception`; `42501` = tidak berwenang)
Umum: `not_authenticated, not_authorized, clinic_not_found, visit_not_found, patient_required, patient_not_found,
patient_name_required, service_type_required, invalid_visit_kind, invalid_priority, invalid_source`.
Pendaftaran/antrean: `clinic_not_available, queue_closed, active_visit_exists, invalid_stage_transition, cannot_cancel_now,
visit_closed, invalid_station, ticket_not_found, invalid_ticket_transition`.
Klinis: `practitioner_not_linked, invalid_stage_for_record, diagnoses_must_be_array, change_reason_required, record_required,
record_not_signed, items_required, medicine_name_required, invalid_stage_for_prescription, immutable_record`.
Tagihan: `invoice_not_found, invoice_not_editable, invoice_not_payable, invoice_not_voidable, invoice_has_payments,
invalid_amount, overpayment, items_must_be_array, item_description_required, reason_required, service_role_only,
idempotency_key_required, invalid_provider, invalid_status`.
Darurat: `too_many_alerts, alert_not_found, alert_closed`.

## 7. Skenario
**Pasien (aplikasi pasien):** cari klinik (`clinic_public_profile`/`clinic_operations_public`) -> `register_visit` ->
pantau `patient_visit_status` + realtime `encounters`/`queue_tickets` -> (opsional) `submit_intake` -> dipanggil ->
lihat resep/hasil -> bayar (online lewat penyedia, status masuk lewat webhook) -> ulas klinik (kunjungan `completed`).
**Datang langsung:** resepsionis `register_visit` (staf) -> tiket -> perawat `queue_call_next('screening')` -> `record_triage(... ready)` ->
dokter `queue_call_next('doctor')` -> `consultation_start` -> `save_medical_record` -> `sign_medical_record` ->
`issue_prescription` -> `complete_consultation` -> kasir `issue_invoice` -> `record_offline_payment` -> selesai.
**Darurat:** pasien `trigger_emergency_call` -> notifikasi kritis di klinik -> staf `emergency_update`.

## 8. Batasan yang disengaja
- Isi percakapan (Tanya Dokter / telekonsultasi) tidak disimpan di skema ini; simpan terpisah dengan akses hanya untuk
  peserta (pasien + dokter), bukan admin. `visit_consultations.channel_ref` hanya menyimpan referensi ruang.
- Aturan red-flag di `red_flag_rules` adalah kata kunci sederhana (alat bantu tinjauan, bukan diagnosis) dan harus
  ditinjau tenaga klinis. Estimasi waktu tunggu kasar (8 menit per pasien di depan).
- Pasien datang langsung tanpa akun belum dapat "mengklaim" riwayatnya; penautan lewat nomor telepon dirancang di tahap pasien.
- Rekam medis memuat data kesehatan yang sensitif: akses dibatasi peran, tetapi pencatatan siapa yang MEMBACA belum ada.
- Pastikan seluruh kewajiban rekam medis elektronik, retensi, dan perlindungan data pribadi dipenuhi sebelum dipakai untuk data pasien nyata.
