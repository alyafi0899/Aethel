-- =====================================================================
--  PROMETHEON  -  0002_trust_and_feedback.sql
--  Jalankan SETELAH 0001_clinic_core.sql. Aman dijalankan ulang.
--  Isi: media publik (logo/sampul/galeri), gerbang kelengkapan yang
--  diperluas, pemantauan masa berlaku (SIO/STR/SIP), kunjungan minimal
--  (encounters), ulasan & rating, balasan, laporan, masukan privat,
--  persetujuan hukum, dan RPC moderasi admin platform.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ENUM BARU
-- ---------------------------------------------------------------------
do $$
declare
  spec  text;
  tname text;
  vals  text;
begin
  foreach spec in array array[
    'media_kind|logo,cover,gallery',
    'encounter_status|scheduled,in_progress,completed,cancelled',
    'review_status|published,removed',
    'report_reason|abusive,false_information,privacy_violation,spam,other',
    'report_status|open,upheld,dismissed',
    'feedback_category|service,facility,staff,waiting_time,billing,other',
    'feedback_status|new,read,resolved',
    'alert_severity|info,warning,critical'
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
-- 2. PERBAIKAN: ganti berkas dokumen => wajib ditinjau ulang
-- ---------------------------------------------------------------------
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
  elsif new.file_path is distinct from old.file_path then
    new.review_status := 'pending';       -- file diganti -> tinjau ulang
    new.review_note   := null;
  else
    new.review_status := old.review_status;
    new.review_note   := old.review_note;
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------------
-- 3. MEDIA PUBLIK KLINIK (logo, sampul, galeri)
-- ---------------------------------------------------------------------
create table if not exists public.clinic_media (
  id            uuid primary key default gen_random_uuid(),
  clinic_id     uuid not null references public.clinics (id) on delete cascade,
  kind          public.media_kind not null,
  file_path     text not null,
  file_name     text,
  mime_type     text,
  size_bytes    bigint,
  alt_text      text,
  sort_order    integer not null default 0,
  review_status public.document_review_status not null default 'pending',
  review_note   text,
  uploaded_by   uuid default auth.uid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create unique index if not exists clinic_media_single_kind
  on public.clinic_media (clinic_id, kind) where kind in ('logo', 'cover');
create index if not exists clinic_media_clinic_idx on public.clinic_media (clinic_id, kind);

-- ---------------------------------------------------------------------
-- 4. KEPATUHAN: peringatan masa berlaku
-- ---------------------------------------------------------------------
create table if not exists public.clinic_alerts (
  id          uuid primary key default gen_random_uuid(),
  clinic_id   uuid not null references public.clinics (id) on delete cascade,
  alert_type  text not null,       -- sio_expiring|sio_expired|str_expiring|str_expired|sip_expiring|sip_expired
  ref_id      uuid not null,       -- clinics.id atau health_workers.id
  severity    public.alert_severity not null default 'warning',
  message     text not null,
  due_date    date,
  is_resolved boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (clinic_id, alert_type, ref_id)
);
create index if not exists clinic_alerts_open_idx on public.clinic_alerts (clinic_id) where not is_resolved;

create or replace view public.clinic_compliance_candidates as
select clinic_id, alert_type, ref_id, due_date, severity, message
from (
  select c.id as clinic_id, 'sio'::text as kind, c.id as ref_id, c.sio_expiry as due_date,
         'SIO klinik'::text as label, 60 as lead_days
    from public.clinics c
   where c.status in ('verified', 'submitted', 'under_review') and c.sio_expiry is not null
  union all
  select w.clinic_id, 'str', w.id, w.str_expiry, 'STR ' || w.full_name, 90
    from public.health_workers w where w.is_active and w.str_expiry is not null
  union all
  select w.clinic_id, 'sip', w.id, w.sip_expiry, 'SIP ' || w.full_name, 90
    from public.health_workers w where w.is_active and w.sip_expiry is not null
) x
cross join lateral (
  select kind || case when due_date < current_date then '_expired' else '_expiring' end as alert_type,
         case when due_date < current_date then 'critical' else 'warning' end::public.alert_severity as severity,
         label || case when due_date < current_date
                       then ' sudah kedaluwarsa pada ' || to_char(due_date, 'DD-MM-YYYY')
                       else ' akan kedaluwarsa pada ' || to_char(due_date, 'DD-MM-YYYY') end as message
) y
where due_date <= current_date + lead_days;
revoke all on public.clinic_compliance_candidates from public, anon, authenticated;

create or replace function public.refresh_compliance_alerts(p_clinic_id uuid default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    if p_clinic_id is null then
      if not public.is_platform_admin() then
        raise exception 'not_authorized' using errcode = '42501';
      end if;
    elsif not public.is_clinic_member(p_clinic_id) then
      raise exception 'not_authorized' using errcode = '42501';
    end if;
  end if;

  insert into public.clinic_alerts (clinic_id, alert_type, ref_id, severity, message, due_date)
  select k.clinic_id, k.alert_type, k.ref_id, k.severity, k.message, k.due_date
    from public.clinic_compliance_candidates k
   where p_clinic_id is null or k.clinic_id = p_clinic_id
  on conflict (clinic_id, alert_type, ref_id) do update
    set severity = excluded.severity, message = excluded.message,
        due_date = excluded.due_date, is_resolved = false, updated_at = now();

  update public.clinic_alerts a
     set is_resolved = true, updated_at = now()
   where not a.is_resolved
     and (p_clinic_id is null or a.clinic_id = p_clinic_id)
     and not exists (
       select 1 from public.clinic_compliance_candidates k
        where k.clinic_id = a.clinic_id and k.alert_type = a.alert_type and k.ref_id = a.ref_id);
end $$;

create or replace function public.clinic_compliance_status(p_clinic_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  c public.clinics;
  v_alerts jsonb;
begin
  if not (public.is_clinic_member(p_clinic_id) or public.is_platform_admin()) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select * into c from public.clinics where id = p_clinic_id;
  if not found then raise exception 'clinic_not_found'; end if;

  perform public.refresh_compliance_alerts(p_clinic_id);

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', a.id, 'type', a.alert_type, 'severity', a.severity,
           'message', a.message, 'due_date', a.due_date, 'ref_id', a.ref_id)
         order by a.severity desc, a.due_date), '[]'::jsonb)
    into v_alerts
    from public.clinic_alerts a
   where a.clinic_id = p_clinic_id and not a.is_resolved;

  return jsonb_build_object(
    'sio_expiry', c.sio_expiry,
    'sio_days_left', case when c.sio_expiry is null then null else c.sio_expiry - current_date end,
    'sio_valid', c.sio_expiry is not null and c.sio_expiry >= current_date,
    'publicly_visible', c.status = 'verified' and c.is_published
                        and c.sio_expiry is not null and c.sio_expiry >= current_date,
    'alerts', v_alerts
  );
end $$;

-- ---------------------------------------------------------------------
-- 5. KUNJUNGAN MINIMAL (akan diperluas oleh ERD klinis)
-- ---------------------------------------------------------------------
create table if not exists public.encounters (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null references public.clinics (id) on delete cascade,
  patient_user_id uuid not null references auth.users (id),
  practitioner_id uuid references public.health_workers (id) on delete set null,
  status          public.encounter_status not null default 'scheduled',
  scheduled_at    timestamptz,
  started_at      timestamptz,
  completed_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (status <> 'completed' or completed_at is not null)
);
create index if not exists encounters_clinic_idx  on public.encounters (clinic_id, status);
create index if not exists encounters_patient_idx on public.encounters (patient_user_id);

-- ---------------------------------------------------------------------
-- 6. ULASAN & RATING
-- ---------------------------------------------------------------------
create table if not exists public.clinic_reviews (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null references public.clinics (id) on delete cascade,
  encounter_id    uuid not null unique references public.encounters (id) on delete cascade,
  patient_user_id uuid not null default auth.uid() references auth.users (id),
  rating          smallint not null check (rating between 1 and 5),
  comment         text check (comment is null or char_length(comment) <= 2000),
  status          public.review_status not null default 'published',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (id, clinic_id)
);
create index if not exists clinic_reviews_clinic_idx on public.clinic_reviews (clinic_id, status, created_at desc);

create table if not exists public.clinic_review_replies (   -- satu balasan per ulasan
  review_id  uuid primary key,
  clinic_id  uuid not null,
  body       text not null check (char_length(body) between 1 and 1000),
  replied_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (review_id, clinic_id) references public.clinic_reviews (id, clinic_id) on delete cascade
);

create table if not exists public.review_reports (
  id          uuid primary key default gen_random_uuid(),
  review_id   uuid not null,
  clinic_id   uuid not null,
  reported_by uuid default auth.uid(),
  reason      public.report_reason not null,
  details     text check (details is null or char_length(details) <= 1000),
  status      public.report_status not null default 'open',
  resolved_by uuid,
  resolved_at timestamptz,
  resolution_note text,
  created_at  timestamptz not null default now(),
  foreign key (review_id, clinic_id) references public.clinic_reviews (id, clinic_id) on delete cascade
);
create unique index if not exists review_reports_one_open
  on public.review_reports (review_id) where status = 'open';

create table if not exists public.clinic_feedback_private (  -- masukan privat (tidak tampil publik)
  id            uuid primary key default gen_random_uuid(),
  clinic_id     uuid not null references public.clinics (id) on delete cascade,
  encounter_id  uuid not null unique references public.encounters (id) on delete cascade,
  patient_user_id uuid not null default auth.uid() references auth.users (id),
  category      public.feedback_category not null default 'other',
  message       text not null check (char_length(message) between 1 and 3000),
  status        public.feedback_status not null default 'new',
  internal_note text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists clinic_feedback_clinic_idx on public.clinic_feedback_private (clinic_id, status);

-- ---------------------------------------------------------------------
-- 7. PERSETUJUAN HUKUM (Syarat & Kebijakan Privasi)
-- ---------------------------------------------------------------------
create table if not exists public.legal_consents (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  document_type    text not null check (document_type in ('terms', 'privacy')),
  document_version text not null,
  accepted_at      timestamptz not null default now(),
  unique (user_id, document_type, document_version)
);

-- ---------------------------------------------------------------------
-- 8. TRIGGER
-- ---------------------------------------------------------------------
create or replace function public.protect_media_columns()
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
  elsif new.file_path is distinct from old.file_path then
    new.review_status := 'pending';
    new.review_note   := null;
  else
    new.review_status := old.review_status;
    new.review_note   := old.review_note;
  end if;
  return new;
end $$;

drop trigger if exists clinic_media_protect_review on public.clinic_media;
create trigger clinic_media_protect_review
  before insert or update on public.clinic_media
  for each row execute function public.protect_media_columns();

create or replace function public.protect_feedback_row()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- klinik hanya boleh mengubah status & catatan internal
  new.message         := old.message;
  new.category        := old.category;
  new.patient_user_id := old.patient_user_id;
  new.encounter_id    := old.encounter_id;
  new.clinic_id       := old.clinic_id;
  return new;
end $$;

drop trigger if exists clinic_feedback_protect on public.clinic_feedback_private;
create trigger clinic_feedback_protect
  before update on public.clinic_feedback_private
  for each row execute function public.protect_feedback_row();

do $$
declare t text;
begin
  foreach t in array array[
    'clinic_media','clinic_alerts','encounters','clinic_reviews',
    'clinic_review_replies','clinic_feedback_private'
  ] loop
    execute format('drop trigger if exists %I on public.%I', t || '_set_updated_at', t);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      t || '_set_updated_at', t);
  end loop;

  foreach t in array array['clinic_media','clinic_review_replies','review_reports','clinic_reviews'] loop
    execute format('drop trigger if exists %I on public.%I', t || '_audit', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function public.log_clinic_change()',
      t || '_audit', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 9. VIEW PUBLIK DIPERBARUI: klinik dengan SIO kedaluwarsa & dokter dengan
--    STR/SIP kedaluwarsa otomatis tidak tampil ke publik.
-- ---------------------------------------------------------------------
create or replace view public.clinic_operations_public_all as
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
      and (w.str_expiry is null or w.str_expiry >= current_date)
      and (w.sip_expiry is null or w.sip_expiry >= current_date)
  ), '[]'::jsonb)                              as available_doctors,
  null::timestamptz                            as next_available_slot,
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

