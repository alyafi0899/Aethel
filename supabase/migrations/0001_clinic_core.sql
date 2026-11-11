-- =====================================================================
--  PROMETHEON  -  0001_clinic_core.sql
--  Cakupan: autentikasi & registrasi klinik, data dasar, layanan &
--  fasilitas, administrasi & legal, sistem RME, penanggung jawab &
--  tenaga kesehatan, layer operasional (internal + dibagikan ke publik).
--  Aman dijalankan ulang (idempotent). Jalankan di Supabase SQL Editor.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ENUM
-- ---------------------------------------------------------------------
do $$
declare
  spec  text;
  tname text;
  vals  text;
begin
  foreach spec in array array[
    'clinic_status|draft,submitted,under_review,verified,rejected,suspended',
    'clinic_role|owner,admin',
    'legal_entity_type|individual,pt,foundation,other',
    'facility_kind|waiting_room,treatment_room,consultation_room,laboratory,pharmacy,registration,other',
    'facility_unit_status|available,occupied,maintenance',
    'equipment_category|medical,non_medical',
    'document_type|sio,npwp,fasyankes_registration,deed_of_establishment,registration_request_letter,quality_commitment_statement,bpjs_cooperation_proof,org_structure,service_sop,clinic_photo,educational_poster,other',
    'worker_document_type|profile_photo,ktp_scan,str_scan,sip_scan,diploma_scan,competency_certificate_scan,other',
    'document_review_status|pending,approved,rejected',
    'health_worker_type|doctor,nurse',
    'duty_status|available,busy,off',
    'queue_process_status|active,paused,closed',
    'facility_operating_status|open,closed,maintenance',
    'emr_app_type|internal,third_party,none'
  ] loop
    tname := split_part(spec, '|', 1);
    vals  := split_part(spec, '|', 2);
    if not exists (
      select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
      where n.nspname = 'public' and t.typname = tname
    ) then
      execute format(
        'create type public.%I as enum (%s)',
        tname,
        (select string_agg(quote_literal(v), ',') from unnest(string_to_array(vals, ',')) as v)
      );
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 2. FUNGSI UMUM
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- 3. PROFIL, ADMIN PLATFORM, KLINIK, ANGGOTA KLINIK
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  full_name    text,
  phone        text,
  account_type text not null default 'patient'
               check (account_type in ('clinic', 'patient', 'health_worker')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table if not exists public.platform_admins (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.clinics (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references auth.users (id),
  status          public.clinic_status not null default 'draft',
  is_published    boolean not null default false,
  onboarding_step smallint not null default 1 check (onboarding_step between 1 and 6),

  -- Data dasar
  clinic_name        text,
  legal_entity_type  public.legal_entity_type,
  address_full       text,
  latitude           numeric(9, 6) check (latitude  is null or latitude  between -90  and 90),
  longitude          numeric(9, 6) check (longitude is null or longitude between -180 and 180),
  phone              text check (phone is null or phone ~ '^\+?[0-9]{8,15}$'),
  email              text,
  sio_number         text,                 -- Surat Izin Operasional (SIO)
  sio_expiry         date,
  npwp               text check (npwp is null or npwp ~ '^[0-9]{15,16}$'),
  fasyankes_code     text,                 -- kode registrasi fasyankes Kemenkes
  deed_number        text,                 -- akta pendirian (PT / yayasan)

  -- Administrasi & legal
  bpjs_registered    boolean not null default false,
  bpjs_facility_code text,

  -- Verifikasi
  submitted_at     timestamptz,
  reviewed_at      timestamptz,
  reviewed_by      uuid references auth.users (id),
  rejection_reason text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists clinics_owner_unique on public.clinics (owner_id);
create unique index if not exists clinics_fasyankes_unique
  on public.clinics (fasyankes_code) where fasyankes_code is not null;
create index if not exists clinics_status_idx on public.clinics (status);

create table if not exists public.clinic_members (
  clinic_id  uuid not null references public.clinics (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       public.clinic_role not null default 'admin',
  created_at timestamptz not null default now(),
  primary key (clinic_id, user_id)
);
create index if not exists clinic_members_user_idx on public.clinic_members (user_id);

-- Helper otorisasi (security definer agar tidak rekursif dengan RLS)
create or replace function public.is_platform_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.platform_admins p where p.user_id = auth.uid());
$$;

create or replace function public.is_clinic_member(p_clinic_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.clinic_members m
    where m.clinic_id = p_clinic_id and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_clinic_owner(p_clinic_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.clinic_members m
    where m.clinic_id = p_clinic_id and m.user_id = auth.uid() and m.role = 'owner'
  );
$$;

-- ---------------------------------------------------------------------
-- 4. DATA LAYANAN & FASILITAS
-- ---------------------------------------------------------------------
create table if not exists public.clinic_services (          -- jenis layanan
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid not null references public.clinics (id) on delete cascade,
  service_type text not null,                                 -- "Umum", "Gigi", "Anak", ...
  description  text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (clinic_id, service_type)
);

create table if not exists public.clinic_facilities (        -- fasilitas & prasarana
  id         uuid primary key default gen_random_uuid(),
  clinic_id  uuid not null references public.clinics (id) on delete cascade,
  name       text not null,
  kind       public.facility_kind not null default 'consultation_room',
  is_room    boolean not null default true,
  capacity   integer check (capacity is null or capacity >= 0),
  status     public.facility_unit_status not null default 'available',
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clinic_equipment (         -- peralatan medis & non-medis
  id         uuid primary key default gen_random_uuid(),
  clinic_id  uuid not null references public.clinics (id) on delete cascade,
  name       text not null,
  category   public.equipment_category not null default 'medical',
  quantity   integer not null default 1 check (quantity >= 0),
  condition  text,
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clinic_medicines (         -- daftar obat tersedia
  id          uuid primary key default gen_random_uuid(),
  clinic_id   uuid not null references public.clinics (id) on delete cascade,
  name        text not null,
  dosage_form text,
  strength    text,
  is_available boolean not null default true,
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.clinic_operating_hours (   -- jam operasional
  id          uuid primary key default gen_random_uuid(),
  clinic_id   uuid not null references public.clinics (id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 1 and 7),   -- 1 = Senin ... 7 = Minggu
  is_open     boolean not null default false,
  open_time   time,
  close_time  time,
  break_start time,
  break_end   time,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (clinic_id, day_of_week),
  check (not is_open or (open_time is not null and close_time is not null and close_time > open_time)),
  check (break_start is null or break_end is null or break_end > break_start)
);

-- ---------------------------------------------------------------------
-- 5. PENANGGUNG JAWAB & TENAGA KESEHATAN
-- ---------------------------------------------------------------------
create table if not exists public.health_workers (
  id                  uuid primary key default gen_random_uuid(),
  clinic_id           uuid not null references public.clinics (id) on delete cascade,
  user_id             uuid references auth.users (id) on delete set null,   -- tautan akun login (tahap berikutnya)
  worker_type         public.health_worker_type not null default 'doctor',
  is_person_in_charge boolean not null default false,                       -- penanggung jawab klinik
  is_active           boolean not null default true,
  on_duty_status      public.duty_status not null default 'off',

  -- Data profesional
  full_name       text not null,
  title_degree    text,                  -- gelar
  specialization  text,                  -- spesialisasi
  str_number      text,                  -- Surat Tanda Registrasi
  str_expiry      date,
  sip_number      text,                  -- Surat Izin Praktik
  sip_expiry      date,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, clinic_id)
);
create index if not exists health_workers_clinic_idx on public.health_workers (clinic_id);

-- Data pribadi sensitif dipisah (NIK, NPWP, alamat, tanggal lahir)
create table if not exists public.health_worker_private (
  worker_id  uuid primary key,
  clinic_id  uuid not null,
  phone      text check (phone is null or phone ~ '^\+?[0-9]{8,15}$'),
  email      text,
  nik        text check (nik  is null or nik  ~ '^[0-9]{16}$'),
  npwp       text check (npwp is null or npwp ~ '^[0-9]{15,16}$'),
  home_address text,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (worker_id, clinic_id) references public.health_workers (id, clinic_id) on delete cascade
);

create table if not exists public.health_worker_educations (   -- riwayat pendidikan kedokteran
  id             uuid primary key default gen_random_uuid(),
  worker_id      uuid not null,
  clinic_id      uuid not null,
  institution    text not null,
  degree         text,
  field_of_study text,
  start_year     smallint,
  end_year       smallint,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  foreign key (worker_id, clinic_id) references public.health_workers (id, clinic_id) on delete cascade
);

create table if not exists public.health_worker_experiences (  -- pengalaman kerja
  id          uuid primary key default gen_random_uuid(),
  worker_id   uuid not null,
  clinic_id   uuid not null,
  workplace   text not null,
  position    text,
  start_date  date,
  end_date    date,
  description text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  foreign key (worker_id, clinic_id) references public.health_workers (id, clinic_id) on delete cascade
);

create table if not exists public.health_worker_certificates ( -- sertifikat & pelatihan (tambahan)
  id          uuid primary key default gen_random_uuid(),
  worker_id   uuid not null,
  clinic_id   uuid not null,
  name        text not null,
  issuer      text,
  issued_date date,
  expiry_date date,
  file_path   text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  foreign key (worker_id, clinic_id) references public.health_workers (id, clinic_id) on delete cascade
);

create table if not exists public.health_worker_documents (    -- dokumen pendukung yang diunggah
  id            uuid primary key default gen_random_uuid(),
  worker_id     uuid not null,
  clinic_id     uuid not null,
  doc_type      public.worker_document_type not null,
  file_path     text not null,
  file_name     text,
  mime_type     text,
  size_bytes    bigint,
  review_status public.document_review_status not null default 'pending',
  review_note   text,
  uploaded_by   uuid default auth.uid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  foreign key (worker_id, clinic_id) references public.health_workers (id, clinic_id) on delete cascade
);

-- ---------------------------------------------------------------------
-- 6. ADMINISTRASI & LEGAL, SISTEM RME
-- ---------------------------------------------------------------------
create table if not exists public.clinic_documents (
  id            uuid primary key default gen_random_uuid(),
  clinic_id     uuid not null references public.clinics (id) on delete cascade,
  doc_type      public.document_type not null,
  file_path     text not null,
  file_name     text,
  mime_type     text,
  size_bytes    bigint,
  review_status public.document_review_status not null default 'pending',
  review_note   text,
  uploaded_by   uuid default auth.uid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists clinic_documents_clinic_idx on public.clinic_documents (clinic_id, doc_type);

create table if not exists public.clinic_org_structure (       -- struktur organisasi klinik
  id               uuid primary key default gen_random_uuid(),
  clinic_id        uuid not null references public.clinics (id) on delete cascade,
  person_name      text not null,
  position         text not null,
  health_worker_id uuid references public.health_workers (id) on delete set null,
  parent_id        uuid references public.clinic_org_structure (id) on delete set null,
  sort_order       integer not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table if not exists public.clinic_emr_settings (        -- sistem rekam medis elektronik
  clinic_id                 uuid primary key references public.clinics (id) on delete cascade,
  emr_app_name              text,
  emr_app_type              public.emr_app_type not null default 'none',
  satusehat_organization_id text,
  satusehat_connected       boolean not null default false,   -- hanya diubah lewat RPC
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

-- Kode API SATUSEHAT: tanpa policy RLS sama sekali -> tidak bisa dibaca dari client.
create table if not exists public.clinic_integration_secrets (
  clinic_id  uuid not null references public.clinics (id) on delete cascade,
  provider   text not null check (provider in ('satusehat')),
  secret     text not null,
  updated_at timestamptz not null default now(),
  primary key (clinic_id, provider)
);
alter table public.clinic_integration_secrets enable row level security;
revoke all on public.clinic_integration_secrets from anon, authenticated;

-- ---------------------------------------------------------------------
-- 7. LAYER OPERASIONAL KLINIK (INTERNAL)
-- ---------------------------------------------------------------------
create table if not exists public.clinic_operations_internal (
  clinic_id                     uuid primary key references public.clinics (id) on delete cascade,
  clinic_name                   text,
  total_queues                  integer not null default 0 check (total_queues >= 0),
  current_queue_number          integer not null default 0 check (current_queue_number >= 0),
  queue_process_status          public.queue_process_status not null default 'closed',   -- active | paused | closed
  average_wait_time             integer not null default 0 check (average_wait_time >= 0), -- menit
  total_registered_patients     integer not null default 0 check (total_registered_patients >= 0),
  total_daily_visitors          integer not null default 0 check (total_daily_visitors >= 0),
  total_doctors_available       integer not null default 0,
  active_rooms_count            integer not null default 0,
  available_rooms_count         integer not null default 0,
  daily_appointments_count      integer not null default 0 check (daily_appointments_count >= 0),
  cancelled_appointments_count  integer not null default 0 check (cancelled_appointments_count >= 0),
  service_types                 text[] not null default '{}',                              -- "Umum", "Gigi", "Anak"
  facility_status               public.facility_operating_status not null default 'closed', -- open | closed | maintenance
  staff_on_duty_count           integer not null default 0,
  total_completed_consultations integer not null default 0 check (total_completed_consultations >= 0),
  last_update_timestamp         timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 8. AUDIT LOG (append-only)
-- ---------------------------------------------------------------------
create table if not exists public.clinic_audit_logs (
  id         bigint generated always as identity primary key,
  clinic_id  uuid not null,
  actor_id   uuid default auth.uid(),
  action     text not null,
  entity     text not null,
  entity_id  text,
  created_at timestamptz not null default now()
);
create index if not exists clinic_audit_logs_clinic_idx on public.clinic_audit_logs (clinic_id, created_at desc);

create or replace function public.log_clinic_change()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  r jsonb := to_jsonb(case when tg_op = 'DELETE' then old else new end);
  v_clinic uuid;
begin
  v_clinic := coalesce(
    (r ->> 'clinic_id')::uuid,
    case when tg_table_name = 'clinics' then (r ->> 'id')::uuid end
  );
  if v_clinic is not null then
    insert into public.clinic_audit_logs (clinic_id, actor_id, action, entity, entity_id)
    values (v_clinic, auth.uid(), tg_op, tg_table_name,
            coalesce(r ->> 'id', r ->> 'worker_id', r ->> 'clinic_id'));
  end if;
  return null;
end $$;

-- ---------------------------------------------------------------------
-- 9. TRIGGER: updated_at
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','clinics','clinic_services','clinic_facilities','clinic_equipment',
    'clinic_medicines','clinic_operating_hours','health_workers','health_worker_private',
    'health_worker_educations','health_worker_experiences','health_worker_certificates',
    'health_worker_documents','clinic_documents','clinic_org_structure','clinic_emr_settings'
  ] loop
    execute format('drop trigger if exists %I on public.%I', t || '_set_updated_at', t);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      t || '_set_updated_at', t);
  end loop;
end $$;

-- Audit
do $$
declare t text;
begin
  foreach t in array array[
    'clinics','clinic_documents','clinic_org_structure','clinic_emr_settings',
    'health_workers','health_worker_private','health_worker_documents'
  ] loop
    execute format('drop trigger if exists %I on public.%I', t || '_audit', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function public.log_clinic_change()',
      t || '_audit', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 10. PENGAMAN KOLOM (workflow hanya lewat RPC)
-- ---------------------------------------------------------------------
create or replace function public.protect_clinic_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('app.clinic_workflow', true), '') = '1' then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    new.owner_id         := old.owner_id;
    new.status           := old.status;
    new.submitted_at     := old.submitted_at;
    new.reviewed_at      := old.reviewed_at;
    new.reviewed_by      := old.reviewed_by;
    new.rejection_reason := old.rejection_reason;

    if new.is_published and old.status <> 'verified' then
      new.is_published := false;
    end if;

    -- Mengubah data legal inti setelah terverifikasi -> kembali ditinjau.
    if old.status = 'verified' and (
         new.clinic_name    is distinct from old.clinic_name or
         new.sio_number     is distinct from old.sio_number or
         new.npwp           is distinct from old.npwp or
         new.fasyankes_code is distinct from old.fasyankes_code) then
      new.status       := 'under_review';
      new.is_published := false;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists clinics_protect_columns on public.clinics;
create trigger clinics_protect_columns
  before update on public.clinics
  for each row execute function public.protect_clinic_columns();

create or replace function public.protect_review_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('app.clinic_workflow', true), '') = '1'
     or public.is_platform_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.review_status := 'pending';
    new.review_note   := null;
  else
    new.review_status := old.review_status;
    new.review_note   := old.review_note;
  end if;
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['clinic_documents', 'health_worker_documents'] loop
    execute format('drop trigger if exists %I on public.%I', t || '_protect_review', t);
    execute format(
      'create trigger %I before insert or update on public.%I for each row execute function public.protect_review_columns()',
      t || '_protect_review', t);
  end loop;
end $$;

create or replace function public.protect_emr_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(current_setting('app.clinic_workflow', true), '') <> '1' then
    if tg_op = 'INSERT' then
      new.satusehat_connected := false;
    else
      new.satusehat_connected := old.satusehat_connected;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists clinic_emr_protect on public.clinic_emr_settings;
create trigger clinic_emr_protect
  before insert or update on public.clinic_emr_settings
  for each row execute function public.protect_emr_columns();

-- ---------------------------------------------------------------------
-- 11. SIGN-UP: akun klinik -> klinik draft + keanggotaan owner
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_type      text := coalesce(new.raw_user_meta_data ->> 'account_type', 'patient');
  v_clinic_id uuid;
begin
  if v_type not in ('clinic', 'patient', 'health_worker') then
    v_type := 'patient';
  end if;

  insert into public.profiles (id, full_name, phone, account_type)
  values (new.id,
          nullif(new.raw_user_meta_data ->> 'full_name', ''),
          nullif(new.raw_user_meta_data ->> 'phone', ''),
          v_type)
  on conflict (id) do nothing;

  if v_type = 'clinic' then
    insert into public.clinics (owner_id, clinic_name, email)
    values (new.id, nullif(new.raw_user_meta_data ->> 'clinic_name', ''), new.email)
    returning id into v_clinic_id;

    insert into public.clinic_members (clinic_id, user_id, role)
    values (v_clinic_id, new.id, 'owner');
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Baris pendamping saat klinik dibuat: operasional, RME, 7 baris jam operasional
create or replace function public.init_clinic_children()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.clinic_operations_internal (clinic_id, clinic_name)
  values (new.id, new.clinic_name) on conflict do nothing;

  insert into public.clinic_emr_settings (clinic_id)
  values (new.id) on conflict do nothing;

  insert into public.clinic_operating_hours (clinic_id, day_of_week, is_open)
  select new.id, d, false from generate_series(1, 7) as d
  on conflict do nothing;
  return new;
end $$;

drop trigger if exists clinics_init_children on public.clinics;
create trigger clinics_init_children
  after insert on public.clinics
  for each row execute function public.init_clinic_children();

-- ---------------------------------------------------------------------
-- 12. OPERASIONAL: hitung ulang field turunan
-- ---------------------------------------------------------------------
create or replace function public.refresh_clinic_operations(p_clinic_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  update public.clinic_operations_internal o set
    clinic_name = (select c.clinic_name from public.clinics c where c.id = p_clinic_id),
    total_doctors_available = (
      select count(*) from public.health_workers w
      where w.clinic_id = p_clinic_id and w.is_active
        and w.worker_type = 'doctor' and w.on_duty_status = 'available'),
    staff_on_duty_count = (
      select count(*) from public.health_workers w
      where w.clinic_id = p_clinic_id and w.is_active
        and w.on_duty_status in ('available', 'busy')),
    active_rooms_count = (
      select count(*) from public.clinic_facilities f
      where f.clinic_id = p_clinic_id and f.is_room and f.status <> 'maintenance'),
    available_rooms_count = (
      select count(*) from public.clinic_facilities f
      where f.clinic_id = p_clinic_id and f.is_room and f.status = 'available'),
    service_types = coalesce((
      select array_agg(s.service_type order by s.service_type)
      from public.clinic_services s
      where s.clinic_id = p_clinic_id and s.is_active), '{}'),
    last_update_timestamp = now()
  where o.clinic_id = p_clinic_id;
end $$;

create or replace function public.trg_refresh_clinic_ops()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  perform public.refresh_clinic_operations(
    case when tg_op = 'DELETE' then old.clinic_id else new.clinic_id end);
  return null;
end $$;

do $$
declare t text;
begin
  foreach t in array array['clinic_services', 'clinic_facilities', 'health_workers'] loop
    execute format('drop trigger if exists %I on public.%I', t || '_refresh_ops', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function public.trg_refresh_clinic_ops()',
      t || '_refresh_ops', t);
  end loop;
end $$;

create or replace function public.trg_refresh_ops_on_clinic()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if new.clinic_name is distinct from old.clinic_name then
    perform public.refresh_clinic_operations(new.id);
  end if;
  return null;
end $$;

drop trigger if exists clinics_refresh_ops on public.clinics;
create trigger clinics_refresh_ops
  after update on public.clinics
  for each row execute function public.trg_refresh_ops_on_clinic();

-- ---------------------------------------------------------------------
-- 13. LAYER OPERASIONAL KLINIK (DIBAGIKAN KE PUBLIK)
--     View internal (tanpa filter) tidak bisa diakses client; view publik
--     hanya memuat klinik terverifikasi + dipublikasikan.
-- ---------------------------------------------------------------------
drop view if exists public.clinic_operations_public;
drop view if exists public.clinic_operations_public_all;
drop function if exists public.build_public_ops(uuid);

create view public.clinic_operations_public_all as
select
  c.id                                         as clinic_id,
  coalesce(o.clinic_name, c.clinic_name)       as clinic_name,
  o.service_types                              as service_types,
  o.current_queue_number                       as current_queue_number,
  o.average_wait_time                          as estimated_wait_time,
  coalesce((
    select jsonb_agg(jsonb_build_object(
             'name', w.full_name,
             'title', w.title_degree,
             'specialization', w.specialization))
    from public.health_workers w
    where w.clinic_id = c.id and w.is_active
      and w.worker_type = 'doctor' and w.on_duty_status = 'available'
  ), '[]'::jsonb)                              as available_doctors,
  null::timestamptz                            as next_available_slot,   -- diisi modul jadwal/appointment (tahap berikutnya)
  case when o.facility_status = 'open' then 'open' else 'closed' end as clinic_status,
  (select jsonb_build_object(
            'open', h.open_time, 'close', h.close_time,
            'break_start', h.break_start, 'break_end', h.break_end)
     from public.clinic_operating_hours h
    where h.clinic_id = c.id and h.is_open
      and h.day_of_week = extract(isodow from (now() at time zone 'Asia/Jakarta'))::int
  )                                            as today_operational_hours,
  jsonb_build_object('latitude', c.latitude, 'longitude', c.longitude) as location_coordinates,
  c.phone                                      as contact_number,
  o.last_update_timestamp                      as last_update_timestamp
from public.clinics c
join public.clinic_operations_internal o on o.clinic_id = c.id;

revoke all on public.clinic_operations_public_all from public, anon, authenticated;

create view public.clinic_operations_public as
select a.*
from public.clinic_operations_public_all a
join public.clinics c on c.id = a.clinic_id
where c.status = 'verified' and c.is_published;

grant select on public.clinic_operations_public to anon, authenticated;

-- Pratinjau untuk pengelola klinik (tanpa syarat verified/published)
create or replace function public.clinic_public_preview(p_clinic_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare v jsonb;
begin
  if not (public.is_clinic_member(p_clinic_id) or public.is_platform_admin()) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select to_jsonb(a) into v
    from public.clinic_operations_public_all a
   where a.clinic_id = p_clinic_id;
  return v;
end $$;

-- ---------------------------------------------------------------------
-- 14. RPC: STATUS ONBOARDING, SUBMIT, REVIEW, PUBLISH, RAHASIA
-- ---------------------------------------------------------------------
create or replace function public.clinic_onboarding_status(p_clinic_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  c        public.clinics;
  e        public.clinic_emr_settings;
  m_basic  text[] := '{}';
  m_serv   text[] := '{}';
  m_legal  text[] := '{}';
  m_emr    text[] := '{}';
  m_staff  text[] := '{}';

begin
  if not (public.is_clinic_member(p_clinic_id) or public.is_platform_admin()) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  select * into c from public.clinics where id = p_clinic_id;
  if not found then
    raise exception 'clinic_not_found';
  end if;
  select * into e from public.clinic_emr_settings where clinic_id = p_clinic_id;

  -- 1. Data dasar
  if coalesce(c.clinic_name, '')     = '' then m_basic := array_append(m_basic, 'clinic_name'); end if;
  if c.legal_entity_type is null         then m_basic := array_append(m_basic, 'legal_entity_type'); end if;
  if coalesce(c.address_full, '')    = '' then m_basic := array_append(m_basic, 'address_full'); end if;
  if c.latitude is null or c.longitude is null then m_basic := array_append(m_basic, 'coordinates'); end if;
  if coalesce(c.phone, '')           = '' then m_basic := array_append(m_basic, 'phone'); end if;
  if coalesce(c.email, '')           = '' then m_basic := array_append(m_basic, 'email'); end if;
  if coalesce(c.sio_number, '')      = '' then m_basic := array_append(m_basic, 'sio_number'); end if;
  if c.sio_expiry is null or c.sio_expiry < current_date then m_basic := array_append(m_basic, 'sio_expiry'); end if;
  if coalesce(c.npwp, '')            = '' then m_basic := array_append(m_basic, 'npwp'); end if;
  if coalesce(c.fasyankes_code, '')  = '' then m_basic := array_append(m_basic, 'fasyankes_code'); end if;
  if c.legal_entity_type in ('pt', 'foundation') and coalesce(c.deed_number, '') = '' then
    m_basic := array_append(m_basic, 'deed_number');
  end if;
  if not exists (select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'sio') then
    m_basic := array_append(m_basic, 'doc:sio');
  end if;
  if c.legal_entity_type in ('pt', 'foundation') and not exists (
       select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'deed_of_establishment') then
    m_basic := array_append(m_basic, 'doc:deed_of_establishment');
  end if;

  -- 2. Layanan & fasilitas
  if not exists (select 1 from public.clinic_services s where s.clinic_id = p_clinic_id and s.is_active) then
    m_serv := array_append(m_serv, 'services');
  end if;
  if not exists (select 1 from public.clinic_facilities f where f.clinic_id = p_clinic_id) then
    m_serv := array_append(m_serv, 'facilities');
  end if;
  if not exists (select 1 from public.clinic_equipment q where q.clinic_id = p_clinic_id) then
    m_serv := array_append(m_serv, 'equipment');
  end if;
  if not exists (select 1 from public.clinic_operating_hours h where h.clinic_id = p_clinic_id and h.is_open) then
    m_serv := array_append(m_serv, 'operating_hours');
  end if;

  -- 3. Administrasi & legal
  if not exists (select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'registration_request_letter') then
    m_legal := array_append(m_legal, 'doc:registration_request_letter');
  end if;
  if not exists (select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'quality_commitment_statement') then
    m_legal := array_append(m_legal, 'doc:quality_commitment_statement');
  end if;
  if not exists (select 1 from public.clinic_org_structure o where o.clinic_id = p_clinic_id) then
    m_legal := array_append(m_legal, 'org_structure');
  end if;
  if c.bpjs_registered then
    if coalesce(c.bpjs_facility_code, '') = '' then m_legal := array_append(m_legal, 'bpjs_facility_code'); end if;
    if not exists (select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'bpjs_cooperation_proof') then
      m_legal := array_append(m_legal, 'doc:bpjs_cooperation_proof');
    end if;
  end if;

  -- 4. Sistem RME
  if coalesce(e.emr_app_name, '') = '' then m_emr := array_append(m_emr, 'emr_app_name'); end if;
  if not exists (select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'service_sop') then
    m_emr := array_append(m_emr, 'doc:service_sop');
  end if;
  if not exists (select 1 from public.clinic_documents d where d.clinic_id = p_clinic_id and d.doc_type = 'clinic_photo') then
    m_emr := array_append(m_emr, 'doc:clinic_photo');
  end if;

  -- 5. Penanggung jawab & tenaga kesehatan
  if not exists (select 1 from public.health_workers w where w.clinic_id = p_clinic_id and w.is_active and w.is_person_in_charge) then
    m_staff := array_append(m_staff, 'person_in_charge');
  end if;
  if not exists (
       select 1 from public.health_workers w
       where w.clinic_id = p_clinic_id and w.is_active and w.worker_type = 'doctor'
         and coalesce(w.str_number, '') <> '' and coalesce(w.sip_number, '') <> '') then
    m_staff := array_append(m_staff, 'doctor_with_str_sip');
  end if;

  return jsonb_build_object(
    'status', c.status,
    'basic_data',          jsonb_build_object('complete', cardinality(m_basic) = 0, 'missing', to_jsonb(m_basic)),
    'services_facilities', jsonb_build_object('complete', cardinality(m_serv)  = 0, 'missing', to_jsonb(m_serv)),
    'admin_legal',         jsonb_build_object('complete', cardinality(m_legal) = 0, 'missing', to_jsonb(m_legal)),
    'emr_system',          jsonb_build_object('complete', cardinality(m_emr)   = 0, 'missing', to_jsonb(m_emr)),
    'health_workers',      jsonb_build_object('complete', cardinality(m_staff) = 0, 'missing', to_jsonb(m_staff)),
    'ready_to_submit', (
      cardinality(m_basic) + cardinality(m_serv) + cardinality(m_legal) +
      cardinality(m_emr) + cardinality(m_staff) = 0)
  );
end $$;

create or replace function public.submit_clinic_for_review(p_clinic_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_status public.clinic_status;
  v_check  jsonb;
begin
  if not public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  select status into v_status from public.clinics where id = p_clinic_id;
  if v_status is null then raise exception 'clinic_not_found'; end if;
  if v_status not in ('draft', 'rejected') then
    raise exception 'invalid_status_for_submit' using detail = v_status::text;
  end if;

  v_check := public.clinic_onboarding_status(p_clinic_id);
  if not (v_check ->> 'ready_to_submit')::boolean then
    raise exception 'onboarding_incomplete' using detail = v_check::text;
  end if;

  perform set_config('app.clinic_workflow', '1', true);
  update public.clinics
     set status = 'submitted', submitted_at = now(), rejection_reason = null
   where id = p_clinic_id;
  perform set_config('app.clinic_workflow', '', true);

  return public.clinic_onboarding_status(p_clinic_id);
end $$;

create or replace function public.review_clinic(p_clinic_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if not p_approve and coalesce(p_note, '') = '' then
    raise exception 'rejection_reason_required';
  end if;

  perform set_config('app.clinic_workflow', '1', true);
  update public.clinics
     set status = case when p_approve then 'verified'::public.clinic_status else 'rejected'::public.clinic_status end,
         reviewed_at = now(),
         reviewed_by = auth.uid(),
         rejection_reason = case when p_approve then null else p_note end
   where id = p_clinic_id;
  perform set_config('app.clinic_workflow', '', true);
end $$;

create or replace function public.set_clinic_published(p_clinic_id uuid, p_published boolean)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare v_status public.clinic_status;
begin
  if not public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select status into v_status from public.clinics where id = p_clinic_id;
  if p_published and v_status is distinct from 'verified' then
    raise exception 'clinic_not_verified';
  end if;

  perform set_config('app.clinic_workflow', '1', true);
  update public.clinics set is_published = p_published where id = p_clinic_id;
  perform set_config('app.clinic_workflow', '', true);
end $$;

create or replace function public.save_clinic_integration_secret(
  p_clinic_id uuid, p_provider text, p_secret text)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_provider <> 'satusehat' or coalesce(p_secret, '') = '' then
    raise exception 'invalid_secret';
  end if;

  insert into public.clinic_integration_secrets (clinic_id, provider, secret)
  values (p_clinic_id, p_provider, p_secret)
  on conflict (clinic_id, provider)
  do update set secret = excluded.secret, updated_at = now();

  perform set_config('app.clinic_workflow', '1', true);
  update public.clinic_emr_settings set satusehat_connected = true where clinic_id = p_clinic_id;
  perform set_config('app.clinic_workflow', '', true);
end $$;

-- Hanya pengguna login yang boleh memanggil RPC
do $$
declare f text;
begin
  foreach f in array array[
    'clinic_onboarding_status(uuid)', 'submit_clinic_for_review(uuid)',
    'review_clinic(uuid,boolean,text)', 'set_clinic_published(uuid,boolean)',
    'save_clinic_integration_secret(uuid,text,text)', 'refresh_clinic_operations(uuid)',
    'clinic_public_preview(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 15. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.profiles        enable row level security;
alter table public.platform_admins enable row level security;
alter table public.clinics         enable row level security;
alter table public.clinic_members  enable row level security;
alter table public.clinic_audit_logs enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists clinics_select on public.clinics;
create policy clinics_select on public.clinics
  for select to authenticated
  using (public.is_clinic_member(id) or public.is_platform_admin());
drop policy if exists clinics_update on public.clinics;
create policy clinics_update on public.clinics
  for update to authenticated
  using (public.is_clinic_member(id)) with check (public.is_clinic_member(id));

drop policy if exists clinic_members_select on public.clinic_members;
create policy clinic_members_select on public.clinic_members
  for select to authenticated
  using (user_id = auth.uid() or public.is_clinic_member(clinic_id));

drop policy if exists audit_select on public.clinic_audit_logs;
create policy audit_select on public.clinic_audit_logs
  for select to authenticated
  using (public.is_clinic_member(clinic_id) or public.is_platform_admin());

-- Tabel dengan clinic_id: anggota klinik boleh CRUD, admin platform boleh baca.
do $$
declare t text;
begin
  foreach t in array array[
    'clinic_services','clinic_facilities','clinic_equipment','clinic_medicines',
    'clinic_operating_hours','clinic_org_structure','clinic_documents',
    'health_workers','health_worker_private','health_worker_educations',
    'health_worker_experiences','health_worker_certificates','health_worker_documents'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_member_all', t);
    execute format(
      'create policy %I on public.%I for all to authenticated using (public.is_clinic_member(clinic_id)) with check (public.is_clinic_member(clinic_id))',
      t || '_member_all', t);
    execute format('drop policy if exists %I on public.%I', t || '_platform_read', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.is_platform_admin())',
      t || '_platform_read', t);
  end loop;
end $$;

-- Baris tunggal per klinik: hanya baca + ubah (tidak boleh insert/hapus dari client)
do $$
declare t text;
begin
  foreach t in array array['clinic_emr_settings', 'clinic_operations_internal'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_member_select', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.is_clinic_member(clinic_id) or public.is_platform_admin())',
      t || '_member_select', t);
    execute format('drop policy if exists %I on public.%I', t || '_member_update', t);
    execute format(
      'create policy %I on public.%I for update to authenticated using (public.is_clinic_member(clinic_id)) with check (public.is_clinic_member(clinic_id))',
      t || '_member_update', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 16. STORAGE: bucket privat untuk dokumen
--     Pola path:  {clinic_id}/{kategori}/{uuid}-{nama_file}
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('clinic-documents', 'clinic-documents', false, 10485760,
        array['application/pdf', 'image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.can_access_clinic_path(p_name text)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select case
    when (storage.foldername(p_name))[1] ~ '^[0-9a-fA-F-]{36}$'
      then public.is_clinic_member(((storage.foldername(p_name))[1])::uuid)
    else false
  end;
$$;

drop policy if exists clinic_docs_select on storage.objects;
create policy clinic_docs_select on storage.objects
  for select to authenticated
  using (bucket_id = 'clinic-documents'
         and (public.can_access_clinic_path(name) or public.is_platform_admin()));

drop policy if exists clinic_docs_insert on storage.objects;
create policy clinic_docs_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'clinic-documents' and public.can_access_clinic_path(name));

drop policy if exists clinic_docs_update on storage.objects;
create policy clinic_docs_update on storage.objects
  for update to authenticated
  using (bucket_id = 'clinic-documents' and public.can_access_clinic_path(name))
  with check (bucket_id = 'clinic-documents' and public.can_access_clinic_path(name));

drop policy if exists clinic_docs_delete on storage.objects;
create policy clinic_docs_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'clinic-documents' and public.can_access_clinic_path(name));
