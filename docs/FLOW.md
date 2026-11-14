# Alur Operasional Klinik

## Data dan otoritas

Skema aktif adalah migrasi `0001` sampai `0007` di `supabase/migrations/`.
Migrasi `0001`-`0005` menyediakan registrasi klinik, profil, katalog, dokumen,
media, legal, dan moderasi; `0006_clinical_operations.sql` menambahkan alur
kunjungan bersama; `0007_operational_status_access.sql` membatasi perubahan
status operasional ke pemilik/admin dan membuat metrik antrean read-only. File
SQL di `supabase/legacy/` bukan bagian dari skema aktif dan tidak boleh
dijalankan.

Perubahan status klinik dilakukan melalui RPC onboarding yang tersedia.
Perubahan status operasional memakai `update_clinic_operational_status`;
perubahan status kunjungan, klinis, antrean, tagihan, dan notifikasi dilakukan
melalui RPC yang dijelaskan di
[kontrak integrasi](./INTEGRATION_CONTRACT.md).
RLS tetap menjadi otoritas akses; pembatasan antarmuka bukan pengganti kebijakan
server. Jangan gunakan data pasien nyata sebelum kontrol akses, retensi,
pencatatan akses, dan kewajiban hukum klinik ditinjau.

## Alur kunjungan

1. Resepsionis memilih pasien terdaftar atau mengisi identitas pasien baru dan
   mendaftarkan kunjungan melalui `register_visit`.
2. Resepsionis mengelola check-in dan antrean. Perawat mengisi skrining dan
   triase; hanya staf dengan akses klinis yang boleh membuka informasi klinis.
3. Dokter memulai konsultasi, menyimpan dan menandatangani rekam medis, serta
   dapat menerbitkan resep dan ringkasan pulang.
4. Sistem menyiapkan tagihan. Kasir mengubah item, menerbitkan tagihan, lalu
   mencatat pembayaran offline. Pembayaran online harus dicatat server melalui
   `apply_payment_event`.
5. Inbox dan panggilan darurat hanya menampilkan data operasional minimum;
   payload realtime menandai data untuk dimuat ulang dan bukan sumber detail
   klinis.

`VisitFlowPage` adalah halaman alur aktif yang dipakai oleh grup navigasi
operasional. Halaman demo lama dan repository legacy tidak menjadi fallback:
query kosong atau gagal tidak boleh diganti dengan data sintetis.

## Realtime dan fallback

Realtime digunakan untuk `encounters`, `queue_tickets`, `clinic_inbox`, dan
`emergency_alerts`. Jika realtime dinonaktifkan atau gagal, klien memakai
polling sebagai pembaruan cadangan. Data tetap dimuat ulang melalui repository
dan RLS; perubahan yang diterima dari channel bukan izin untuk melakukan aksi.

## Pembayaran webhook

`supabase/functions/payment-webhook/` menerima payload Prometheon yang sudah
dinormalisasi. Endpoint memverifikasi HMAC-SHA256 atas body mentah sebelum
memanggil RPC dengan service role; `supabase/config.toml` menonaktifkan
verifikasi JWT bawaan hanya untuk endpoint ini. Verifikasi HMAC tetap wajib.
Service role dan `PAYMENT_WEBHOOK_SECRET` hanya boleh disimpan sebagai secrets
server Supabase, tidak di aplikasi Flutter atau repositori.

Endpoint ini **bukan adapter notifikasi native Midtrans atau Xendit**. Sebelum
integrasi gateway, implementasikan adapter server yang memverifikasi signature,
status, nilai, identitas invoice, timestamp/replay sesuai protokol gateway,
kemudian menghasilkan payload ternormalisasi dan idempotency key. Jangan
mengirim payload klien langsung ke endpoint dan jangan menganggap pembayaran
lunas berdasarkan redirect browser.

Uji fungsi lokal dengan `deno test --allow-env supabase/functions/payment-webhook/`.
Untuk deploy, siapkan secret pada Supabase Edge Function dan deploy dari
direktori proyek. Pastikan hanya secret webhook khusus yang dapat membuat
signature; jangan gunakan service role sebagai secret HMAC.

## Batasan yang diketahui

- Pasien datang langsung tanpa akun dapat dibuat saat registrasi kunjungan,
  tetapi klaim atau penggabungan riwayat pasien belum tersedia.
- Resep pada antarmuka operasional saat ini menyediakan satu item per
  penyimpanan formulir; dukungan resep multi-item dapat ditambahkan tanpa
  mengubah RPC.
- Log audit tentang siapa yang membaca rekam medis belum disediakan oleh skema
  aktif; akses RLS saja tidak menggantikan kebutuhan audit klinis.
- Pembayaran gateway tidak dapat dipakai sampai adapter provider dan pengujian
  sandbox masing-masing gateway tersedia.
