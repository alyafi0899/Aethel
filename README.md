# Prometheon Clinic OS — Production Flutter + Supabase Application

Prometheon Clinic OS is a full-featured, production-ready Flutter healthcare operations and clinical management application powered by Supabase.

---

## 🌟 Key Features

- **Role-Based Access Control (RBAC)**: Dedicated workflows and views for **Admin** (full administrative, financial, and facility control) and **Nurse / Perawat** (clinical triage, vital signs, patient care, room management).
- **Live Supabase Database Persistence**: Real-time integration with Postgres database tables (`appointments`, `screening_sessions`, `patients`, `doctors`, `rooms`, `invoices`, `notifications`, `audit_logs`).
- **Row Level Security (RLS)**: Enforced data safety using indexed SECURITY DEFINER helpers (`auth_role()`, `auth_facility_id()`, `has_permission()`).
- **Append-Only Audit Trail**: Immutable logging of operational actions across all clinical and administrative workflows.
- **Administrative User Management**: Server-side user creation via Supabase Edge Function (`admin-create-user`).

---

## 🚀 Quick Start & Running Locally

### 1. Prerequisites
- Flutter SDK 3.22+ installed
- Supabase CLI installed (for local database migrations)

### 2. Configure Environment
Copy `env.example.json` to `env.json`:
```bash
cp env.example.json env.json
```
Edit `env.json` with your Supabase credentials:
```json
{
  "SUPABASE_URL": "https://qshmccjazkupvbelyjhi.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_0FJxIsGzTDi8AeIj42utSQ_IPEKBWkZ",
  "USE_MOCK": false,
  "DEFAULT_LOCALE": "id_ID",
  "DEFAULT_CURRENCY": "IDR",
  "DEFAULT_TIMEZONE": "Asia/Jakarta"
}
```

### 3. Run Application
```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

---

## 🗄️ Supabase Database Setup & Migrations

### 1. Link to Supabase Project
```bash
supabase link --project-ref qshmccjazkupvbelyjhi
```

### 2. Apply Migrations
Run database migrations sequentially:
```bash
supabase db push
```
Or execute the following migration files in Order:
1. `supabase/migrations/01_schema.sql` (Tables, Enums, Triggers, Views)
2. `supabase/migrations/02_security_rls.sql` (Row Level Security & Policies)
3. `supabase/migrations/03_rpcs.sql` (Atomic Stored Procedures & Logic)

### 3. Seed Development Data (Optional)
```bash
supabase db execute --file supabase/seed.sql
```

### 4. Deploy Edge Functions
```bash
supabase functions deploy admin-create-user --no-verify-jwt
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

---

## 🔑 Initial Admin Account Bootstrap Instructions

1. Log in to the [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **Authentication -> Users** and click **Add User -> Create User**.
3. Create a user with email `admin@prometheon.health` and password.
4. Run the following SQL query in the **SQL Editor** to grant Administrator role:
```sql
INSERT INTO profiles (id, facility_id, full_name, role, is_active)
VALUES (
  'YOUR_USER_UUID',
  'a0000000-0000-0000-0000-000000000001',
  'Elena Cruz',
  'admin',
  TRUE
) ON CONFLICT (id) DO UPDATE SET role = 'admin';
```

---

## 🔒 Recommended Auth Settings in Supabase Dashboard

To ensure production security compliance:
1. Disable Public Sign-ups (**Authentication -> Settings -> Disable Allow new users to sign up**).
2. Enable Email Confirmation (**Authentication -> Settings -> Enable Confirm email**).
3. Set minimum password length to 10 characters.
4. Enable Leaked Password Protection.

---

## 🧪 Testing & Code Quality

Run code formatting, linter analysis, and automated test suite:
```bash
dart format .
flutter analyze
flutter test test/widget_test.dart test/auth_role_test.dart
```