create or replace view public.clinic_operations_public as
select a.*
from public.clinic_operations_public_all a
join public.clinics c on c.id = a.clinic_id
where c.status = 'verified' and c.is_published
  and c.sio_expiry is not null and c.sio_expiry >= current_date;

-- Profil publik klinik (untuk pasien): identitas, media yang SUDAH disetujui, rating
create or replace view public.clinic_public_profile as
select
  c.id                  as clinic_id,
  c.clinic_name         as clinic_name,
  c.address_full        as address_full,
  c.latitude            as latitude,
  c.longitude           as longitude,
  c.phone               as contact_number,
  coalesce((select array_agg(s.service_type order by s.service_type)
              from public.clinic_services s
             where s.clinic_id = c.id and s.is_active), '{}') as service_types,
  (select m.file_path from public.clinic_media m
    where m.clinic_id = c.id and m.kind = 'logo' and m.review_status = 'approved' limit 1) as logo_path,
  (select m.file_path from public.clinic_media m
    where m.clinic_id = c.id and m.kind = 'cover' and m.review_status = 'approved' limit 1) as cover_path,
  coalesce((select jsonb_agg(m.file_path order by m.sort_order, m.created_at)
              from public.clinic_media m
             where m.clinic_id = c.id and m.kind = 'gallery' and m.review_status = 'approved'),
           '[]'::jsonb) as gallery_paths,
  (select round(avg(r.rating)::numeric, 2) from public.clinic_reviews r
    where r.clinic_id = c.id and r.status = 'published') as rating_average,
  (select count(*) from public.clinic_reviews r
    where r.clinic_id = c.id and r.status = 'published')::int as rating_count
