# Audit Alur Registrasi dan Operasional Klinik

## Sumber kebenaran aktif

- Skema klinik dan RPC registrasi: `supabase/migrations/0001_clinic_core.sql`.
- Kepatuhan, ulasan, media dan dokumen: `0002_trust_and_feedback.sql`.
- Perbaikan profil/auth: migrasi bernomor `0003_*`.
- Penyederhanaan RME: `0003_simplify_emr_step.sql`.
- Penyesuaian status pengiriman dan cache PostgREST: `0004_*`, `0005_*`.
- Kunjungan, antrean, data klinis, pembayaran, inbox dan emergency: `0006_clinical_operations.sql`.
- Kontrak lintas aplikasi: [`INTEGRATION_CONTRACT.md`](./INTEGRATION_CONTRACT.md).

## Audit modul lama

| Halaman / modul | Implementasi awal | Query/tabel lama | Pemetaan skema aktif | Status audit |
|---|---|---|---|---|
| Beranda / dashboard | `lib/pages/dashboard_page.dart`, `lib/features/clinic/ui/home_page.dart` | `ClinicData` dan `MockData`; nilai KPI/timeline statis | `clinic_operations_internal`, `clinic_visit_board`, `clinic_inbox`, `emergency_alerts`, `clinic_alerts`, review stats | Dashboard clinic-native memakai repository aktif; halaman dashboard lama harus membaca sumber aktif sebelum menggantikan Beranda. |
| Appointments | `lib/pages/appointments_page.dart`, `lib/data/repositories/appointments_repository.dart` | `appointments`, join/tabel terkait | `encounters`, `clinic_patients`, `queue_tickets`; perubahan melalui `register_visit`, `check_in_visit`, `cancel_visit`, `take_queue` | Implementasi lama tidak kompatibel dengan skema aktif; jangan gunakan repo legacy untuk alur klinik. |
| Triage & Screening | `lib/pages/triage_page.dart`, `lib/data/repositories/triage_repository.dart` | `screening_sessions`, `triage_assessments`, `vitals` | `visit_intakes`, `visit_triage`, `visit_vitals`, `encounters`; tulis melalui `submit_intake`/`record_triage` | Implementasi lama tidak kompatibel; data klinis wajib dilindungi peran. |
| Doctors / Nurses & Staff | `lib/pages/doctors_page.dart`, `lib/features/clinic/ui/health_workers/health_worker_list_page.dart` | Repo demo query `doctors`; staf klinik memakai tabel aktif `health_workers` | `health_workers`, `clinic_members`, `clinic_members.clinical_access` | Gunakan sumber `health_workers` untuk tenaga kesehatan dan membership untuk staf aplikasi. |
| Patients | `lib/pages/patients_page.dart`, `lib/data/repositories/patients_repository.dart` | `patients`, termasuk `is_deleted`, `global_patient_id`, `mrn` | `clinic_patients`, `clinic_patient_private`; tambah/registrasi pasien bersamaan melalui RPC `register_visit` | Operasi tulis langsung lama tidak boleh dipakai; kontrak belum menyediakan RPC edit pasien terpisah. |
| Consultations / Clinical Workflow | `lib/pages/consultations_page.dart`, `lib/pages/placeholder_page.dart` | Repo demo `consultations` atau `ClinicData` | `visit_consultations`, `medical_records`, `medical_record_versions`, `prescriptions`, `visit_discharges`; tulis lewat RPC klinis | Placeholder/demo tidak boleh dianggap sebagai alur klinis aktif. |
| Billing & Payments | `lib/pages/finance_page.dart`, `lib/data/repositories/billing_repository.dart` | `invoices`, `refund_requests`; update langsung | `visit_invoices`, `visit_invoice_items`, `visit_payments`; tulis melalui RPC billing dan webhook server | Repo lama tidak kompatibel dan melanggar kontrak tulis RPC. |
| Notifications | `lib/pages/notifications_page.dart`, `lib/data/repositories/notifications_repository.dart` | `notifications`, `send_notification` lama | `clinic_inbox`, `emergency_alerts`; baca melalui RLS, tandai baca dengan `inbox_mark_read`, status darurat dengan `emergency_update` | Sumber lama tidak sesuai kontrak aktif. |
| Services | `lib/pages/services_page.dart`, `lib/data/repositories/services_repository.dart` | `services` | `clinic_services` (`service_type`, `default_price`, `duration_min`) | Mutasi harus memakai repository katalog klinik, bukan tabel lama. |
| Rooms & Resources | `lib/pages/resources_page.dart`, `lib/data/repositories/rooms_repository.dart` | `rooms` | `clinic_facilities` (ruang, kapasitas, status) dan `clinic_equipment` | Mutasi harus memakai repository katalog klinik. |
| Roles & Permissions | `lib/pages/permissions_page.dart`, `lib/data/repositories/roles_repository.dart` | `role_permissions` model lama (`facility_id`) | `clinic_members.role`, `clinical_access`; kebijakan server adalah sumber otoritatif | UI harus menampilkan akses membership nyata dan alasan pembatasan. |
| Operations Overview | `lib/features/operations/ui/internal_operations_page.dart` | Modul klinik aktif | `clinic_operations_internal`, `clinic_public_preview`; aksi operasi melalui repository klinik | Statistik dibaca dari server; hanya status operasional yang dapat diubah. |
| Public Profile, Reviews, Compliance | `lib/features/clinic/ui/*` | Modul klinik-native | tabel dan RPC `clinic_*` dari migrasi aktif | Tetap menjadi implementasi sumber data aktif. |

## Masalah lintas pemotongan lama

1. `SupabaseClinicRepository` membuat snapshot `MockData` lalu mengembalikannya
   ketika tabel kosong, query gagal, atau Supabase belum tersedia. Ini
   menyamarkan kegagalan dan dapat menampilkan data pasien sintetis.
2. Repo pada `lib/data/repositories/` memakai nama tabel/RPC skema lama dan
   beberapa melakukan insert/update langsung. Repo tersebut tidak aman untuk
   dipakai pada alur baru.
3. Beberapa halaman presentasi membaca `ClinicData` yang berisi angka dan data
   statis. Kehadiran halaman tidak berarti fiturnya sudah terhubung ke backend.
4. Skema lama dipindahkan ke `supabase/legacy/`; jangan jalankan file tersebut.

## Langkah migrasi kode

Domain alur baru ada di `lib/domain/` tanpa dependensi Flutter. Implementasi
Supabase baru ada di `lib/data/supabase/`; seluruh perubahan kunjungan, klinis,
tagihan, inbox, dan emergency menggunakan RPC. Penggantian halaman lama harus
berlangsung per modul dan harus mempertahankan batas akses RLS/clinical access
dari kontrak.
