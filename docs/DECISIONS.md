# Prometheon Clinic OS - Architectural & Design Decisions

This document records key design decisions, technical trade-offs, and security choices made during the transformation of Prometheon Clinic OS into a live Supabase application.

---

## 1. Single-Facility & Multi-Clinic Architecture
- **Decision**: Multi-clinic structure powered by `clinics`, `profiles`, and `clinic_members` (roles: `owner`, `admin`). All child entities map directly to `clinic_id`.
- **Rationale**: Ensures complete RLS isolation per clinic while supporting multi-tenant growth.

## 2. Row Level Security (RLS) & Helper Functions
- **Decision**: RLS is mandatory on ALL public schema tables. Security definer functions (`is_clinic_member()`, `is_clinic_owner()`, `is_platform_admin()`) avoid recursion and query leakage.
- **Rationale**: Isolates policy execution logic into fast, indexed database helpers.

## 3. Currency & Timezone Settings
- **Decision**: Default currency is IDR (`bigint` in rupiah) and timezone is `Asia/Jakarta`. Formats are configurable via `EnvConfig`.
- **Rationale**: Meets local Indonesian clinic operations standards while maintaining configurable multi-currency compatibility.

## 4. Clinic Onboarding & Status Lock Workflow
- **Decision**: Clinic status transitions (`draft` → `submitted` → `under_review` → `verified`) and verification columns are write-protected at database trigger level (`protect_clinic_columns`). Status changes can only occur via SECURITY DEFINER RPCs (`submit_clinic_for_review`, `review_clinic`, `set_clinic_published`).
- **Rationale**: Prevents clients from tampering with compliance status or bypassing platform review.

## 5. Storage Security & File Path Convention
- **Decision**: Storage bucket `clinic-documents` is private. Path structure is strictly `{clinic_id}/{doc_type}/{uuid}-{filename}` or `{clinic_id}/workers/{worker_id}/{doc_type}/{uuid}-{filename}`. Access is controlled via `can_access_clinic_path()` helper with 60-second signed URLs (`createSignedUrl`).
- **Rationale**: Enforces tenant-level document privacy while enabling fast web & mobile file previews.

## 6. Write-Only Integration Secrets
- **Decision**: SATUSEHAT API codes are stored in `clinic_integration_secrets` with client `select` access revoked. Saving is write-only through `save_clinic_integration_secret`; the RPC permits verified and under-review clinics only.
- **Rationale**: The API code is not needed during registration and must never be readable by the client. The UI requests it only when the clinic is eligible to configure the integration.

## 7. Sensitive Health Worker Data Separation & Masking
- **Decision**: Sensitive personal details (NIK 16 digits, NPWP 15-16 digits, home address, birth date) are stored in `health_worker_private` with foreign key cascade. UI lists display masked values (showing only last 4 digits) and omit sensitive fields from logs.
- **Rationale**: Protects PII and medical staff privacy in accordance with healthcare governance.

## 8. Shared Public Operations Layer
- **Decision**: View `clinic_operations_public` exposes only verified and published clinics. Public preview for clinic managers is fetched via `clinic_public_preview` RPC. Unpopulated operational fields (such as `next_available_slot`) return `null` until appointment module activation.
- **Rationale**: Separates real-time patient-facing queue status from internal management state.

## 9. Phase A Resolution of Analyzer & Test Issues
- **AuthController.initSession**: Added public `initSession()` method to `AuthController` for explicit session initialization in tests without duplicate listener logic.
- **ClinicOperationsPublicModel.toJson**: Added `toJson()` with exact snake_case keys matching `fromJson`.
- **AppFormatters.formatRupiah**: Added `formatRupiah` using `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)` with non-breaking space normalization.
- **Flow Control Lint**: Enclosed all single-line `if` statements in curly braces `{}` across `document_upload_tile.dart`.

## 10. Supabase Sign-up Database Failures
- **Decision**: Add `0003_profiles_account_type.sql` as a forward-only migration to add and constrain `profiles.account_type`, backfilling existing null values as `patient`.
- **Rationale**: Supabase Auth logs confirmed that `handle_new_user()` inserts `account_type` but the deployed `profiles` table did not have that column. The original migration uses `CREATE TABLE IF NOT EXISTS`, which does not reconcile a pre-existing table with its declared columns. Do not modify migrations `0001` or `0002`; apply migration `0003` to the Supabase project before retrying signup.

## 11. Clinic UX Simplification
- **Decision**: Keep clinic-management navigation focused on the operational home, operations, staff, reviews/feedback, profile/legal, and settings. Legacy demo destinations stay inaccessible while the demo feature flag is disabled; authentication and verification gates remain authoritative.
- **Rationale**: Clinic administrators should reach actionable verification and daily-operation tasks without seeing unrelated demo modules. Status changes continue to use existing controller/repository RPC paths.

## 12. Clinic Location Map Tiles
- **Decision**: The onboarding location picker uses OpenStreetMap tiles and displays attribution with a link to the OSM copyright page. The map only writes coordinates after an explicit map tap; GPS and manual coordinate entry remain available.
- **Rationale and limitation**: `tile.openstreetmap.org` is a community-operated public service with a usage policy and no production availability guarantee. The app must not bulk-download or prefetch tiles. For sustained production traffic or offline use, configure a compliant hosted tile provider and follow its licensing, attribution, and caching requirements.

## 13. Automatic RME Configuration and Recommendations
- **Decision**: Rekam Medis (RME) is configured automatically as `emr_app_type=internal`, `emr_app_name=Prometheon Clinic OS`, and confirmed when clinic onboarding data is loaded. The manual RME step is hidden from the registration wizard; separate profile settings remain available. This is not a claim of certification, official status, or SATUSEHAT integration.
- **Rationale**: Prometheon is the clinic's internal RME, so the onboarding flow must not ask clinics to re-enter its name. RME does not determine whether registration can be submitted. SOP and gallery uploads are optional recommendations rather than submission requirements; existing clinic-photo documents remain view/delete-only.
- **Security**: The SATUSEHAT API code is requested only after clinic verification (or while under review), submitted directly to the write-only RPC, and cleared from the dialog controller after closing. It is not stored in client models, preferences, or logs.
- **User guidance**: When the UI mentions the legal duty to use an electronic medical record, it also says “Pastikan sesuai ketentuan yang berlaku.”

## 14. Server-Side Onboarding Readiness
- **Decision**: The `clinic_onboarding_status` RPC and submission gate use the same five required sections as the wizard. RME remains informational and cannot block `submit_clinic_for_review`.
- **Rationale**: The client can display every section as complete while an older deployed RPC still rejects submission for legacy RME requirements. Migration `0005_align_onboarding_submit_readiness.sql` reapplies the server-side status function and reloads the PostgREST schema cache.
- **Operations**: Apply forward migrations `0004` and `0005` to the Supabase project before retrying submission. An `onboarding_incomplete` response containing only legacy RME requirements is surfaced as a migration action rather than a generic form error.