from public.clinics c
where c.status = 'verified' and c.is_published
  and c.sio_expiry is not null and c.sio_expiry >= current_date;

grant select on public.clinic_public_profile to anon, authenticated;

-- Ulasan publik (anonim, "pasien terverifikasi") + balasan klinik
create or replace view public.clinic_reviews_public as
select
  r.id          as review_id,
  r.clinic_id   as clinic_id,
  r.rating      as rating,
  r.comment     as comment,
  r.created_at  as created_at,
  true          as verified_patient,
  rp.body       as reply_body,
  rp.created_at as reply_created_at
from public.clinic_reviews r
join public.clinics c on c.id = r.clinic_id
left join public.clinic_review_replies rp on rp.review_id = r.id
where r.status = 'published'
  and c.status = 'verified' and c.is_published
  and c.sio_expiry is not null and c.sio_expiry >= current_date;

grant select on public.clinic_reviews_public to anon, authenticated;

-- Daftar ulasan untuk pengelola klinik (RLS tetap berlaku: security_invoker)
create or replace view public.clinic_reviews_manage with (security_invoker = true) as
select
  r.id          as review_id,
  r.clinic_id   as clinic_id,
  r.rating      as rating,
  r.comment     as comment,
  r.created_at  as created_at,
  (rp.review_id is not null) as replied,
  rp.body       as reply_body,
  rp.created_at as reply_created_at,
  exists (select 1 from public.review_reports x
           where x.review_id = r.id and x.status = 'open')      as has_open_report,
  exists (select 1 from public.review_reports x
           where x.review_id = r.id and x.status = 'dismissed') as report_dismissed
