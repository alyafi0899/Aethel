-- =====================================================================
--  PROMETHEON  -  0006_clinical_operations.sql
--  Jalankan SETELAH 0001..0005. Aman dijalankan ulang.
--
--  Alur operasional klinik yang dipakai bersama oleh TIGA aplikasi
--  (administrasi klinik, pasien, dokter/perawat):
--
--   registrasi (aplikasi pasien / datang langsung) -> antrean -> check-in
--   -> skrining -> triase -> menunggu dokter -> pemeriksaan -> rekam medis
--   -> resep & ringkasan pulang -> tagihan -> pembayaran -> selesai
--
--  Semua perubahan status melalui RPC (aturan peran + log + notifikasi).
--  Data klinis (anamnesis, vital, triase, rekam medis, resep) HANYA bisa
--  dibaca peran klinis (dokter/perawat) atau anggota dengan clinical_access;
--  admin klinik hanya melihat status operasional (prioritas, tahap, tagihan).
--  Nama tabel/kolom baru sengaja unik agar tidak bentrok dengan skema lama
--  (01_schema.sql / clean_schema.sql) bila pernah dijalankan.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. PERAN STAF & AKSES KLINIS
-- ---------------------------------------------------------------------
alter type public.clinic_role add value if not exists 'doctor';
alter type public.clinic_role add value if not exists 'nurse';
alter type public.clinic_role add value if not exists 'receptionist';
alter type public.clinic_role add value if not exists 'cashier';

alter table public.clinic_members
  add column if not exists clinical_access boolean not null default false;

alter table public.clinic_services add column if not exists default_price bigint;
alter table public.clinic_services add column if not exists duration_min  integer;

create or replace function public.clinic_role_of(p_clinic_id uuid)
returns text
language sql stable security definer
set search_path = ''
as $$
  select m.role::text from public.clinic_members m
   where m.clinic_id = p_clinic_id and m.user_id = auth.uid();
$$;

create or replace function public.has_clinic_role(p_clinic_id uuid, p_roles text[])
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(public.clinic_role_of(p_clinic_id) = any (p_roles), false);
$$;

-- Boleh MEMBACA data klinis: dokter/perawat, atau anggota yang diberi clinical_access.
create or replace function public.can_view_clinical(p_clinic_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.clinic_members m
     where m.clinic_id = p_clinic_id and m.user_id = auth.uid()
       and (m.role::text in ('doctor', 'nurse') or m.clinical_access));
$$;

-- Boleh BERTINDAK sebagai dokter (owner/admin hanya bila diberi clinical_access).
create or replace function public.can_act_as_doctor(p_clinic_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.clinic_members m
     where m.clinic_id = p_clinic_id and m.user_id = auth.uid()
       and (m.role::text = 'doctor'
            or (m.role::text in ('owner', 'admin') and m.clinical_access)));
$$;

create or replace function public.current_practitioner(p_clinic_id uuid)
returns uuid
language sql stable security definer
set search_path = ''
as $$
  select w.id from public.health_workers w
   where w.clinic_id = p_clinic_id and w.user_id = auth.uid() and w.is_active
   order by w.created_at limit 1;
$$;

-- Pasien (akun aplikasi pasien)
create or replace function public.is_patient_account()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.account_type = 'patient');
$$;

create or replace function public.today_jakarta()
returns date
language sql stable
set search_path = ''
as $$ select (now() at time zone 'Asia/Jakarta')::date $$;

-- ---------------------------------------------------------------------
-- 2. PENCACAH ATOMIK (nomor RM, nomor antrean, nomor tagihan)
-- ---------------------------------------------------------------------
create table if not exists public.clinic_counters (
  clinic_id    uuid not null references public.clinics (id) on delete cascade,
  counter_key  text not null,
  counter_date date not null default date '1970-01-01',
  value        integer not null default 0,
  primary key (clinic_id, counter_key, counter_date)
);
alter table public.clinic_counters enable row level security;
revoke all on public.clinic_counters from anon, authenticated;

create or replace function public._next_counter(p_clinic uuid, p_key text, p_date date default date '1970-01-01')
returns integer
language plpgsql security definer
set search_path = ''
as $$
declare v integer;
begin
  insert into public.clinic_counters (clinic_id, counter_key, counter_date, value)
  values (p_clinic, p_key, p_date, 1)
  on conflict (clinic_id, counter_key, counter_date)
  do update set value = public.clinic_counters.value + 1
  returning value into v;
  return v;
