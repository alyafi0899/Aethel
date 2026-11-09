# Prometheon Clinic OS — versi Flutter

Port Flutter dari desain **Clinic Operations Platform** (Figma Make, React + Tailwind).
Semua 15 halaman, drawer, modal, dan interaksi dari desain sudah ada.

## Menjalankan

```bash
flutter create . --platforms=web,android,ios,windows,macos   # sekali saja, membuat folder platform
flutter pub get
flutter run -d chrome        # atau device lain
flutter test
```

## Mengatur theme (cukup satu file)

`lib/core/theme/theme_config.dart`

| Yang ingin diubah | Di mana |
|---|---|
| Warna brand (primary, accent, sidebar) | `BrandPalettes` — edit atau tambah palette |
| Tema awal (palette, light/dark, radius, density, font, ukuran font) | `kInitialThemeConfig` di bawah file |
| Warna status badge (hijau/amber/merah…) | `ClinicColors.from(...)` di `clinic_colors.dart` |
| Kata kunci status → warna badge | fungsi `badgeTone()` di `data/models.dart` |
| Set ikon | `lib/core/icons.dart` |

Saat aplikasi berjalan, semua pengaturan itu juga bisa diubah langsung dari menu **Settings → Appearance**
(palette, mode light/dark/system, radius sudut, density, ukuran font, jenis font).
Dari kode: `context.read<ThemeController>().setPalette(BrandPalettes.emerald)`.

Di widget, ambil token dengan `context.c.primary`, `context.m.radius`, `context.sH1`, dst. (`core/theme/context_ext.dart`).

## Data point

Semua data contoh ada di **`lib/data/mock_data.dart`** — pasien, janji temu, dokter, ruangan, invoice,
notifikasi, angka dashboard, KPI, dll. Ubah angkanya di sana, UI ikut berubah.

Untuk memakai backend sungguhan: buat class yang `implements ClinicRepository`
(`lib/data/clinic_repository.dart`), kembalikan `ClinicData`, lalu ganti `MockClinicRepository()` di `main.dart`.

## Struktur

```
lib/
  main.dart, app.dart
  core/            icons, responsive, theme/ (config, colors, metrics, controller)
  data/            models, mock_data, clinic_repository
  state/           AppController (halaman aktif, daftar appointment, pencarian)
  widgets/         AppCard, StatusBadge, DataGrid, AppButton, form, toast, side panel
  shell/           sidebar, header, app_shell (responsif: sidebar tetap >= 850px, drawer di bawahnya)
  pages/           dashboard, appointments, triage, doctors, resources, notifications, finance,
                   reports, patients, services, consultations, marketplace, permissions, settings
  sheets/          drawer appointment, panel review klinis, dialog darurat, form appointment 2 langkah,
                   form notifikasi, quick action
```

## Catatan terhadap desain asli

- Ukuran font default sedikit lebih besar dari mock-up web (yang memakai 8–11 px). Untuk tampilan lebih padat,
  set `fontScale: 0.9`.
- Ikon memakai Material Icons (padanan terdekat dari set SVG di desain).
- Halaman **Settings** di desain hanya placeholder; di sini diisi editor theme.
- Halaman Clinical Workflow, Nurses & Staff, Facility Membership, Scheduling, dan Ratings & Reviews juga
  placeholder di desain asli, jadi tetap placeholder.
- Pengaturan theme belum disimpan permanen. Tambahkan `shared_preferences` di `ThemeController` bila perlu.
