# Rencana Penyederhanaan UX

## Peta menu

| Menu lama | Menu baru |
| --- | --- |
| Dashboard / Beranda demo | Beranda klinik; ringkasan operasional dan hal yang perlu ditindaklanjuti |
| Operasional Internal dan Operasional demo | Operasional; kontrol status dan antrean |
| Tenaga Kesehatan | Tenaga Kesehatan |
| Ulasan & Rating dan Masukan Privat | Ulasan & Masukan; tab Ulasan dan Masukan Privat |
| Profil Klinik, Layanan & Fasilitas, Administrasi & Legal, Rekam Medis (RME), Tampilan Publik, Kepatuhan | Profil & Legal; tab untuk keenam bagian tersebut |
| Pengaturan tema | Pengaturan; tampilan, akun, syarat & privasi, bantuan, dan keluar |

## Halaman yang disembunyikan saat modul demo dimatikan

Appointments, Triage, Consultations, Patients, Workflow, Nurses, Membership,
Scheduling, Reviews lama, Billing, Reports, Notifications lama, Roles, Operations
lama, serta Doctors/Services/Rooms berbasis data demo tetap ada di kode tetapi
tidak tersedia melalui navigasi maupun `AppController.go`.

## Implementasi UX

- Navigasi klinik menampilkan enam tujuan; layar sempit memakai lima tujuan
  bawah dan lembar "Lainnya". Destinasi demo dialihkan ke Beranda saat flag
  demo dimatikan.
- Beranda menampilkan status klinik, kontrol operasi ringkas, daftar tindakan,
  saran, dan panduan awal sekali per klinik.
- Wizard menyediakan bantuan kontekstual, simpan otomatis untuk data teks,
  simpan-lanjut, dukungan, template klinik dengan pencegahan duplikasi, serta
  pilihan lokasi melalui GPS, koordinat manual, atau peta yang dapat diketuk
  dan digeser.
- Unggah dokumen dan foto menerima pilihan kamera atau berkas. `file_picker`
  versi 13 membaca isi berkas melalui `PlatformFile.readAsBytes()`; API versi
  ini tidak lagi menyediakan parameter `withData`.
- Publikasi dibatasi untuk klinik terverifikasi dengan SIO yang masih berlaku.
  Status pratinjau tetap membedakan klinik buka dengan antrean yang ditutup.
- Gerbang autentikasi/verifikasi dan perubahan status melalui RPC tetap
  dipertahankan. Aturan penggunaan tile OSM dicatat di `DECISIONS.md`.
