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
- **Decision**: SATUSEHAT API key is stored in `clinic_integration_secrets` with RLS completely revoking `select` permissions from `anon` and `authenticated` roles. Saving is strictly write-only via `save_clinic_integration_secret` RPC.
- **Rationale**: Prevents client-side exposure of third-party integration secrets while allowing connection verification.

## 7. Sensitive Health Worker Data Separation & Masking
- **Decision**: Sensitive personal details (NIK 16 digits, NPWP 15-16 digits, home address, birth date) are stored in `health_worker_private` with foreign key cascade. UI lists display masked values (showing only last 4 digits) and omit sensitive fields from logs.
- **Rationale**: Protects PII and medical staff privacy in accordance with healthcare governance.

## 8. Shared Public Operations Layer
- **Decision**: View `clinic_operations_public` exposes only verified and published clinics. Public preview for clinic managers is fetched via `clinic_public_preview` RPC. Unpopulated operational fields (such as `next_available_slot`) return `null` until appointment module activation.
- **Rationale**: Separates real-time patient-facing queue status from internal management state.