from public.clinic_reviews r
left join public.clinic_review_replies rp on rp.review_id = r.id
where r.status = 'published';

revoke all on public.clinic_reviews_manage from public, anon;
grant select on public.clinic_reviews_manage to authenticated;

-- Statistik ulasan untuk pengelola klinik
create or replace function public.clinic_review_stats(p_clinic_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare v jsonb;
begin
  if not (public.is_clinic_member(p_clinic_id) or public.is_platform_admin()) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'count', count(*),
    'average', coalesce(round(avg(r.rating)::numeric, 2), 0),
    'distribution', jsonb_build_object(
      '1', count(*) filter (where r.rating = 1),
      '2', count(*) filter (where r.rating = 2),
      '3', count(*) filter (where r.rating = 3),
      '4', count(*) filter (where r.rating = 4),
      '5', count(*) filter (where r.rating = 5)),
    'last_30_days', count(*) filter (where r.created_at > now() - interval '30 days'),
    'replied', count(rp.review_id),
    'response_rate', case when count(*) = 0 then 0
                          else round(100.0 * count(rp.review_id) / count(*), 1) end,
    'unanswered', count(*) - count(rp.review_id)
  ) into v
  from public.clinic_reviews r
  left join public.clinic_review_replies rp on rp.review_id = r.id
  where r.clinic_id = p_clinic_id and r.status = 'published';
  return v;