end $$;
revoke all on function public._next_counter(uuid, text, date) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. PASIEN KLINIK
-- ---------------------------------------------------------------------
create table if not exists public.clinic_patients (
  id                  uuid primary key default gen_random_uuid(),
  clinic_id           uuid not null references public.clinics (id) on delete cascade,
  user_id             uuid references auth.users (id) on delete set null,   -- akun aplikasi pasien (boleh kosong untuk pasien datang langsung)
  medical_record_no   text not null,
  full_name           text not null,
  gender              text check (gender is null or gender in ('male', 'female')),
  birth_date          date,
  phone               text check (phone is null or phone ~ '^\+?[0-9]{8,15}$'),
  registration_status text not null default 'registered' check (registration_status in ('registered', 'pending')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (clinic_id, medical_record_no),
  unique (id, clinic_id)
);
create unique index if not exists clinic_patients_user_unique
  on public.clinic_patients (clinic_id, user_id) where user_id is not null;
create index if not exists clinic_patients_name_idx on public.clinic_patients (clinic_id, lower(full_name));

create table if not exists public.clinic_patient_private (   -- data sensitif dipisah
  clinic_patient_id uuid primary key,
  clinic_id         uuid not null,
  national_id       text check (national_id is null or national_id ~ '^[0-9]{16}$'),
  address           text,
  emergency_contact_name  text,
  emergency_contact_phone text check (emergency_contact_phone is null or emergency_contact_phone ~ '^\+?[0-9]{8,15}$'),
  insurance_type    text check (insurance_type is null or insurance_type in ('none', 'bpjs', 'private')),
  insurance_no      text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  foreign key (clinic_patient_id, clinic_id) references public.clinic_patients (id, clinic_id) on delete cascade
);

-- ---------------------------------------------------------------------
-- 4. KUNJUNGAN (encounters dari 0002 diperluas menjadi poros alur pasien)
-- ---------------------------------------------------------------------
alter table public.encounters alter column patient_user_id drop not null;

alter table public.encounters add column if not exists reference         text;
alter table public.encounters add column if not exists clinic_patient_id uuid;
alter table public.encounters add column if not exists service_type      text;
alter table public.encounters add column if not exists source            text not null default 'reception';
alter table public.encounters add column if not exists visit_kind        text not null default 'in_person';
alter table public.encounters add column if not exists stage             text not null default 'registered';
alter table public.encounters add column if not exists stage_changed_at  timestamptz not null default now();
alter table public.encounters add column if not exists triage_priority   text;       -- ringkasan aman untuk admin
alter table public.encounters add column if not exists has_red_flag      boolean not null default false;
alter table public.encounters add column if not exists cancel_reason     text;
alter table public.encounters add column if not exists registered_by     uuid;

do $$
declare c record;
begin
  for c in select * from (values
    ('encounters_source_chk',   $c$source in ('patient_app','walk_in','reception','referral','telehealth')$c$),
    ('encounters_kind_chk',     $c$visit_kind in ('in_person','online_scheduled','direct_ask')$c$),
    ('encounters_stage_chk',    $c$stage in ('registered','queued','checked_in','screening','triage','waiting_doctor','in_consultation','awaiting_payment','completed','cancelled','no_show')$c$),
    ('encounters_triage_chk',   $c$triage_priority is null or triage_priority in ('urgent','priority','routine')$c$)
  ) as t(cname, expr)
  loop
    if not exists (select 1 from pg_constraint where conname = c.cname) then
      execute format('alter table public.encounters add constraint %I check (%s)', c.cname, c.expr);
    end if;
  end loop;
  if not exists (select 1 from pg_constraint where conname = 'encounters_clinic_patient_fk') then
    alter table public.encounters
      add constraint encounters_clinic_patient_fk
      foreign key (clinic_patient_id, clinic_id) references public.clinic_patients (id, clinic_id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'encounters_id_clinic_unique') then
    alter table public.encounters add constraint encounters_id_clinic_unique unique (id, clinic_id);
  end if;
end $$;

create unique index if not exists encounters_reference_unique on public.encounters (clinic_id, reference) where reference is not null;
create index if not exists encounters_stage_idx on public.encounters (clinic_id, stage, stage_changed_at);
create index if not exists encounters_patient_clinic_idx on public.encounters (clinic_patient_id);

-- ---------------------------------------------------------------------
-- 5. ANTREAN (satu nomor per pasien per hari, berpindah antar "stasiun")
-- ---------------------------------------------------------------------
create table if not exists public.queue_tickets (
  id             uuid primary key default gen_random_uuid(),
  clinic_id      uuid not null references public.clinics (id) on delete cascade,
  encounter_id   uuid not null unique,
  ticket_date    date not null default public.today_jakarta(),
  queue_code     text not null default 'A',
  number         integer not null,
  display_code   text not null,
  station        text not null default 'screening' check (station in ('screening', 'doctor', 'cashier')),
  status         text not null default 'waiting' check (status in ('waiting', 'called', 'serving', 'skipped', 'done', 'cancelled')),
  priority       text not null default 'normal' check (priority in ('normal', 'priority', 'emergency')),
  waiting_since  timestamptz not null default now(),
  first_called_at timestamptz,
  called_at      timestamptz,
  called_by      uuid,
  done_at        timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (clinic_id, ticket_date, queue_code, number),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);
create index if not exists queue_tickets_board_idx on public.queue_tickets (clinic_id, ticket_date, station, status);

-- Linimasa tahap kunjungan (append-only) = sumber "Live activity"
create table if not exists public.visit_events (
  id           bigint generated always as identity primary key,
  clinic_id    uuid not null,
  encounter_id uuid not null,
  from_stage   text,
  to_stage     text not null,
  actor_id     uuid,
  actor_role   text,
  note         text,
  created_at   timestamptz not null default now(),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);
create index if not exists visit_events_enc_idx on public.visit_events (encounter_id, created_at);
create index if not exists visit_events_clinic_idx on public.visit_events (clinic_id, created_at desc);

-- ---------------------------------------------------------------------
-- 6. DATA KLINIS (skrining, triase, vital) - dibatasi peran klinis
-- ---------------------------------------------------------------------
create table if not exists public.visit_intakes (
  id               uuid primary key default gen_random_uuid(),
  clinic_id        uuid not null,
  encounter_id     uuid not null unique,
  data_source      text not null check (data_source in ('patient_self_reported', 'receptionist_assisted', 'clinical_assisted')),
  author_id        uuid default auth.uid(),
  chief_complaint  text,
  symptom_category text,
  duration_text    text,
  onset            text,
  pain_assessment  jsonb not null default '{}'::jsonb,     -- SOCRATES
  medical_history  text,
  medication_allergies text,
  additional_notes text,
  submitted_at     timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

create table if not exists public.visit_triage (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null,
  encounter_id    uuid not null unique,
  priority        text not null check (priority in ('urgent', 'priority', 'routine')),
  state           text not null default 'new' check (state in ('new', 'in_review', 'escalated', 'completed')),
  red_flag        boolean not null default false,
  red_flag_reasons text[] not null default '{}',
  disposition     text,
  notes           text,
  assessed_by     uuid,
  assessed_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

create table if not exists public.visit_vitals (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid not null,
  encounter_id uuid not null,
  bp_systolic  smallint check (bp_systolic  is null or bp_systolic  between 40 and 300),
  bp_diastolic smallint check (bp_diastolic is null or bp_diastolic between 20 and 200),
  heart_rate   smallint check (heart_rate   is null or heart_rate   between 20 and 300),
  spo2         smallint check (spo2         is null or spo2         between 30 and 100),
  temperature_c numeric(4, 1) check (temperature_c is null or temperature_c between 30 and 45),
  resp_rate    smallint check (resp_rate    is null or resp_rate    between 4 and 80),
  weight_kg    numeric(5, 1) check (weight_kg is null or weight_kg between 0.3 and 500),
  height_cm    numeric(5, 1) check (height_cm is null or height_cm between 20 and 260),
  recorded_by  uuid default auth.uid(),
  recorded_at  timestamptz not null default now(),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);
create index if not exists visit_vitals_enc_idx on public.visit_vitals (encounter_id, recorded_at);

-- Aturan kata kunci red-flag (alat bantu peninjauan, BUKAN diagnosis). Isi aturan
-- harus ditinjau tenaga klinis; hanya dapat diubah lewat service role.
create table if not exists public.red_flag_rules (
  keyword text primary key,
  label   text not null
);
insert into public.red_flag_rules (keyword, label) values
  ('nyeri dada',        'Nyeri dada'),
  ('sesak napas',       'Sesak napas'),
  ('sesak nafas',       'Sesak napas'),
  ('sulit bernapas',    'Sulit bernapas'),
  ('sulit bernafas',    'Sulit bernapas'),
  ('pingsan',           'Pingsan'),
  ('tidak sadar',       'Penurunan kesadaran'),
  ('kejang',            'Kejang'),
  ('perdarahan hebat',  'Perdarahan hebat'),
  ('muntah darah',      'Muntah darah'),
  ('lumpuh',            'Kelumpuhan mendadak'),
  ('bicara pelo',       'Gangguan bicara mendadak')
on conflict (keyword) do nothing;

-- ---------------------------------------------------------------------
-- 7. PEMERIKSAAN DOKTER, REKAM MEDIS (berversi), RESEP, RINGKASAN PULANG
-- ---------------------------------------------------------------------
create table if not exists public.visit_consultations (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null,
  encounter_id    uuid not null unique,
  practitioner_id uuid references public.health_workers (id) on delete set null,
  kind            text not null default 'in_person' check (kind in ('in_person', 'online_scheduled', 'direct_ask')),
  state           text not null default 'in_progress' check (state in ('requested', 'accepted', 'in_progress', 'completed', 'cancelled')),
  requested_at    timestamptz not null default now(),
  started_at      timestamptz,
  ended_at        timestamptz,
  facility_id     uuid references public.clinic_facilities (id) on delete set null,
  channel_ref     text,          -- id ruang video/chat (isi percakapan disimpan terpisah, hanya peserta)
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

create table if not exists public.medical_records (
  id                uuid primary key default gen_random_uuid(),
  clinic_id         uuid not null,
  encounter_id      uuid not null unique,
  clinic_patient_id uuid,
  status            text not null default 'draft' check (status in ('draft', 'signed', 'amended')),
  current_version   integer not null default 0,
  signed_version    integer,
  signed_by         uuid,
  signed_at         timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (id, clinic_id),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

create table if not exists public.medical_record_versions (  -- SOAP, tidak bisa diubah / dihapus
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null,
  record_id       uuid not null,
  version         integer not null,
  subjective      text,            -- anamnesis
  objective       text,            -- temuan pemeriksaan
  assessment      text,            -- penilaian / diagnosis (teks)
  plan            text,            -- rencana tata laksana
  diagnoses       jsonb not null default '[]'::jsonb,        -- [{code,label,type}] (mis. ICD-10)
  supporting_tests jsonb not null default '[]'::jsonb,
  doctor_notes    text,
  authored_by     uuid default auth.uid(),
  change_reason   text,
  created_at      timestamptz not null default now(),
  unique (record_id, version),
  foreign key (record_id, clinic_id) references public.medical_records (id, clinic_id) on delete cascade
);

create or replace function public.forbid_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'immutable_record' using errcode = '42501';
end $$;

drop trigger if exists medical_record_versions_immutable on public.medical_record_versions;
create trigger medical_record_versions_immutable
  before update or delete on public.medical_record_versions
  for each row execute function public.forbid_mutation();

drop trigger if exists visit_events_immutable on public.visit_events;
create trigger visit_events_immutable
  before update or delete on public.visit_events
  for each row execute function public.forbid_mutation();

create table if not exists public.prescriptions (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null,
  encounter_id    uuid not null,
  record_id       uuid,
  practitioner_id uuid references public.health_workers (id) on delete set null,
  status          text not null default 'issued' check (status in ('issued', 'dispensed', 'cancelled')),
  pharmacy_notes  text,
  issued_by       uuid default auth.uid(),
  issued_at       timestamptz not null default now(),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (id, clinic_id),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

create table if not exists public.prescription_items (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null,
  prescription_id uuid not null,
  medicine_id     uuid references public.clinic_medicines (id) on delete set null,
  medicine_name   text not null,
  dose            text,
  frequency       text,
  duration_days   integer check (duration_days is null or duration_days > 0),
  quantity        integer check (quantity is null or quantity > 0),
  instructions    text,
  foreign key (prescription_id, clinic_id) references public.prescriptions (id, clinic_id) on delete cascade
);

create table if not exists public.visit_discharges (          -- ringkasan pulang / tindak lanjut
  id                 uuid primary key default gen_random_uuid(),
  clinic_id          uuid not null,
  encounter_id       uuid not null unique,
  summary            text,
  follow_up_at       timestamptz,
  follow_up_note     text,
  emergency_contact_info text,
  issued_by          uuid default auth.uid(),
  issued_at          timestamptz not null default now(),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

-- ---------------------------------------------------------------------
-- 8. TAGIHAN & PEMBAYARAN (layer "Pay Service")
-- ---------------------------------------------------------------------
create table if not exists public.visit_invoices (
  id                uuid primary key default gen_random_uuid(),
  clinic_id         uuid not null,
  encounter_id      uuid not null unique,
  clinic_patient_id uuid,
  reference         text not null,
  status            text not null default 'draft' check (status in ('draft', 'issued', 'processing', 'paid', 'failed', 'void', 'refunded')),
  payer_type        text not null default 'self' check (payer_type in ('self', 'bpjs', 'insurance')),
  subtotal          bigint not null default 0 check (subtotal >= 0),
  discount          bigint not null default 0 check (discount >= 0),
  total             bigint not null default 0 check (total >= 0),
  currency          text not null default 'IDR',
  issued_at         timestamptz,
  paid_at           timestamptz,
  void_reason       text,
  created_by        uuid default auth.uid(),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (clinic_id, reference),
  unique (id, clinic_id),
  foreign key (encounter_id, clinic_id) references public.encounters (id, clinic_id) on delete cascade
);

create table if not exists public.visit_invoice_items (
  id          uuid primary key default gen_random_uuid(),
  clinic_id   uuid not null,
  invoice_id  uuid not null,
  description text not null,
  quantity    integer not null default 1 check (quantity > 0),
  unit_price  bigint not null check (unit_price >= 0),
  item_type   text not null default 'service' check (item_type in ('service', 'medicine', 'procedure', 'manual')),
  foreign key (invoice_id, clinic_id) references public.visit_invoices (id, clinic_id) on delete cascade
);

create table if not exists public.visit_payments (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null,
  invoice_id      uuid not null,
  amount          bigint not null check (amount > 0),
  method          text not null check (method in ('cash', 'bank_transfer', 'debit_card', 'credit_card', 'qris', 'ewallet', 'bpjs', 'insurance')),
  status          text not null default 'succeeded' check (status in ('pending', 'succeeded', 'failed', 'refunded')),
  provider        text not null default 'manual' check (provider in ('manual', 'midtrans', 'xendit', 'other')),
  provider_ref    text,
  idempotency_key text,
  note            text,
  recorded_by     uuid,
  paid_at         timestamptz,
  created_at      timestamptz not null default now(),
  foreign key (invoice_id, clinic_id) references public.visit_invoices (id, clinic_id) on delete cascade
);
create unique index if not exists visit_payments_idem_unique
  on public.visit_payments (clinic_id, idempotency_key) where idempotency_key is not null;

-- ---------------------------------------------------------------------
-- 9. KOTAK MASUK KLINIK (notifikasi operasional) & PANGGILAN DARURAT
-- ---------------------------------------------------------------------
create table if not exists public.clinic_inbox (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid not null references public.clinics (id) on delete cascade,
  kind         text not null,       -- queue_registered|walk_in|patient_checked_in|triage_escalated|consultation_done|payment_pending|payment_received|payment_failed|emergency_call|...
  severity     text not null default 'info' check (severity in ('info', 'warning', 'critical')),
  title        text not null,
  body         text,
  encounter_id uuid,
  ref          jsonb not null default '{}'::jsonb,
  is_read      boolean not null default false,
  read_at      timestamptz,
  read_by      uuid,
  created_at   timestamptz not null default now()
);
create index if not exists clinic_inbox_clinic_idx on public.clinic_inbox (clinic_id, is_read, created_at desc);

create table if not exists public.emergency_alerts (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null references public.clinics (id) on delete cascade,
  patient_user_id uuid references auth.users (id) on delete set null,
  patient_name    text,
  patient_phone   text,
  location        jsonb,
  message         text check (message is null or char_length(message) <= 1000),
  status          text not null default 'open' check (status in ('open', 'acknowledged', 'dispatched', 'resolved', 'false_alarm')),
  handled_by      uuid,
  handled_at      timestamptz,
  resolution_note text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists emergency_alerts_clinic_idx on public.emergency_alerts (clinic_id, status, created_at desc);

-- ---------------------------------------------------------------------
-- 10. TRIGGER updated_at & audit
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'clinic_patients','clinic_patient_private','queue_tickets','visit_intakes','visit_triage',
    'visit_consultations','medical_records','prescriptions','visit_invoices','emergency_alerts'
  ] loop
    execute format('drop trigger if exists %I on public.%I', t || '_set_updated_at', t);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      t || '_set_updated_at', t);
  end loop;

  foreach t in array array[
    'clinic_patients','medical_records','prescriptions','visit_invoices','visit_payments','emergency_alerts','visit_discharges'
  ] loop
    execute format('drop trigger if exists %I on public.%I', t || '_audit', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function public.log_clinic_change()',
      t || '_audit', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 11. FUNGSI INTERNAL (tidak dapat dipanggil dari client)
-- ---------------------------------------------------------------------
create or replace function public._push_inbox(
  p_clinic uuid, p_kind text, p_severity text, p_title text, p_body text default null,
  p_enc uuid default null, p_ref jsonb default '{}'::jsonb)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.clinic_inbox (clinic_id, kind, severity, title, body, encounter_id, ref)
  values (p_clinic, p_kind, p_severity, p_title, p_body, p_enc, coalesce(p_ref, '{}'::jsonb));
end $$;

create or replace function public._log_visit_event(p_enc uuid, p_from text, p_to text, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.visit_events (clinic_id, encounter_id, from_stage, to_stage, actor_id, actor_role, note)
  select e.clinic_id, e.id, p_from, p_to, auth.uid(), public.clinic_role_of(e.clinic_id), p_note
    from public.encounters e where e.id = p_enc;
end $$;

create or replace function public._patient_name(p_enc uuid)
returns text
language sql stable security definer
set search_path = ''
as $$
  select cp.full_name from public.encounters e
    join public.clinic_patients cp on cp.id = e.clinic_patient_id
   where e.id = p_enc;
$$;

-- Statistik operasional (menggantikan isian manual untuk angka yang bisa dihitung)
create or replace function public._refresh_ops(p_clinic_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_today date := public.today_jakarta();
begin
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
    total_registered_patients = (
      select count(*) from public.clinic_patients p where p.clinic_id = p_clinic_id),
    total_queues = (
      select count(*) from public.queue_tickets t
      where t.clinic_id = p_clinic_id and t.ticket_date = v_today),
    current_queue_number = coalesce((
      select t.number from public.queue_tickets t
      where t.clinic_id = p_clinic_id and t.ticket_date = v_today
        and t.status in ('called', 'serving') and t.station in ('doctor', 'screening')
      order by (t.station = 'doctor') desc, t.called_at desc nulls last limit 1), 0),
    average_wait_time = coalesce((
      select round(avg(extract(epoch from (t.first_called_at - t.created_at)) / 60))::int
      from public.queue_tickets t
      where t.clinic_id = p_clinic_id and t.ticket_date = v_today and t.first_called_at is not null), 0),
    total_daily_visitors = (
      select count(*) from public.encounters e
      where e.clinic_id = p_clinic_id and (e.created_at at time zone 'Asia/Jakarta')::date = v_today
        and e.stage not in ('cancelled', 'no_show')),
    daily_appointments_count = (
      select count(*) from public.encounters e
      where e.clinic_id = p_clinic_id
        and (coalesce(e.scheduled_at, e.created_at) at time zone 'Asia/Jakarta')::date = v_today),
    cancelled_appointments_count = (
      select count(*) from public.encounters e
      where e.clinic_id = p_clinic_id and e.stage in ('cancelled', 'no_show')
        and (e.stage_changed_at at time zone 'Asia/Jakarta')::date = v_today),
    total_completed_consultations = (
      select count(*) from public.encounters e
      where e.clinic_id = p_clinic_id and e.stage = 'completed'
        and (e.completed_at at time zone 'Asia/Jakarta')::date = v_today),
    last_update_timestamp = now()
  where o.clinic_id = p_clinic_id;
end $$;

create or replace function public.refresh_clinic_operations(p_clinic_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  perform public._refresh_ops(p_clinic_id);
end $$;

create or replace function public.trg_refresh_ops_from_visits()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  perform public._refresh_ops(case when tg_op = 'DELETE' then old.clinic_id else new.clinic_id end);
  return null;
end $$;

do $$
declare t text;
begin
  foreach t in array array['encounters', 'queue_tickets', 'clinic_patients'] loop
    execute format('drop trigger if exists %I on public.%I', t || '_refresh_ops_visits', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function public.trg_refresh_ops_from_visits()',
      t || '_refresh_ops_visits', t);
  end loop;
end $$;

create or replace function public._new_clinic_patient(
  p_clinic uuid, p_user uuid, p_name text, p_phone text, p_gender text, p_birth date)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare v_id uuid;
begin
  insert into public.clinic_patients (clinic_id, user_id, medical_record_no, full_name, phone, gender, birth_date)
  values (p_clinic, p_user,
          'RM-' || lpad(public._next_counter(p_clinic, 'mrn')::text, 6, '0'),
          p_name, nullif(p_phone, ''), nullif(p_gender, ''), p_birth)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public._issue_ticket(p_enc uuid, p_priority text default 'normal')
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  e   public.encounters;
  v_id uuid;
  v_code text;
  v_n integer;
begin
  select * into e from public.encounters where id = p_enc;
  select t.id into v_id from public.queue_tickets t where t.encounter_id = p_enc;
  if v_id is not null then return v_id; end if;

  v_code := coalesce(nullif(upper(left(regexp_replace(coalesce(e.service_type, ''), '[^A-Za-z]', '', 'g'), 1)), ''), 'A');
  v_n := public._next_counter(e.clinic_id, 'queue:' || v_code, public.today_jakarta());
  insert into public.queue_tickets (clinic_id, encounter_id, ticket_date, queue_code, number, display_code, priority)
  values (e.clinic_id, e.id, public.today_jakarta(), v_code, v_n,
          v_code || '-' || lpad(v_n::text, 3, '0'),
          case when e.has_red_flag then 'emergency' else p_priority end)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public._ticket_info(p_enc uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  t public.queue_tickets;
  v_ahead integer;
  v_now text;
begin
  select * into t from public.queue_tickets where encounter_id = p_enc;
  if not found then return null; end if;

  select count(*) into v_ahead
    from public.queue_tickets x
   where x.clinic_id = t.clinic_id and x.ticket_date = t.ticket_date
     and x.station = t.station and x.status = 'waiting' and x.id <> t.id
     and (case x.priority when 'emergency' then 0 when 'priority' then 1 else 2 end, x.waiting_since, x.number)
       < (case t.priority when 'emergency' then 0 when 'priority' then 1 else 2 end, t.waiting_since, t.number);

  select x.display_code into v_now
    from public.queue_tickets x
   where x.clinic_id = t.clinic_id and x.ticket_date = t.ticket_date
     and x.station = t.station and x.status in ('called', 'serving')
   order by x.called_at desc nulls last limit 1;

  return jsonb_build_object(
    'ticket_id', t.id, 'display_code', t.display_code, 'number', t.number,
    'station', t.station, 'status', t.status, 'priority', t.priority,
    'ahead_count', case when t.status = 'waiting' then v_ahead else 0 end,
    'estimated_wait_min', case when t.status = 'waiting' then v_ahead * 8 else 0 end,
    'now_serving', v_now);
end $$;

create or replace function public._visit_snapshot(p_enc uuid)
returns jsonb
language sql stable security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'encounter_id', e.id, 'reference', e.reference, 'clinic_id', e.clinic_id,
    'stage', e.stage, 'status', e.status, 'service_type', e.service_type,
    'source', e.source, 'visit_kind', e.visit_kind,
    'triage_priority', e.triage_priority, 'has_red_flag', e.has_red_flag,
    'ticket', public._ticket_info(e.id))
  from public.encounters e where e.id = p_enc;
$$;

create or replace function public._set_stage(p_enc uuid, p_to text, p_note text default null)
returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  e   public.encounters;
  v_ok boolean;
begin
  select * into e from public.encounters where id = p_enc for update;
  if not found then raise exception 'visit_not_found'; end if;

  select exists (
    select 1 from (values
      ('registered','queued'), ('registered','checked_in'), ('registered','cancelled'), ('registered','no_show'),
      ('queued','checked_in'), ('queued','screening'), ('queued','cancelled'), ('queued','no_show'),
      ('checked_in','screening'), ('checked_in','triage'), ('checked_in','waiting_doctor'), ('checked_in','cancelled'),
      ('screening','triage'), ('screening','waiting_doctor'), ('screening','cancelled'),
      ('triage','waiting_doctor'), ('triage','cancelled'),
      ('waiting_doctor','in_consultation'), ('waiting_doctor','cancelled'),
      ('in_consultation','awaiting_payment'),
      ('awaiting_payment','completed')
    ) as t(a, b) where t.a = e.stage and t.b = p_to) into v_ok;
  if not v_ok then
    raise exception 'invalid_stage_transition' using detail = e.stage || '->' || p_to;
  end if;

  update public.encounters set
    stage = p_to,
    stage_changed_at = now(),
    status = (case
               when p_to in ('registered', 'queued') then 'scheduled'
               when p_to = 'completed' then 'completed'
               when p_to in ('cancelled', 'no_show') then 'cancelled'
               else 'in_progress' end)::public.encounter_status,
    started_at   = case when p_to in ('screening', 'triage', 'waiting_doctor', 'in_consultation') and started_at is null then now() else started_at end,
    completed_at = case when p_to = 'completed' then now() else completed_at end
  where id = p_enc;

  -- Sinkronkan tiket antrean dengan tahap kunjungan
  if p_to in ('screening', 'triage') then
    update public.queue_tickets set status = 'serving', station = 'screening',
           first_called_at = coalesce(first_called_at, now()), called_at = coalesce(called_at, now())
     where encounter_id = p_enc;
  elsif p_to = 'waiting_doctor' then
    update public.queue_tickets set station = 'doctor', status = 'waiting', waiting_since = now()
     where encounter_id = p_enc;
  elsif p_to = 'in_consultation' then
    update public.queue_tickets set station = 'doctor', status = 'serving',
           first_called_at = coalesce(first_called_at, now()), called_at = now()
     where encounter_id = p_enc;
  elsif p_to = 'awaiting_payment' then
    update public.queue_tickets set station = 'cashier', status = 'waiting', waiting_since = now()
     where encounter_id = p_enc;
  elsif p_to = 'completed' then
    update public.queue_tickets set status = 'done', done_at = now() where encounter_id = p_enc;
  elsif p_to in ('cancelled', 'no_show') then
    update public.queue_tickets set status = 'cancelled', done_at = now() where encounter_id = p_enc;
  end if;

  perform public._log_visit_event(p_enc, e.stage, p_to, p_note);
  return e.stage;
end $$;

-- Pelaku kunjungan: staf dengan peran tertentu, atau pasien pemilik kunjungan
create or replace function public._visit_actor(p_enc uuid, p_staff_roles text[])
returns text
language plpgsql stable security definer
set search_path = ''
as $$
declare e public.encounters;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  select * into e from public.encounters where id = p_enc;
  if not found then raise exception 'visit_not_found'; end if;
  if public.has_clinic_role(e.clinic_id, p_staff_roles) then return 'staff'; end if;
  if e.patient_user_id is not null and e.patient_user_id = auth.uid() then return 'patient'; end if;
  raise exception 'not_authorized' using errcode = '42501';
end $$;

-- Aturan kata kunci red-flag: alat bantu peninjauan klinis, bukan diagnosis.
create or replace function public._apply_red_flags(p_enc uuid, p_text text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_reasons text[];
begin
  if coalesce(trim(p_text), '') = '' then return; end if;
  select coalesce(array_agg(distinct r.label order by r.label), '{}') into v_reasons
    from public.red_flag_rules r where position(r.keyword in lower(p_text)) > 0;
  if cardinality(v_reasons) = 0 then return; end if;

  select * into e from public.encounters where id = p_enc;
  insert into public.visit_triage (clinic_id, encounter_id, priority, state, red_flag, red_flag_reasons)
  values (e.clinic_id, p_enc, 'urgent', 'escalated', true, v_reasons)
  on conflict (encounter_id) do update
    set red_flag = true, priority = 'urgent',
        state = case when public.visit_triage.state = 'completed' then 'completed' else 'escalated' end,
        red_flag_reasons = (select array_agg(distinct x order by x)
                              from unnest(public.visit_triage.red_flag_reasons || excluded.red_flag_reasons) x);

  update public.encounters set has_red_flag = true, triage_priority = 'urgent' where id = p_enc;
  update public.queue_tickets set priority = 'emergency' where encounter_id = p_enc and status in ('waiting', 'called');
  perform public._push_inbox(e.clinic_id, 'triage_escalated', 'critical',
            'Pasien perlu penilaian klinis segera',
            coalesce(public._patient_name(p_enc), 'Pasien') || ' - ditandai untuk tinjauan klinis.',
            p_enc, jsonb_build_object('reference', e.reference));
end $$;

create or replace function public._save_intake(p_enc uuid, p_data jsonb, p_source text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare e public.encounters;
begin
  select * into e from public.encounters where id = p_enc;
  insert into public.visit_intakes (clinic_id, encounter_id, data_source, author_id, chief_complaint,
         symptom_category, duration_text, onset, pain_assessment, medical_history, medication_allergies, additional_notes)
  values (e.clinic_id, p_enc, p_source, auth.uid(),
          nullif(p_data ->> 'chief_complaint', ''), nullif(p_data ->> 'symptom_category', ''),
          nullif(p_data ->> 'duration_text', ''), nullif(p_data ->> 'onset', ''),
          coalesce(p_data -> 'pain_assessment', '{}'::jsonb),
          nullif(p_data ->> 'medical_history', ''), nullif(p_data ->> 'medication_allergies', ''),
          nullif(p_data ->> 'additional_notes', ''))
  on conflict (encounter_id) do update set
    data_source = excluded.data_source, author_id = auth.uid(),
    chief_complaint = coalesce(excluded.chief_complaint, public.visit_intakes.chief_complaint),
    symptom_category = coalesce(excluded.symptom_category, public.visit_intakes.symptom_category),
    duration_text = coalesce(excluded.duration_text, public.visit_intakes.duration_text),
    onset = coalesce(excluded.onset, public.visit_intakes.onset),
    pain_assessment = case when excluded.pain_assessment = '{}'::jsonb then public.visit_intakes.pain_assessment else excluded.pain_assessment end,
    medical_history = coalesce(excluded.medical_history, public.visit_intakes.medical_history),
    medication_allergies = coalesce(excluded.medication_allergies, public.visit_intakes.medication_allergies),
    additional_notes = coalesce(excluded.additional_notes, public.visit_intakes.additional_notes),
    updated_at = now();

  perform public._apply_red_flags(p_enc,
     coalesce(p_data ->> 'chief_complaint', '') || ' ' || coalesce(p_data ->> 'additional_notes', ''));
end $$;

create or replace function public._recalc_invoice(p_invoice uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  update public.visit_invoices i set
    subtotal = coalesce((select sum(it.quantity::bigint * it.unit_price) from public.visit_invoice_items it where it.invoice_id = i.id), 0),
    total = greatest(coalesce((select sum(it.quantity::bigint * it.unit_price) from public.visit_invoice_items it where it.invoice_id = i.id), 0) - i.discount, 0)
  where i.id = p_invoice;
end $$;

create or replace function public._ensure_invoice(p_enc uuid)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_id uuid;
  v_price bigint;
begin
  select i.id into v_id from public.visit_invoices i where i.encounter_id = p_enc;
  if v_id is not null then return v_id; end if;

  select * into e from public.encounters where id = p_enc;
  insert into public.visit_invoices (clinic_id, encounter_id, clinic_patient_id, reference)
  values (e.clinic_id, p_enc, e.clinic_patient_id,
          'INV-' || to_char(public.today_jakarta(), 'YYMMDD') || '-' ||
          lpad(public._next_counter(e.clinic_id, 'invoice', public.today_jakarta())::text, 3, '0'))
  returning id into v_id;

  select s.default_price into v_price from public.clinic_services s
   where s.clinic_id = e.clinic_id and s.service_type = e.service_type;
  if v_price is not null then
    insert into public.visit_invoice_items (clinic_id, invoice_id, description, quantity, unit_price, item_type)
    values (e.clinic_id, v_id, coalesce(e.service_type, 'Layanan'), 1, v_price, 'service');
  end if;
  perform public._recalc_invoice(v_id);
  return v_id;
end $$;

-- Setelah pembayaran tercatat: tandai lunas dan selesaikan kunjungan
create or replace function public._after_payment_check(p_invoice uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  i public.visit_invoices;
  v_paid bigint;
  e public.encounters;
begin
  select * into i from public.visit_invoices where id = p_invoice for update;
  select coalesce(sum(p.amount), 0) into v_paid
    from public.visit_payments p where p.invoice_id = p_invoice and p.status = 'succeeded';

  if i.status in ('issued', 'processing', 'failed') and v_paid >= i.total and i.total > 0 then
    update public.visit_invoices set status = 'paid', paid_at = now() where id = p_invoice;
    select * into e from public.encounters where id = i.encounter_id;
    perform public._push_inbox(i.clinic_id, 'payment_received', 'info', 'Pembayaran diterima',
            'Tagihan ' || i.reference || ' lunas.', i.encounter_id, jsonb_build_object('invoice', i.reference));
    if e.stage = 'awaiting_payment' then
      perform public._set_stage(e.id, 'completed', 'Pembayaran lunas');
    end if;
  end if;
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    '_push_inbox(uuid,text,text,text,text,uuid,jsonb)', '_log_visit_event(uuid,text,text,text)',
    '_patient_name(uuid)', '_refresh_ops(uuid)', 'trg_refresh_ops_from_visits()',
    '_new_clinic_patient(uuid,uuid,text,text,text,date)', '_issue_ticket(uuid,text)', '_ticket_info(uuid)',
    '_visit_snapshot(uuid)', '_set_stage(uuid,text,text)', '_visit_actor(uuid,text[])',
    '_apply_red_flags(uuid,text)', '_save_intake(uuid,jsonb,text)', '_recalc_invoice(uuid)',
    '_ensure_invoice(uuid)', '_after_payment_check(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 12. RPC: REGISTRASI & ANTREAN
--     Dipakai aplikasi klinik (daftar langsung) dan aplikasi pasien.
-- ---------------------------------------------------------------------
create or replace function public.register_visit(
  p_clinic_id   uuid,
  p_service_type text,
  p_patient     jsonb default null,
  p_source      text default null,
  p_visit_kind  text default 'in_person',
  p_scheduled_at timestamptz default null,
  p_complaint   text default null,
  p_take_queue  boolean default true,
  p_priority    text default 'normal')
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_user  uuid := auth.uid();
  v_staff boolean;
  c       public.clinics;
  o       public.clinic_operations_internal;
  cp_id   uuid;
  v_src   text;
  v_enc   uuid;
  v_today date := public.today_jakarta();
  v_name  text;
  v_phone text;
  v_now_queue boolean;
begin
  if v_user is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if p_visit_kind not in ('in_person', 'online_scheduled', 'direct_ask') then raise exception 'invalid_visit_kind'; end if;
  if p_priority not in ('normal', 'priority', 'emergency') then raise exception 'invalid_priority'; end if;
  if coalesce(trim(p_service_type), '') = '' then raise exception 'service_type_required'; end if;

  select * into c from public.clinics where id = p_clinic_id;
  if not found then raise exception 'clinic_not_found'; end if;

  v_now_queue := p_take_queue and (p_scheduled_at is null or (p_scheduled_at at time zone 'Asia/Jakarta')::date = v_today);
  v_staff := public.has_clinic_role(p_clinic_id, array['owner', 'admin', 'receptionist', 'nurse']);

  if not v_staff then
    -- Mode pasien (aplikasi pasien)
    if public.is_clinic_member(p_clinic_id) or not public.is_patient_account() then
      raise exception 'not_authorized' using errcode = '42501';
    end if;
    if c.status <> 'verified' or not c.is_published or c.sio_expiry is null or c.sio_expiry < current_date then
      raise exception 'clinic_not_available';
    end if;
    select * into o from public.clinic_operations_internal where clinic_id = p_clinic_id;
    if v_now_queue and (o.facility_status <> 'open' or o.queue_process_status <> 'active') then
      raise exception 'queue_closed';
    end if;
    v_src := 'patient_app';
    p_priority := 'normal';
    select cp.id into cp_id from public.clinic_patients cp where cp.clinic_id = p_clinic_id and cp.user_id = v_user;
    if cp_id is null then
      select pr.full_name, pr.phone into v_name, v_phone from public.profiles pr where pr.id = v_user;
      cp_id := public._new_clinic_patient(p_clinic_id, v_user, coalesce(nullif(v_name, ''), 'Pasien'), v_phone, null, null);
    end if;
  else
    -- Mode staf (pasien datang langsung / pendaftaran oleh resepsionis)
    v_src := coalesce(p_source, 'walk_in');
    if v_src not in ('walk_in', 'reception', 'referral') then raise exception 'invalid_source'; end if;
    if p_patient is null then raise exception 'patient_required'; end if;
    if p_patient ? 'id' then
      select cp.id into cp_id from public.clinic_patients cp
       where cp.id = (p_patient ->> 'id')::uuid and cp.clinic_id = p_clinic_id;
      if cp_id is null then raise exception 'patient_not_found'; end if;
    else
      if coalesce(trim(p_patient ->> 'full_name'), '') = '' then raise exception 'patient_name_required'; end if;
      if p_patient ->> 'user_id' is not null then
        select cp.id into cp_id from public.clinic_patients cp
         where cp.clinic_id = p_clinic_id and cp.user_id = (p_patient ->> 'user_id')::uuid;
      end if;
      if cp_id is null then
        cp_id := public._new_clinic_patient(p_clinic_id, nullif(p_patient ->> 'user_id', '')::uuid,
                   trim(p_patient ->> 'full_name'), p_patient ->> 'phone', p_patient ->> 'gender',
                   nullif(p_patient ->> 'birth_date', '')::date);
      end if;
    end if;
  end if;

  if exists (select 1 from public.encounters e
              where e.clinic_patient_id = cp_id and e.clinic_id = p_clinic_id
                and e.stage not in ('completed', 'cancelled', 'no_show')
                and coalesce(e.service_type, '') = p_service_type) then
    raise exception 'active_visit_exists';
  end if;

  insert into public.encounters (clinic_id, patient_user_id, clinic_patient_id, service_type, source, visit_kind,
                                 stage, scheduled_at, registered_by, reference)
  select p_clinic_id, cp.user_id, cp.id, p_service_type, v_src, p_visit_kind, 'registered', p_scheduled_at, v_user,
         'VST-' || to_char(v_today, 'YYMMDD') || '-' ||
         lpad(public._next_counter(p_clinic_id, 'visit', v_today)::text, 3, '0')
    from public.clinic_patients cp where cp.id = cp_id
  returning id into v_enc;

  perform public._log_visit_event(v_enc, null, 'registered', v_src);

  if coalesce(trim(p_complaint), '') <> '' then
    perform public._save_intake(v_enc, jsonb_build_object('chief_complaint', p_complaint),
      case when v_staff then 'receptionist_assisted' else 'patient_self_reported' end);
  end if;

  if v_now_queue then
    perform public._issue_ticket(v_enc, p_priority);
    perform public._set_stage(v_enc, 'queued', 'Mengambil antrean');
  end if;

  perform public._push_inbox(
    p_clinic_id,
    case when v_src = 'patient_app' then (case when v_now_queue then 'queue_registered' else 'visit_scheduled' end) else 'walk_in' end,
    'info',
    case when v_src = 'patient_app' then (case when v_now_queue then 'Pasien mendaftar antrean' else 'Pasien membuat janji kunjungan' end)
         else 'Pasien datang langsung' end,
    coalesce(public._patient_name(v_enc), 'Pasien') || ' - ' || p_service_type,
    v_enc, jsonb_build_object('source', v_src));

  return public._visit_snapshot(v_enc);
end $$;

create or replace function public.take_queue(p_encounter_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_actor text;
  o public.clinic_operations_internal;
begin
  v_actor := public._visit_actor(p_encounter_id, array['owner', 'admin', 'receptionist', 'nurse']);
  select * into e from public.encounters where id = p_encounter_id;
  if e.stage <> 'registered' then raise exception 'invalid_stage_transition' using detail = e.stage || '->queued'; end if;
  if v_actor = 'patient' then
    select * into o from public.clinic_operations_internal where clinic_id = e.clinic_id;
    if o.facility_status <> 'open' or o.queue_process_status <> 'active' then raise exception 'queue_closed'; end if;
  end if;
  perform public._issue_ticket(e.id, case when e.has_red_flag then 'emergency' else 'normal' end);
  perform public._set_stage(e.id, 'queued', 'Mengambil antrean');
  perform public._push_inbox(e.clinic_id, 'queue_registered', 'info', 'Pasien mengambil antrean',
          coalesce(public._patient_name(e.id), 'Pasien') || ' - ' || coalesce(e.service_type, ''), e.id);
  return public._visit_snapshot(e.id);
end $$;

create or replace function public.check_in_visit(p_encounter_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare e public.encounters;
begin
  perform public._visit_actor(p_encounter_id, array['owner', 'admin', 'receptionist', 'nurse']);
  select * into e from public.encounters where id = p_encounter_id;
  if e.stage not in ('registered', 'queued') then
    raise exception 'invalid_stage_transition' using detail = e.stage || '->checked_in';
  end if;
  perform public._issue_ticket(e.id, case when e.has_red_flag then 'emergency' else 'normal' end);
  perform public._set_stage(e.id, 'checked_in', 'Check-in');
  perform public._push_inbox(e.clinic_id, 'patient_checked_in', 'info', 'Pasien check-in',
          coalesce(public._patient_name(e.id), 'Pasien') || ' - ' || coalesce(e.service_type, ''), e.id);
  return public._visit_snapshot(e.id);
end $$;

create or replace function public.cancel_visit(p_encounter_id uuid, p_reason text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_actor text;
begin
  v_actor := public._visit_actor(p_encounter_id, array['owner', 'admin', 'receptionist', 'nurse']);
  select * into e from public.encounters where id = p_encounter_id;
  if v_actor = 'patient' and e.stage not in ('registered', 'queued', 'checked_in') then
    raise exception 'cannot_cancel_now';
  end if;
  perform public._set_stage(e.id, 'cancelled', p_reason);
  update public.encounters set cancel_reason = p_reason where id = e.id;
  perform public._push_inbox(e.clinic_id, 'visit_cancelled', 'info', 'Kunjungan dibatalkan',
          coalesce(public._patient_name(e.id), 'Pasien') || coalesce(' - ' || p_reason, ''), e.id);
  return public._visit_snapshot(e.id);
end $$;

create or replace function public.mark_no_show(p_encounter_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
begin
  if public._visit_actor(p_encounter_id, array['owner', 'admin', 'receptionist']) <> 'staff' then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  perform public._set_stage(p_encounter_id, 'no_show', 'Pasien tidak hadir');
  return public._visit_snapshot(p_encounter_id);
end $$;

create or replace function public.queue_call_next(
  p_clinic_id uuid, p_station text default 'screening', p_queue_code text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare t public.queue_tickets;
begin
  if not public.has_clinic_role(p_clinic_id, array['owner', 'admin', 'receptionist', 'nurse', 'doctor', 'cashier']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_station not in ('screening', 'doctor', 'cashier') then raise exception 'invalid_station'; end if;

  select * into t from public.queue_tickets x
   where x.clinic_id = p_clinic_id and x.ticket_date = public.today_jakarta()
     and x.station = p_station and x.status = 'waiting'
     and (p_queue_code is null or x.queue_code = p_queue_code)
   order by case x.priority when 'emergency' then 0 when 'priority' then 1 else 2 end, x.waiting_since, x.number
   limit 1
   for update skip locked;
  if not found then return null; end if;

  update public.queue_tickets set status = 'called', called_at = now(), called_by = auth.uid(),
         first_called_at = coalesce(first_called_at, now())
   where id = t.id;

  if p_station = 'screening' then
    perform public._set_stage(t.encounter_id, 'screening', 'Dipanggil ke skrining');
  end if;
  return public._ticket_info(t.encounter_id);
end $$;

create or replace function public.queue_update_ticket(p_ticket_id uuid, p_status text)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare t public.queue_tickets;
begin
  select * into t from public.queue_tickets where id = p_ticket_id;
  if not found then raise exception 'ticket_not_found'; end if;
  if not public.has_clinic_role(t.clinic_id, array['owner', 'admin', 'receptionist', 'nurse', 'doctor', 'cashier']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_status = 'skipped' and t.status = 'called' then
    update public.queue_tickets set status = 'skipped' where id = t.id;
  elsif p_status = 'waiting' and t.status = 'skipped' then
    update public.queue_tickets set status = 'waiting', waiting_since = now() where id = t.id;
  elsif p_status = 'serving' and t.status = 'called' then
    update public.queue_tickets set status = 'serving' where id = t.id;
  else
    raise exception 'invalid_ticket_transition' using detail = t.status || '->' || p_status;
  end if;
  return public._ticket_info(t.encounter_id);
end $$;

-- ---------------------------------------------------------------------
-- 13. RPC: SKRINING, TRIASE, VITAL
-- ---------------------------------------------------------------------
create or replace function public.submit_intake(p_encounter_id uuid, p_data jsonb)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_actor text;
  v_source text;
begin
  v_actor := public._visit_actor(p_encounter_id, array['owner', 'admin', 'receptionist', 'nurse', 'doctor']);
  select * into e from public.encounters where id = p_encounter_id;
  if e.stage in ('completed', 'cancelled', 'no_show') then raise exception 'visit_closed'; end if;
  v_source := case
    when v_actor = 'patient' then 'patient_self_reported'
    when public.has_clinic_role(e.clinic_id, array['nurse', 'doctor']) then 'clinical_assisted'
    else 'receptionist_assisted' end;
  perform public._save_intake(e.id, coalesce(p_data, '{}'::jsonb), v_source);
  return public._visit_snapshot(e.id);
end $$;

create or replace function public.record_triage(
  p_encounter_id uuid,
  p_priority text,
  p_notes text default null,
  p_vitals jsonb default null,
  p_red_flag boolean default null,
  p_ready_for_doctor boolean default false)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_red boolean;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not (public.has_clinic_role(e.clinic_id, array['nurse', 'doctor']) or public.can_act_as_doctor(e.clinic_id)) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_priority not in ('urgent', 'priority', 'routine') then raise exception 'invalid_priority'; end if;

  v_red := coalesce(p_red_flag, false) or e.has_red_flag;

  insert into public.visit_triage (clinic_id, encounter_id, priority, state, red_flag, notes, assessed_by, assessed_at)
  values (e.clinic_id, e.id, p_priority, case when p_ready_for_doctor then 'completed' else 'in_review' end,
          v_red, p_notes, auth.uid(), now())
  on conflict (encounter_id) do update set
    priority = excluded.priority,
    state = excluded.state,
    red_flag = public.visit_triage.red_flag or excluded.red_flag,
    notes = coalesce(excluded.notes, public.visit_triage.notes),
    assessed_by = auth.uid(), assessed_at = now();

  if p_vitals is not null and p_vitals <> '{}'::jsonb then
    insert into public.visit_vitals (clinic_id, encounter_id, bp_systolic, bp_diastolic, heart_rate, spo2,
                                     temperature_c, resp_rate, weight_kg, height_cm)
    values (e.clinic_id, e.id,
            nullif(p_vitals ->> 'bp_systolic', '')::smallint, nullif(p_vitals ->> 'bp_diastolic', '')::smallint,
            nullif(p_vitals ->> 'heart_rate', '')::smallint, nullif(p_vitals ->> 'spo2', '')::smallint,
            nullif(p_vitals ->> 'temperature_c', '')::numeric, nullif(p_vitals ->> 'resp_rate', '')::smallint,
            nullif(p_vitals ->> 'weight_kg', '')::numeric, nullif(p_vitals ->> 'height_cm', '')::numeric);
  end if;

  update public.encounters set triage_priority = p_priority, has_red_flag = v_red where id = e.id;
  update public.queue_tickets
     set priority = case when v_red then 'emergency' when p_priority = 'urgent' then 'priority' else priority end
   where encounter_id = e.id and status in ('waiting', 'called', 'serving');

  if e.stage in ('checked_in', 'screening') then
    perform public._set_stage(e.id, 'triage', 'Triase');
  end if;
  if p_ready_for_doctor and (select stage from public.encounters where id = e.id) = 'triage' then
    perform public._set_stage(e.id, 'waiting_doctor', 'Siap diperiksa dokter');
  end if;

  if v_red or p_priority = 'urgent' then
    perform public._push_inbox(e.clinic_id, 'triage_escalated', 'critical', 'Pasien prioritas tinggi',
            coalesce(public._patient_name(e.id), 'Pasien') || ' - perlu ditangani segera.', e.id,
            jsonb_build_object('reference', e.reference));
  end if;
  return public._visit_snapshot(e.id);
end $$;

-- ---------------------------------------------------------------------
-- 14. RPC: PEMERIKSAAN DOKTER, REKAM MEDIS, RESEP, RINGKASAN PULANG
-- ---------------------------------------------------------------------
create or replace function public.consultation_start(p_encounter_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_pr uuid;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not public.can_act_as_doctor(e.clinic_id) then raise exception 'not_authorized' using errcode = '42501'; end if;
  v_pr := public.current_practitioner(e.clinic_id);
  if v_pr is null then raise exception 'practitioner_not_linked'; end if;

  perform public._set_stage(e.id, 'in_consultation', 'Pemeriksaan dimulai');
  insert into public.visit_consultations (clinic_id, encounter_id, practitioner_id, kind, state, started_at)
  values (e.clinic_id, e.id, v_pr, e.visit_kind, 'in_progress', now())
  on conflict (encounter_id) do update
    set practitioner_id = excluded.practitioner_id, state = 'in_progress', started_at = now(), ended_at = null;
  update public.encounters set practitioner_id = v_pr where id = e.id;
  return public._visit_snapshot(e.id);
end $$;

create or replace function public.save_medical_record(
  p_encounter_id uuid, p_content jsonb, p_diagnoses jsonb default '[]'::jsonb, p_change_reason text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  r public.medical_records;
  v_ver integer;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not public.can_act_as_doctor(e.clinic_id) then raise exception 'not_authorized' using errcode = '42501'; end if;
  if e.stage not in ('in_consultation', 'awaiting_payment', 'completed') then raise exception 'invalid_stage_for_record'; end if;
  if jsonb_typeof(coalesce(p_diagnoses, '[]'::jsonb)) <> 'array' then raise exception 'diagnoses_must_be_array'; end if;

  select * into r from public.medical_records where encounter_id = e.id for update;
  if not found then
    insert into public.medical_records (clinic_id, encounter_id, clinic_patient_id)
    values (e.clinic_id, e.id, e.clinic_patient_id) returning * into r;
  end if;
  if r.status in ('signed', 'amended') and coalesce(trim(p_change_reason), '') = '' then
    raise exception 'change_reason_required';
  end if;

  v_ver := r.current_version + 1;
  insert into public.medical_record_versions (clinic_id, record_id, version, subjective, objective, assessment, plan,
                                              diagnoses, supporting_tests, doctor_notes, change_reason)
  values (e.clinic_id, r.id, v_ver,
          p_content ->> 'subjective', p_content ->> 'objective', p_content ->> 'assessment', p_content ->> 'plan',
          coalesce(p_diagnoses, '[]'::jsonb), coalesce(p_content -> 'supporting_tests', '[]'::jsonb),
          p_content ->> 'doctor_notes', nullif(trim(p_change_reason), ''));
  update public.medical_records
     set current_version = v_ver, status = case when status in ('signed', 'amended') then 'amended' else 'draft' end
   where id = r.id;
  return jsonb_build_object('record_id', r.id, 'version', v_ver);
end $$;

create or replace function public.sign_medical_record(p_encounter_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  r public.medical_records;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not public.can_act_as_doctor(e.clinic_id) then raise exception 'not_authorized' using errcode = '42501'; end if;
  select * into r from public.medical_records where encounter_id = e.id for update;
  if not found or r.current_version < 1 then raise exception 'record_required'; end if;
  update public.medical_records
     set status = 'signed', signed_version = current_version, signed_by = auth.uid(), signed_at = now()
   where id = r.id;
  return jsonb_build_object('record_id', r.id, 'signed_version', r.current_version);
end $$;

create or replace function public.issue_prescription(
  p_encounter_id uuid, p_items jsonb, p_pharmacy_notes text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  r public.medical_records;
  v_id uuid;
  it jsonb;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not public.can_act_as_doctor(e.clinic_id) then raise exception 'not_authorized' using errcode = '42501'; end if;
  if e.stage not in ('in_consultation', 'awaiting_payment') then raise exception 'invalid_stage_for_prescription'; end if;
  select * into r from public.medical_records where encounter_id = e.id;
  if not found then raise exception 'record_required'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'items_required'; end if;

  insert into public.prescriptions (clinic_id, encounter_id, record_id, practitioner_id, pharmacy_notes)
  values (e.clinic_id, e.id, r.id, coalesce(e.practitioner_id, public.current_practitioner(e.clinic_id)), p_pharmacy_notes)
  returning id into v_id;

  for it in select * from jsonb_array_elements(p_items) loop
    if coalesce(trim(it ->> 'medicine_name'), '') = '' then raise exception 'medicine_name_required'; end if;
    insert into public.prescription_items (clinic_id, prescription_id, medicine_id, medicine_name, dose, frequency,
                                           duration_days, quantity, instructions)
    values (e.clinic_id, v_id, nullif(it ->> 'medicine_id', '')::uuid, trim(it ->> 'medicine_name'),
            it ->> 'dose', it ->> 'frequency', nullif(it ->> 'duration_days', '')::integer,
            nullif(it ->> 'quantity', '')::integer, it ->> 'instructions');
  end loop;
  return jsonb_build_object('prescription_id', v_id);
end $$;

create or replace function public.complete_consultation(p_encounter_id uuid, p_discharge jsonb default '{}'::jsonb)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  r public.medical_records;
  v_inv uuid;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not public.can_act_as_doctor(e.clinic_id) then raise exception 'not_authorized' using errcode = '42501'; end if;
  if e.stage <> 'in_consultation' then raise exception 'invalid_stage_transition' using detail = e.stage || '->awaiting_payment'; end if;
  select * into r from public.medical_records where encounter_id = e.id;
  if not found or r.status <> 'signed' then raise exception 'record_not_signed'; end if;

  insert into public.visit_discharges (clinic_id, encounter_id, summary, follow_up_at, follow_up_note, emergency_contact_info)
  values (e.clinic_id, e.id, p_discharge ->> 'summary', nullif(p_discharge ->> 'follow_up_at', '')::timestamptz,
          p_discharge ->> 'follow_up_note', p_discharge ->> 'emergency_contact_info')
  on conflict (encounter_id) do update set
    summary = excluded.summary, follow_up_at = excluded.follow_up_at, follow_up_note = excluded.follow_up_note,
    emergency_contact_info = excluded.emergency_contact_info, issued_by = auth.uid(), issued_at = now();

  update public.visit_consultations set state = 'completed', ended_at = now() where encounter_id = e.id;
  perform public._set_stage(e.id, 'awaiting_payment', 'Pemeriksaan selesai');
  v_inv := public._ensure_invoice(e.id);
  perform public._push_inbox(e.clinic_id, 'payment_pending', 'info', 'Menunggu pembayaran',
          coalesce(public._patient_name(e.id), 'Pasien') || ' - pemeriksaan selesai, tagihan disiapkan.', e.id);
  return jsonb_build_object('invoice_id', v_inv) || public._visit_snapshot(e.id);
end $$;

-- ---------------------------------------------------------------------
-- 15. RPC: TAGIHAN & PEMBAYARAN
--     Pembayaran online hanya bisa "lunas" lewat apply_payment_event
--     (dipanggil Edge Function webhook dengan service role).
-- ---------------------------------------------------------------------
create or replace function public.update_invoice_items(
  p_encounter_id uuid, p_items jsonb, p_discount bigint default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  e public.encounters;
  v_inv uuid;
  i public.visit_invoices;
  it jsonb;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not public.has_clinic_role(e.clinic_id, array['owner', 'admin', 'cashier']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if jsonb_typeof(p_items) <> 'array' then raise exception 'items_must_be_array'; end if;

  v_inv := public._ensure_invoice(e.id);
  select * into i from public.visit_invoices where id = v_inv for update;
  if i.status <> 'draft' then raise exception 'invoice_not_editable'; end if;

  delete from public.visit_invoice_items where invoice_id = v_inv;
  for it in select * from jsonb_array_elements(p_items) loop
    if coalesce(trim(it ->> 'description'), '') = '' then raise exception 'item_description_required'; end if;
    insert into public.visit_invoice_items (clinic_id, invoice_id, description, quantity, unit_price, item_type)
    values (e.clinic_id, v_inv, trim(it ->> 'description'),
            coalesce(nullif(it ->> 'quantity', '')::integer, 1),
            (it ->> 'unit_price')::bigint,
            coalesce(nullif(it ->> 'item_type', ''), 'manual'));
  end loop;
  if p_discount is not null then
    update public.visit_invoices set discount = p_discount where id = v_inv;
  end if;
  perform public._recalc_invoice(v_inv);
  return (select jsonb_build_object('invoice_id', x.id, 'reference', x.reference, 'status', x.status,
                                    'subtotal', x.subtotal, 'discount', x.discount, 'total', x.total)
            from public.visit_invoices x where x.id = v_inv);
end $$;

create or replace function public.issue_invoice(p_invoice_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  i public.visit_invoices;
  e public.encounters;
begin
  select * into i from public.visit_invoices where id = p_invoice_id for update;
  if not found then raise exception 'invoice_not_found'; end if;
  if not public.has_clinic_role(i.clinic_id, array['owner', 'admin', 'cashier']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if i.status <> 'draft' then raise exception 'invoice_not_editable'; end if;
  perform public._recalc_invoice(i.id);

  update public.visit_invoices set status = 'issued', issued_at = now() where id = i.id;
  select * into i from public.visit_invoices where id = p_invoice_id;
  if i.total = 0 then      -- tagihan nol (gratis/ditanggung): langsung lunas
    update public.visit_invoices set status = 'paid', paid_at = now() where id = i.id;
    select * into e from public.encounters where id = i.encounter_id;
    if e.stage = 'awaiting_payment' then perform public._set_stage(e.id, 'completed', 'Tagihan nol'); end if;
  end if;
  return (select jsonb_build_object('invoice_id', x.id, 'reference', x.reference, 'status', x.status, 'total', x.total)
            from public.visit_invoices x where x.id = i.id);
end $$;

create or replace function public.record_offline_payment(
  p_invoice_id uuid, p_amount bigint, p_method text, p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  i public.visit_invoices;
  v_paid bigint;
begin
  select * into i from public.visit_invoices where id = p_invoice_id for update;
  if not found then raise exception 'invoice_not_found'; end if;
  if not public.has_clinic_role(i.clinic_id, array['owner', 'admin', 'cashier']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if i.status not in ('issued', 'processing', 'failed') then raise exception 'invoice_not_payable'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'invalid_amount'; end if;

  select coalesce(sum(p.amount), 0) into v_paid from public.visit_payments p
   where p.invoice_id = i.id and p.status = 'succeeded';
  if p_amount > i.total - v_paid then raise exception 'overpayment'; end if;

  insert into public.visit_payments (clinic_id, invoice_id, amount, method, status, provider, note, recorded_by, paid_at)
  values (i.clinic_id, i.id, p_amount, p_method, 'succeeded', 'manual', p_note, auth.uid(), now());
  perform public._after_payment_check(i.id);
  return (select jsonb_build_object('invoice_id', x.id, 'status', x.status, 'total', x.total,
            'paid', (select coalesce(sum(p.amount), 0) from public.visit_payments p where p.invoice_id = x.id and p.status = 'succeeded'))
            from public.visit_invoices x where x.id = i.id);
end $$;

-- Webhook penyedia pembayaran (Edge Function dengan service role). Idempoten.
create or replace function public.apply_payment_event(
  p_invoice_id uuid, p_provider text, p_provider_ref text, p_amount bigint,
  p_method text, p_status text, p_idempotency_key text)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  i public.visit_invoices;
  v_existing uuid;
  v_paid bigint;
begin
  if auth.uid() is not null then raise exception 'service_role_only' using errcode = '42501'; end if;
  if coalesce(p_idempotency_key, '') = '' then raise exception 'idempotency_key_required'; end if;
  if p_status not in ('pending', 'succeeded', 'failed') then raise exception 'invalid_status'; end if;
  if p_provider not in ('midtrans', 'xendit', 'other') then raise exception 'invalid_provider'; end if;

  select * into i from public.visit_invoices where id = p_invoice_id for update;
  if not found then raise exception 'invoice_not_found'; end if;

  select p.id into v_existing from public.visit_payments p
   where p.clinic_id = i.clinic_id and p.idempotency_key = p_idempotency_key;
  if v_existing is not null then
    return jsonb_build_object('invoice_id', i.id, 'status', i.status, 'duplicate', true);
  end if;
  if i.status not in ('issued', 'processing', 'failed') then raise exception 'invoice_not_payable'; end if;

  insert into public.visit_payments (clinic_id, invoice_id, amount, method, status, provider, provider_ref,
                                     idempotency_key, paid_at)
  values (i.clinic_id, i.id, p_amount, p_method, p_status, p_provider, p_provider_ref, p_idempotency_key,
          case when p_status = 'succeeded' then now() end);

  if p_status = 'succeeded' then
    perform public._after_payment_check(i.id);
  elsif p_status = 'pending' then
    update public.visit_invoices set status = 'processing' where id = i.id and status in ('issued', 'failed');
  else
    select coalesce(sum(p.amount), 0) into v_paid from public.visit_payments p where p.invoice_id = i.id and p.status = 'succeeded';
    if v_paid < i.total then
      update public.visit_invoices set status = 'failed' where id = i.id and status in ('issued', 'processing');
      perform public._push_inbox(i.clinic_id, 'payment_failed', 'warning', 'Pembayaran gagal',
              'Tagihan ' || i.reference || ' belum terbayar.', i.encounter_id);
    end if;
  end if;
  return (select jsonb_build_object('invoice_id', x.id, 'status', x.status, 'duplicate', false)
            from public.visit_invoices x where x.id = i.id);
end $$;

create or replace function public.void_invoice(p_invoice_id uuid, p_reason text)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  i public.visit_invoices;
  e public.encounters;
begin
  select * into i from public.visit_invoices where id = p_invoice_id for update;
  if not found then raise exception 'invoice_not_found'; end if;
  if not public.has_clinic_role(i.clinic_id, array['owner', 'admin']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'reason_required'; end if;
  if i.status in ('paid', 'void', 'refunded') then raise exception 'invoice_not_voidable'; end if;
  if exists (select 1 from public.visit_payments p where p.invoice_id = i.id and p.status = 'succeeded') then
    raise exception 'invoice_has_payments';
  end if;

  update public.visit_invoices set status = 'void', void_reason = p_reason where id = i.id;
  select * into e from public.encounters where id = i.encounter_id;
  if e.stage = 'awaiting_payment' then perform public._set_stage(e.id, 'completed', 'Tagihan dibatalkan: ' || p_reason); end if;
  return jsonb_build_object('invoice_id', i.id, 'status', 'void');
end $$;

-- ---------------------------------------------------------------------
-- 16. RPC: PANGGILAN DARURAT, KOTAK MASUK, STATUS UNTUK PASIEN
-- ---------------------------------------------------------------------
create or replace function public.trigger_emergency_call(
  p_clinic_id uuid, p_location jsonb default null, p_message text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  c public.clinics;
  v_id uuid;
  v_name text;
  v_phone text;
begin
  if auth.uid() is null or not public.is_patient_account() or public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select * into c from public.clinics where id = p_clinic_id;
  if not found or c.status <> 'verified' or not c.is_published then raise exception 'clinic_not_available'; end if;
  if (select count(*) from public.emergency_alerts a
       where a.clinic_id = p_clinic_id and a.patient_user_id = auth.uid()
         and a.created_at > now() - interval '1 hour') >= 3 then
    raise exception 'too_many_alerts';
  end if;

  select pr.full_name, pr.phone into v_name, v_phone from public.profiles pr where pr.id = auth.uid();
  insert into public.emergency_alerts (clinic_id, patient_user_id, patient_name, patient_phone, location, message)
  values (p_clinic_id, auth.uid(), v_name, v_phone, p_location, p_message)
  returning id into v_id;

  perform public._push_inbox(p_clinic_id, 'emergency_call', 'critical', 'PANGGILAN DARURAT',
          coalesce(v_name, 'Pasien') || ' meminta bantuan darurat.', null,
          jsonb_build_object('alert_id', v_id));
  return jsonb_build_object('alert_id', v_id, 'status', 'open');
end $$;

create or replace function public.emergency_update(p_alert_id uuid, p_status text, p_note text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare a public.emergency_alerts;
begin
  select * into a from public.emergency_alerts where id = p_alert_id for update;
  if not found then raise exception 'alert_not_found'; end if;
  if not public.has_clinic_role(a.clinic_id, array['owner', 'admin', 'receptionist', 'nurse', 'doctor']) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_status not in ('acknowledged', 'dispatched', 'resolved', 'false_alarm') then raise exception 'invalid_status'; end if;
  if a.status in ('resolved', 'false_alarm') then raise exception 'alert_closed'; end if;
  update public.emergency_alerts
     set status = p_status, handled_by = auth.uid(), handled_at = now(),
         resolution_note = coalesce(p_note, resolution_note)
   where id = a.id;
  return jsonb_build_object('alert_id', a.id, 'status', p_status);
end $$;

create or replace function public.inbox_mark_read(p_ids uuid[])
returns integer
language plpgsql security definer
set search_path = ''
as $$
declare n integer;
begin
  update public.clinic_inbox set is_read = true, read_at = now(), read_by = auth.uid()
   where id = any (p_ids) and not is_read and public.is_clinic_member(clinic_id);
  get diagnostics n = row_count;
  return n;
end $$;

-- Status kunjungan untuk aplikasi pasien (dan staf)
create or replace function public.patient_visit_status(p_encounter_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  e public.encounters;
  c public.clinics;
  i public.visit_invoices;
  o public.clinic_operations_internal;
begin
  select * into e from public.encounters where id = p_encounter_id;
  if not found then raise exception 'visit_not_found'; end if;
  if not (e.patient_user_id = auth.uid() or public.is_clinic_member(e.clinic_id)) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select * into c from public.clinics where id = e.clinic_id;
  select * into o from public.clinic_operations_internal where clinic_id = e.clinic_id;
  select * into i from public.visit_invoices where encounter_id = e.id;

  return public._visit_snapshot(e.id) || jsonb_build_object(
    'clinic_name', c.clinic_name,
    'clinic_status', case when o.facility_status = 'open' then 'open' else 'closed' end,
    'invoice', case when i.id is null or i.status = 'draft' then null
                    else jsonb_build_object('reference', i.reference, 'status', i.status, 'total', i.total) end,
    'has_prescription', exists (select 1 from public.prescriptions p where p.encounter_id = e.id and p.status <> 'cancelled'),
    'record_signed', exists (select 1 from public.medical_records r where r.encounter_id = e.id and r.status = 'signed'));
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'register_visit(uuid,text,jsonb,text,text,timestamptz,text,boolean,text)', 'take_queue(uuid)',
    'check_in_visit(uuid)', 'cancel_visit(uuid,text)', 'mark_no_show(uuid)',
    'queue_call_next(uuid,text,text)', 'queue_update_ticket(uuid,text)', 'submit_intake(uuid,jsonb)',
    'record_triage(uuid,text,text,jsonb,boolean,boolean)', 'consultation_start(uuid)',
    'save_medical_record(uuid,jsonb,jsonb,text)', 'sign_medical_record(uuid)',
    'issue_prescription(uuid,jsonb,text)', 'complete_consultation(uuid,jsonb)',
    'update_invoice_items(uuid,jsonb,bigint)', 'issue_invoice(uuid)',
    'record_offline_payment(uuid,bigint,text,text)', 'void_invoice(uuid,text)',
    'trigger_emergency_call(uuid,jsonb,text)', 'emergency_update(uuid,text,text)',
    'inbox_mark_read(uuid[])', 'patient_visit_status(uuid)', 'refresh_clinic_operations(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- Webhook pembayaran: hanya service role
revoke all on function public.apply_payment_event(uuid, text, text, bigint, text, text, text) from public, anon, authenticated;
grant execute on function public.apply_payment_event(uuid, text, text, bigint, text, text, text) to service_role;

-- ---------------------------------------------------------------------
-- 17. PAPAN ALUR OPERASIONAL (RLS tetap berlaku: security_invoker)
-- ---------------------------------------------------------------------
create or replace view public.clinic_visit_board with (security_invoker = true) as
select
  e.id                 as encounter_id,
  e.clinic_id          as clinic_id,
  e.reference          as reference,
  e.stage              as stage,
  e.status::text       as status,
  e.visit_kind         as visit_kind,
  e.source             as source,
  e.service_type       as service_type,
  e.triage_priority    as triage_priority,
  e.has_red_flag       as has_red_flag,
  e.scheduled_at       as scheduled_at,
  e.created_at         as registered_at,
  e.stage_changed_at   as stage_changed_at,
  round(extract(epoch from (now() - e.stage_changed_at)) / 60)::int as minutes_in_stage,
  cp.id                as clinic_patient_id,
  cp.full_name         as patient_name,
  cp.medical_record_no as medical_record_no,
  t.display_code       as ticket_code,
  t.station            as ticket_station,
  t.status             as ticket_status,
  t.priority           as ticket_priority,
  w.full_name          as practitioner_name,
  inv.status           as invoice_status,
  inv.total            as invoice_total
from public.encounters e
left join public.clinic_patients cp on cp.id = e.clinic_patient_id
left join public.queue_tickets t on t.encounter_id = e.id
left join public.health_workers w on w.id = e.practitioner_id
left join public.visit_invoices inv on inv.encounter_id = e.id;

revoke all on public.clinic_visit_board from public, anon;
grant select on public.clinic_visit_board to authenticated;

-- ---------------------------------------------------------------------
-- 18. ROW LEVEL SECURITY
--     Penulisan data alur pasien HANYA lewat RPC (security definer).
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'clinic_patients','clinic_patient_private','queue_tickets','visit_events','visit_intakes','visit_triage',
    'visit_vitals','red_flag_rules','visit_consultations','medical_records','medical_record_versions',
    'prescriptions','prescription_items','visit_discharges','visit_invoices','visit_invoice_items',
    'visit_payments','clinic_inbox','emergency_alerts'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Kunjungan: anggota hanya membaca (perubahan lewat RPC)
drop policy if exists encounters_member_all on public.encounters;
drop policy if exists encounters_member_select on public.encounters;
create policy encounters_member_select on public.encounters
  for select to authenticated using (public.is_clinic_member(clinic_id));

-- Pasien klinik
drop policy if exists clinic_patients_member_select on public.clinic_patients;
create policy clinic_patients_member_select on public.clinic_patients
  for select to authenticated using (public.is_clinic_member(clinic_id));
drop policy if exists clinic_patients_member_update on public.clinic_patients;
create policy clinic_patients_member_update on public.clinic_patients
  for update to authenticated
  using (public.has_clinic_role(clinic_id, array['owner', 'admin', 'receptionist', 'nurse']))
  with check (public.has_clinic_role(clinic_id, array['owner', 'admin', 'receptionist', 'nurse']));
drop policy if exists clinic_patients_self_select on public.clinic_patients;
create policy clinic_patients_self_select on public.clinic_patients
  for select to authenticated using (user_id = auth.uid());

drop policy if exists clinic_patient_private_staff_all on public.clinic_patient_private;
create policy clinic_patient_private_staff_all on public.clinic_patient_private
  for all to authenticated
  using (public.has_clinic_role(clinic_id, array['owner', 'admin', 'receptionist', 'nurse', 'doctor']))
  with check (public.has_clinic_role(clinic_id, array['owner', 'admin', 'receptionist', 'nurse', 'doctor']));

-- Antrean, linimasa, konsultasi (metadata operasional): semua anggota; pasien miliknya
drop policy if exists queue_tickets_member_select on public.queue_tickets;
create policy queue_tickets_member_select on public.queue_tickets
  for select to authenticated using (public.is_clinic_member(clinic_id));
drop policy if exists queue_tickets_patient_select on public.queue_tickets;
create policy queue_tickets_patient_select on public.queue_tickets
  for select to authenticated
  using (exists (select 1 from public.encounters e where e.id = encounter_id and e.patient_user_id = auth.uid()));

drop policy if exists visit_events_member_select on public.visit_events;
create policy visit_events_member_select on public.visit_events
  for select to authenticated using (public.is_clinic_member(clinic_id));
drop policy if exists visit_events_patient_select on public.visit_events;
create policy visit_events_patient_select on public.visit_events
  for select to authenticated
  using (exists (select 1 from public.encounters e where e.id = encounter_id and e.patient_user_id = auth.uid()));

drop policy if exists visit_consultations_member_select on public.visit_consultations;
create policy visit_consultations_member_select on public.visit_consultations
  for select to authenticated using (public.is_clinic_member(clinic_id));
drop policy if exists visit_consultations_patient_select on public.visit_consultations;
create policy visit_consultations_patient_select on public.visit_consultations
  for select to authenticated
  using (exists (select 1 from public.encounters e where e.id = encounter_id and e.patient_user_id = auth.uid()));

-- Data klinis: hanya peran klinis / clinical_access; pasien membaca miliknya
do $$
declare t text;
begin
  foreach t in array array['visit_intakes', 'visit_vitals', 'visit_discharges', 'prescriptions'] loop
    execute format('drop policy if exists %I on public.%I', t || '_clinical_select', t);
    execute format('create policy %I on public.%I for select to authenticated using (public.can_view_clinical(clinic_id))',
                   t || '_clinical_select', t);
    execute format('drop policy if exists %I on public.%I', t || '_patient_select', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (exists (select 1 from public.encounters e where e.id = encounter_id and e.patient_user_id = auth.uid()))',
      t || '_patient_select', t);
  end loop;
end $$;

drop policy if exists visit_triage_clinical_select on public.visit_triage;
create policy visit_triage_clinical_select on public.visit_triage
  for select to authenticated using (public.can_view_clinical(clinic_id));

drop policy if exists prescription_items_clinical_select on public.prescription_items;
create policy prescription_items_clinical_select on public.prescription_items
  for select to authenticated using (public.can_view_clinical(clinic_id));
drop policy if exists prescription_items_patient_select on public.prescription_items;
create policy prescription_items_patient_select on public.prescription_items
  for select to authenticated
  using (exists (select 1 from public.prescriptions p join public.encounters e on e.id = p.encounter_id
                  where p.id = prescription_id and e.patient_user_id = auth.uid()));

drop policy if exists medical_records_clinical_select on public.medical_records;
create policy medical_records_clinical_select on public.medical_records
  for select to authenticated using (public.can_view_clinical(clinic_id));
drop policy if exists medical_records_patient_select on public.medical_records;
create policy medical_records_patient_select on public.medical_records
  for select to authenticated
  using (status in ('signed', 'amended')
         and exists (select 1 from public.encounters e where e.id = encounter_id and e.patient_user_id = auth.uid()));

drop policy if exists medical_record_versions_clinical_select on public.medical_record_versions;
create policy medical_record_versions_clinical_select on public.medical_record_versions
  for select to authenticated using (public.can_view_clinical(clinic_id));
drop policy if exists medical_record_versions_patient_select on public.medical_record_versions;
create policy medical_record_versions_patient_select on public.medical_record_versions
  for select to authenticated
  using (exists (select 1 from public.medical_records r join public.encounters e on e.id = r.encounter_id
                  where r.id = record_id and e.patient_user_id = auth.uid()
                    and r.signed_version is not null and version <= r.signed_version));

-- Tagihan & pembayaran: owner/admin/kasir; pasien membaca tagihan miliknya (bukan draft)
drop policy if exists visit_invoices_billing_select on public.visit_invoices;
create policy visit_invoices_billing_select on public.visit_invoices
  for select to authenticated using (public.has_clinic_role(clinic_id, array['owner', 'admin', 'cashier']));
drop policy if exists visit_invoices_patient_select on public.visit_invoices;
create policy visit_invoices_patient_select on public.visit_invoices
  for select to authenticated
  using (status <> 'draft'
         and exists (select 1 from public.encounters e where e.id = encounter_id and e.patient_user_id = auth.uid()));

drop policy if exists visit_invoice_items_billing_select on public.visit_invoice_items;
create policy visit_invoice_items_billing_select on public.visit_invoice_items
  for select to authenticated using (public.has_clinic_role(clinic_id, array['owner', 'admin', 'cashier']));
drop policy if exists visit_invoice_items_patient_select on public.visit_invoice_items;
create policy visit_invoice_items_patient_select on public.visit_invoice_items
  for select to authenticated
  using (exists (select 1 from public.visit_invoices i join public.encounters e on e.id = i.encounter_id
                  where i.id = invoice_id and i.status <> 'draft' and e.patient_user_id = auth.uid()));

drop policy if exists visit_payments_billing_select on public.visit_payments;
create policy visit_payments_billing_select on public.visit_payments
  for select to authenticated using (public.has_clinic_role(clinic_id, array['owner', 'admin', 'cashier']));
drop policy if exists visit_payments_patient_select on public.visit_payments;
create policy visit_payments_patient_select on public.visit_payments
  for select to authenticated
  using (exists (select 1 from public.visit_invoices i join public.encounters e on e.id = i.encounter_id
                  where i.id = invoice_id and e.patient_user_id = auth.uid()));

-- Kotak masuk & darurat
drop policy if exists clinic_inbox_member_select on public.clinic_inbox;
create policy clinic_inbox_member_select on public.clinic_inbox
  for select to authenticated using (public.is_clinic_member(clinic_id));

drop policy if exists emergency_alerts_member_select on public.emergency_alerts;
create policy emergency_alerts_member_select on public.emergency_alerts
  for select to authenticated using (public.is_clinic_member(clinic_id));
drop policy if exists emergency_alerts_patient_select on public.emergency_alerts;
create policy emergency_alerts_patient_select on public.emergency_alerts
  for select to authenticated using (patient_user_id = auth.uid());

drop policy if exists red_flag_rules_select on public.red_flag_rules;
create policy red_flag_rules_select on public.red_flag_rules
  for select to authenticated using (true);

-- Tidak ada akses tulis langsung dari client ke tabel alur: cabut hak tulis tabel.
do $$
declare t text;
begin
  foreach t in array array[
    'queue_tickets','visit_events','visit_intakes','visit_triage','visit_vitals','visit_consultations',
    'medical_records','medical_record_versions','prescriptions','prescription_items','visit_discharges',
    'visit_invoices','visit_invoice_items','visit_payments','clinic_inbox','emergency_alerts','red_flag_rules','encounters'
  ] loop
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
  end loop;
  revoke insert, delete, truncate on public.clinic_patients from anon, authenticated;

  -- Pengguna anonim tidak butuh akses apa pun ke tabel alur (pertahanan berlapis di atas RLS)
  foreach t in array array[
    'encounters','clinic_patients','clinic_patient_private','queue_tickets','visit_events','visit_intakes',
    'visit_triage','visit_vitals','red_flag_rules','visit_consultations','medical_records',
    'medical_record_versions','prescriptions','prescription_items','visit_discharges','visit_invoices',
    'visit_invoice_items','visit_payments','clinic_inbox','emergency_alerts'
  ] loop
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 19. REALTIME (jika tersedia) agar papan alur & notifikasi langsung ter-update
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['clinic_inbox', 'encounters', 'queue_tickets', 'emergency_alerts'] loop
      begin
        execute format('alter publication supabase_realtime add table public.%I', t);
      exception when duplicate_object then null;
      end;
    end loop;
  end if;
end $$;
