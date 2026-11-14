# Skema Supabase lama — jangan dijalankan

File SQL di folder ini (`01_schema.sql`, `02_security_rls.sql`,
`03_rpcs.sql`, dan `clean_schema.sql`) adalah skema lama berbasis
`facilities`, `appointments`, `patients`, `screening_sessions`, dan tabel
terkait. Skema tersebut bertentangan dengan skema klinik aktif yang memakai
`clinics`, `clinic_members`, `clinic_patients`, `encounters`, dan RPC pada
`supabase/migrations/0001` sampai `0006`.

Jangan jalankan file di folder ini pada proyek Supabase aktif. Gunakan hanya
migrasi bernomor di `supabase/migrations/`, sesuai urutan dan riwayat database.
