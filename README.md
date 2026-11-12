# Prometheon Clinic OS — Production Flutter + Supabase Application

Prometheon Clinic OS is a full-featured, production-ready Flutter healthcare operations and clinical management application powered by Supabase.

---

## 🌟 Key Features (Stage 1 & Stage 2 Completed)

- **Clinic Registration & Authentication**: Full sign-up flow with email confirmation, password strength validation, and automatic trigger profile/clinic creation.
- **6-Step Onboarding Wizard**: Complete registration flow covering Data Dasar (SIO/Akta upload, location geolocator), Layanan & Fasilitas, Administrasi & Legal (BPJS, Org structure), Sistem RME (SATUSEHAT integration, write-only API key), Tenaga Kesehatan, and Review & Submit.
- **Visual Identity & Public Media**: Logo, cover photo, and photo gallery management (`clinic-public-media` bucket) with moderation status badges.
- **Compliance & Expiry Monitoring**: Automatic tracking for SIO, STR, and SIP expiration with real-time system alerts, global critical banners, and automatic public search exclusion for expired licenses.
- **Patient Reviews & Ratings**: Verification-tied reviews management, star distribution, response rate analytics, official clinic reply dialog, and platform report dialog.
- **Private Patient Feedback**: Confidential feedback intake (`clinic_feedback_private`) with status tracking (`new`/`read`/`resolved`) and internal note management.
- **Legal Consents**: Version-controlled terms & privacy policy agreement dialog (`legal_consents` table).
- **Health Worker Management**: Manage doctors and nurses with sensitive PII masking (NIK 16 digits, NPWP), STR/SIP expiry tracking, duty status toggling, and supporting document uploads.
- **Internal Operations Layer**: Real-time queue management (+/- controls, process status), operational facility status, daily statistics, and calculated staffing metrics.
- **Shared Public Operations Layer**: Patient-facing live view (`clinic_public_preview` RPC and `clinic_operations_public` view) with clinic status, wait time, available doctors, and publishing control.
- **Row Level Security (RLS)**: Enforced multi-tenant data isolation per clinic using indexed SECURITY DEFINER functions (`is_clinic_member()`, `is_clinic_owner()`, `is_platform_admin()`).

---

## 🏗️ Folder Structure & Architecture

```
lib/
├── core/
│   ├── config/env.dart               # Environment constants (SUPABASE_URL, PUBLISHABLE_KEY)
│   ├── errors/error_handler.dart     # Global Flutter & platform error handler
│   ├── theme/                        # Context extentions, metrics, colors, dark/light themes
│   └── utils/
│       ├── validators.dart           # AppValidators (email, phone, NIK, NPWP, lat/lng, SIO expiry)
│       ├── formatters.dart           # AppFormatters (Rupiah, byte sizes, NIK/NPWP masking)
│       └── error_mapper.dart         # ErrorMapper (Auth, Postgrest 42501/23505/23514/23503, Storage)
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart # AuthRepository (SupabaseAuthRepository, FakeAuthRepository)
│   │   ├── state/auth_controller.dart# AuthController ChangeNotifier
│   │   └── ui/                       # AuthGate, LoginPage, RegisterClinicPage, ForgotPasswordPage, PendingVerificationPage, LegalConsentDialog
│   ├── clinic/
│   │   ├── data/                     # ClinicProfileRepository, CatalogRepository, StaffRepository, DocumentRepository, MediaRepository, ComplianceRepository, ReviewsRepository, FeedbackRepository, LegalConsentRepository
│   │   ├── models/                   # ClinicModel, ProfileModel, HealthWorkerModels, DocumentModels, OnboardingStatusModel, ComplianceModel, ReviewModels, FeedbackModel, MediaModel
│   │   ├── state/clinic_controller.dart # ClinicController ChangeNotifier
│   │   ├── ui/                       # OnboardingWizardPage, HealthWorkerListPage, HealthWorkerFormDialog, CompliancePage, ClinicReviewsPage, ClinicFeedbackPage
│   │   └── widgets/                  # DocumentUploadTile, PublicMediaUploader
│   └── operations/
│       ├── data/operations_repository.dart # OperationsRepository
│       ├── models/clinic_operations_models.dart # Internal and Public operations models
│       └── ui/                       # InternalOperationsPage, PublicOperationsPage
├── shell/                            # AppShell, AppHeader, Sidebar with KLINIK menu group
└── pages/                            # Legacy demo pages (Appointments, Triage, Finance, etc.)
```

---

## 🚀 Quick Start & Running Locally

### 1. Prerequisites
- Flutter SDK 3.22+ installed
- Google Chrome (for Web) or Android Studio / Emulator (for Android)

### 2. Run Application (Web or Android)

Run with inline `--dart-define` parameters:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://qshmccjazkupvbelyjhi.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_0FJxIsGzTDi8AeIj42utSQ_IPEKBWkZ
```

Or run on Android:
```bash
flutter run -d android \
  --dart-define=SUPABASE_URL=https://qshmccjazkupvbelyjhi.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_0FJxIsGzTDi8AeIj42utSQ_IPEKBWkZ
```

---

## 🗄️ Supabase Database & Auth Setup Order

### Step 1: Execute Migration SQL
1. Log in to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Open **SQL Editor**.
3. Run `supabase/migrations/0001_clinic_core.sql` followed by `supabase/migrations/0002_trust_and_feedback.sql`.

### Step 2: Manual Moderation (Approval Snippets)
To manually approve submitted clinic documents or public media via SQL Editor:

```sql
-- Approve a clinic document:
SELECT review_clinic_document('DOCUMENT_UUID', true, NULL);

-- Reject a clinic document:
SELECT review_clinic_document('DOCUMENT_UUID', false, 'Dokumen SIO kurang jelas.');

-- Approve a public media image (Logo/Cover/Gallery):
SELECT review_clinic_media('MEDIA_UUID', true, NULL);

-- Resolve a review report (uphold report and remove review):
SELECT resolve_review_report('REPORT_UUID', true, 'Ulasan terbukti melanggar privasi.');
```

### Step 3: Schedule Daily Compliance Expiry Refresh (pg_cron)
To automatically refresh compliance alert status daily at 01:00 AM UTC:
```sql
SELECT cron.schedule(
  'compliance-alerts-daily',
  '0 1 * * *',
  $$SELECT public.refresh_compliance_alerts(null)$$
);
```

---

## 🧪 Testing & Code Quality

Run code formatting, linter static analysis, and automated unit/widget test suite:

```bash
# 1. Format code
dart format .

# 2. Run static analysis (0 issues requirement)
flutter analyze

# 3. Execute all test suites
flutter test
```