end $$;

-- ---------------------------------------------------------------------
-- 10. GERBANG KELENGKAPAN DIPERLUAS + PUBLISH WAJIB SIO AKTIF
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
  m_media  text[] := '{}';

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
  if exists (
       select 1 from public.health_workers w
       where w.clinic_id = p_clinic_id and w.is_active and w.worker_type = 'doctor'
         and not exists (
           select 1 from public.health_worker_documents d
           where d.worker_id = w.id and d.doc_type = 'profile_photo'
             and d.review_status <> 'rejected')) then
    m_staff := array_append(m_staff, 'doctor_profile_photo');
  end if;

  -- 6. Identitas visual publik (logo & sampul)
  if not exists (select 1 from public.clinic_media m
                 where m.clinic_id = p_clinic_id and m.kind = 'logo' and m.review_status <> 'rejected') then
    m_media := array_append(m_media, 'media:logo');
  end if;
  if not exists (select 1 from public.clinic_media m
                 where m.clinic_id = p_clinic_id and m.kind = 'cover' and m.review_status <> 'rejected') then
    m_media := array_append(m_media, 'media:cover');
  end if;

  return jsonb_build_object(
    'status', c.status,
    'basic_data',          jsonb_build_object('complete', cardinality(m_basic) = 0, 'missing', to_jsonb(m_basic)),
    'services_facilities', jsonb_build_object('complete', cardinality(m_serv)  = 0, 'missing', to_jsonb(m_serv)),
    'admin_legal',         jsonb_build_object('complete', cardinality(m_legal) = 0, 'missing', to_jsonb(m_legal)),
    'emr_system',          jsonb_build_object('complete', cardinality(m_emr)   = 0, 'missing', to_jsonb(m_emr)),
    'health_workers',      jsonb_build_object('complete', cardinality(m_staff) = 0, 'missing', to_jsonb(m_staff)),
    'public_media',        jsonb_build_object('complete', cardinality(m_media) = 0, 'missing', to_jsonb(m_media)),
    'ready_to_submit', (
      cardinality(m_basic) + cardinality(m_serv) + cardinality(m_legal) +
      cardinality(m_emr) + cardinality(m_staff) + cardinality(m_media) = 0)
  );
end $$;

create or replace function public.set_clinic_published(p_clinic_id uuid, p_published boolean)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_status public.clinic_status;
  v_sio    date;
begin
  if not public.is_clinic_member(p_clinic_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  select status, sio_expiry into v_status, v_sio from public.clinics where id = p_clinic_id;
  if p_published and v_status is distinct from 'verified' then
    raise exception 'clinic_not_verified';
  end if;
  if p_published and (v_sio is null or v_sio < current_date) then
    raise exception 'sio_expired';
  end if;

  perform set_config('app.clinic_workflow', '1', true);
  update public.clinics set is_published = p_published where id = p_clinic_id;
  perform set_config('app.clinic_workflow', '', true);
end $$;

-- ---------------------------------------------------------------------
-- 11. RPC MODERASI (khusus admin platform)
-- ---------------------------------------------------------------------
create or replace function public.review_clinic_document(p_doc_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  if not p_approve and coalesce(p_note, '') = '' then raise exception 'rejection_reason_required'; end if;
  update public.clinic_documents
     set review_status = case when p_approve then 'approved'::public.document_review_status else 'rejected'::public.document_review_status end,
         review_note = case when p_approve then null else p_note end
   where id = p_doc_id;
  if not found then raise exception 'document_not_found'; end if;
end $$;

create or replace function public.review_worker_document(p_doc_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  if not p_approve and coalesce(p_note, '') = '' then raise exception 'rejection_reason_required'; end if;
  update public.health_worker_documents
     set review_status = case when p_approve then 'approved'::public.document_review_status else 'rejected'::public.document_review_status end,
         review_note = case when p_approve then null else p_note end
   where id = p_doc_id;
  if not found then raise exception 'document_not_found'; end if;
end $$;

create or replace function public.review_clinic_media(p_media_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  if not p_approve and coalesce(p_note, '') = '' then raise exception 'rejection_reason_required'; end if;
  update public.clinic_media
     set review_status = case when p_approve then 'approved'::public.document_review_status else 'rejected'::public.document_review_status end,
         review_note = case when p_approve then null else p_note end
   where id = p_media_id;
  if not found then raise exception 'media_not_found'; end if;
end $$;

create or replace function public.resolve_review_report(p_report_id uuid, p_uphold boolean, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare v_review uuid;
begin
  if not public.is_platform_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  update public.review_reports
     set status = case when p_uphold then 'upheld'::public.report_status else 'dismissed'::public.report_status end,
         resolved_by = auth.uid(), resolved_at = now(), resolution_note = p_note
   where id = p_report_id and status = 'open'
   returning review_id into v_review;
  if v_review is null then raise exception 'report_not_found_or_closed'; end if;
  if p_uphold then
    update public.clinic_reviews set status = 'removed' where id = v_review;
  end if;
end $$;

create or replace function public.platform_pending_clinics()
returns table (
  clinic_id uuid, clinic_name text, status public.clinic_status, submitted_at timestamptz,
  docs_pending bigint, worker_docs_pending bigint, media_pending bigint, open_reports bigint
)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then raise exception 'not_authorized' using errcode = '42501'; end if;
  return query
  select c.id, c.clinic_name, c.status, c.submitted_at,
         (select count(*) from public.clinic_documents d where d.clinic_id = c.id and d.review_status = 'pending'),
         (select count(*) from public.health_worker_documents d where d.clinic_id = c.id and d.review_status = 'pending'),
         (select count(*) from public.clinic_media m where m.clinic_id = c.id and m.review_status = 'pending'),
         (select count(*) from public.review_reports r where r.clinic_id = c.id and r.status = 'open')
    from public.clinics c
   where c.status in ('submitted', 'under_review')
      or exists (select 1 from public.clinic_media m where m.clinic_id = c.id and m.review_status = 'pending')
      or exists (select 1 from public.review_reports r where r.clinic_id = c.id and r.status = 'open')
   order by c.submitted_at nulls last;
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'refresh_compliance_alerts(uuid)', 'clinic_compliance_status(uuid)',
    'clinic_review_stats(uuid)', 'review_clinic_document(uuid,boolean,text)',
    'review_worker_document(uuid,boolean,text)', 'review_clinic_media(uuid,boolean,text)',
    'resolve_review_report(uuid,boolean,text)', 'platform_pending_clinics()',
    'clinic_onboarding_status(uuid)', 'set_clinic_published(uuid,boolean)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 12. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.clinic_media            enable row level security;
alter table public.clinic_alerts           enable row level security;
alter table public.encounters              enable row level security;
alter table public.clinic_reviews          enable row level security;
alter table public.clinic_review_replies   enable row level security;
alter table public.review_reports          enable row level security;
alter table public.clinic_feedback_private enable row level security;
alter table public.legal_consents          enable row level security;

-- media: anggota klinik CRUD (status review dilindungi trigger), admin platform baca
drop policy if exists clinic_media_member_all on public.clinic_media;
create policy clinic_media_member_all on public.clinic_media
  for all to authenticated
  using (public.is_clinic_member(clinic_id)) with check (public.is_clinic_member(clinic_id));
drop policy if exists clinic_media_platform_read on public.clinic_media;
create policy clinic_media_platform_read on public.clinic_media
  for select to authenticated using (public.is_platform_admin());

-- alerts: hanya baca
drop policy if exists clinic_alerts_select on public.clinic_alerts;
create policy clinic_alerts_select on public.clinic_alerts
  for select to authenticated
  using (public.is_clinic_member(clinic_id) or public.is_platform_admin());

-- encounters: anggota klinik kelola; pasien lihat miliknya
drop policy if exists encounters_member_all on public.encounters;
create policy encounters_member_all on public.encounters
  for all to authenticated
  using (public.is_clinic_member(clinic_id))
  with check (
    public.is_clinic_member(clinic_id)
    and not exists (select 1 from public.clinic_members m
                     where m.clinic_id = encounters.clinic_id and m.user_id = encounters.patient_user_id));
drop policy if exists encounters_patient_select on public.encounters;
create policy encounters_patient_select on public.encounters
  for select to authenticated using (patient_user_id = auth.uid());
drop policy if exists encounters_platform_read on public.encounters;
create policy encounters_platform_read on public.encounters
  for select to authenticated using (public.is_platform_admin());

-- ulasan: pasien menulis SATU ulasan untuk kunjungan selesai miliknya (<= 30 hari);
-- klinik hanya membaca; penghapusan hanya lewat moderasi admin platform.
drop policy if exists reviews_patient_insert on public.clinic_reviews;
create policy reviews_patient_insert on public.clinic_reviews
  for insert to authenticated
  with check (
    patient_user_id = auth.uid()
    and status = 'published'
    and exists (
      select 1 from public.encounters e
       where e.id = encounter_id
         and e.clinic_id = clinic_reviews.clinic_id
         and e.patient_user_id = auth.uid()
         and e.status = 'completed'
         and e.completed_at > now() - interval '30 days')
  );
drop policy if exists reviews_patient_select on public.clinic_reviews;
create policy reviews_patient_select on public.clinic_reviews
  for select to authenticated using (patient_user_id = auth.uid());
drop policy if exists reviews_member_select on public.clinic_reviews;
create policy reviews_member_select on public.clinic_reviews
  for select to authenticated
  using (public.is_clinic_member(clinic_id) and status = 'published');
drop policy if exists reviews_platform_read on public.clinic_reviews;
create policy reviews_platform_read on public.clinic_reviews
  for select to authenticated using (public.is_platform_admin());

-- balasan: klinik boleh membalas satu kali (tanpa edit/hapus)
drop policy if exists replies_member_insert on public.clinic_review_replies;
create policy replies_member_insert on public.clinic_review_replies
  for insert to authenticated with check (public.is_clinic_member(clinic_id));
drop policy if exists replies_member_select on public.clinic_review_replies;
create policy replies_member_select on public.clinic_review_replies
  for select to authenticated
  using (public.is_clinic_member(clinic_id) or public.is_platform_admin());

-- laporan: klinik melaporkan ulasan kliniknya; keputusan di admin platform
drop policy if exists reports_member_insert on public.review_reports;
create policy reports_member_insert on public.review_reports
  for insert to authenticated
  with check (public.is_clinic_member(clinic_id) and status = 'open');
drop policy if exists reports_member_select on public.review_reports;
create policy reports_member_select on public.review_reports
  for select to authenticated
  using (public.is_clinic_member(clinic_id) or public.is_platform_admin());

-- masukan privat: pasien hanya menulis; klinik membaca & menindaklanjuti
drop policy if exists feedback_patient_insert on public.clinic_feedback_private;
create policy feedback_patient_insert on public.clinic_feedback_private
  for insert to authenticated
  with check (
    patient_user_id = auth.uid()
    and status = 'new'
    and internal_note is null
    and exists (
      select 1 from public.encounters e
       where e.id = encounter_id
         and e.clinic_id = clinic_feedback_private.clinic_id
         and e.patient_user_id = auth.uid()
         and e.status = 'completed'
         and e.completed_at > now() - interval '30 days')
  );
drop policy if exists feedback_member_select on public.clinic_feedback_private;
create policy feedback_member_select on public.clinic_feedback_private
  for select to authenticated using (public.is_clinic_member(clinic_id));
drop policy if exists feedback_member_update on public.clinic_feedback_private;
create policy feedback_member_update on public.clinic_feedback_private
  for update to authenticated
  using (public.is_clinic_member(clinic_id)) with check (public.is_clinic_member(clinic_id));

-- persetujuan hukum: milik sendiri
drop policy if exists consents_select_own on public.legal_consents;
create policy consents_select_own on public.legal_consents
  for select to authenticated using (user_id = auth.uid());
drop policy if exists consents_insert_own on public.legal_consents;
create policy consents_insert_own on public.legal_consents
  for insert to authenticated with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 13. STORAGE: bucket publik untuk logo / sampul / galeri
--     Path: {clinic_id}/{kind}/{uuid}-{nama_file}. Berkas baru tidak
--     ditampilkan di profil publik sebelum disetujui admin platform.
--     Jangan unggah foto yang berisi data pasien.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('clinic-public-media', 'clinic-public-media', true, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists public_media_select on storage.objects;
create policy public_media_select on storage.objects
  for select to authenticated
  using (bucket_id = 'clinic-public-media'
         and (public.can_access_clinic_path(name) or public.is_platform_admin()));

drop policy if exists public_media_insert on storage.objects;
create policy public_media_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'clinic-public-media' and public.can_access_clinic_path(name));

drop policy if exists public_media_update on storage.objects;
create policy public_media_update on storage.objects
  for update to authenticated
  using (bucket_id = 'clinic-public-media' and public.can_access_clinic_path(name))
  with check (bucket_id = 'clinic-public-media' and public.can_access_clinic_path(name));

drop policy if exists public_media_delete on storage.objects;
create policy public_media_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'clinic-public-media' and public.can_access_clinic_path(name));

-- ---------------------------------------------------------------------
-- 14. (OPSIONAL) Jadwal harian peringatan masa berlaku lewat pg_cron.
--     Aktifkan extension pg_cron di Dashboard, lalu jalankan manual:
--
--   select cron.schedule('compliance-alerts-daily', '0 1 * * *',
--                        $$select public.refresh_compliance_alerts(null)$$);
-- ---------------------------------------------------------------------
