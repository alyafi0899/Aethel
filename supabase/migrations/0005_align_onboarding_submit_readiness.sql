-- Align server-side readiness with the five required onboarding sections.
-- Apply after 0004 so the informational RME column is present.
begin;

alter table public.clinic_emr_settings
  add column if not exists emr_choice_confirmed boolean not null default false;

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
  m_staff  text[] := '{}';
  m_media  text[] := '{}';
  v_reco   text[] := '{}';
begin
  if not (public.is_clinic_member(p_clinic_id) or public.is_platform_admin()) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  select * into c from public.clinics where id = p_clinic_id;
  if not found then
    raise exception 'clinic_not_found';
  end if;
  select * into e from public.clinic_emr_settings where clinic_id = p_clinic_id;

  if coalesce(c.clinic_name, '') = '' then
    m_basic := array_append(m_basic, 'clinic_name');
  end if;
  if c.legal_entity_type is null then
    m_basic := array_append(m_basic, 'legal_entity_type');
  end if;
  if coalesce(c.address_full, '') = '' then
    m_basic := array_append(m_basic, 'address_full');
  end if;
  if c.latitude is null or c.longitude is null then
    m_basic := array_append(m_basic, 'coordinates');
  end if;
  if coalesce(c.phone, '') = '' then
    m_basic := array_append(m_basic, 'phone');
  end if;
  if coalesce(c.email, '') = '' then
    m_basic := array_append(m_basic, 'email');
  end if;
  if coalesce(c.sio_number, '') = '' then
    m_basic := array_append(m_basic, 'sio_number');
  end if;
  if c.sio_expiry is null or c.sio_expiry < current_date then
    m_basic := array_append(m_basic, 'sio_expiry');
  end if;
  if coalesce(c.npwp, '') = '' then
    m_basic := array_append(m_basic, 'npwp');
  end if;
  if coalesce(c.fasyankes_code, '') = '' then
    m_basic := array_append(m_basic, 'fasyankes_code');
  end if;
  if c.legal_entity_type in ('pt', 'foundation')
     and coalesce(c.deed_number, '') = '' then
    m_basic := array_append(m_basic, 'deed_number');
  end if;
  if not exists (
    select 1 from public.clinic_documents d
    where d.clinic_id = p_clinic_id and d.doc_type = 'sio'
  ) then
    m_basic := array_append(m_basic, 'doc:sio');
  end if;
  if c.legal_entity_type in ('pt', 'foundation') and not exists (
    select 1 from public.clinic_documents d
    where d.clinic_id = p_clinic_id
      and d.doc_type = 'deed_of_establishment'
  ) then
    m_basic := array_append(m_basic, 'doc:deed_of_establishment');
  end if;

  if not exists (
    select 1 from public.clinic_services s
    where s.clinic_id = p_clinic_id and s.is_active
  ) then
    m_serv := array_append(m_serv, 'services');
  end if;
  if not exists (
    select 1 from public.clinic_facilities f
    where f.clinic_id = p_clinic_id
  ) then
    m_serv := array_append(m_serv, 'facilities');
  end if;
  if not exists (
    select 1 from public.clinic_equipment q
    where q.clinic_id = p_clinic_id
  ) then
    m_serv := array_append(m_serv, 'equipment');
  end if;
  if not exists (
    select 1 from public.clinic_operating_hours h
    where h.clinic_id = p_clinic_id and h.is_open
  ) then
    m_serv := array_append(m_serv, 'operating_hours');
  end if;

  if not exists (
    select 1 from public.clinic_documents d
    where d.clinic_id = p_clinic_id
      and d.doc_type = 'registration_request_letter'
  ) then
    m_legal := array_append(m_legal, 'doc:registration_request_letter');
  end if;
  if not exists (
    select 1 from public.clinic_documents d
    where d.clinic_id = p_clinic_id
      and d.doc_type = 'quality_commitment_statement'
  ) then
    m_legal := array_append(m_legal, 'doc:quality_commitment_statement');
  end if;
  if not exists (
    select 1 from public.clinic_org_structure o
    where o.clinic_id = p_clinic_id
  ) then
    m_legal := array_append(m_legal, 'org_structure');
  end if;
  if c.bpjs_registered then
    if coalesce(c.bpjs_facility_code, '') = '' then
      m_legal := array_append(m_legal, 'bpjs_facility_code');
    end if;
    if not exists (
      select 1 from public.clinic_documents d
      where d.clinic_id = p_clinic_id
        and d.doc_type = 'bpjs_cooperation_proof'
    ) then
      m_legal := array_append(m_legal, 'doc:bpjs_cooperation_proof');
    end if;
  end if;

  if not exists (
    select 1 from public.health_workers w
    where w.clinic_id = p_clinic_id
      and w.is_active and w.is_person_in_charge
  ) then
    m_staff := array_append(m_staff, 'person_in_charge');
  end if;
  if not exists (
    select 1 from public.health_workers w
    where w.clinic_id = p_clinic_id
      and w.is_active and w.worker_type = 'doctor'
      and coalesce(w.str_number, '') <> ''
      and coalesce(w.sip_number, '') <> ''
  ) then
    m_staff := array_append(m_staff, 'doctor_with_str_sip');
  end if;
  if exists (
    select 1 from public.health_workers w
    where w.clinic_id = p_clinic_id
      and w.is_active and w.worker_type = 'doctor'
      and not exists (
        select 1 from public.health_worker_documents d
        where d.worker_id = w.id
          and d.doc_type = 'profile_photo'
          and d.review_status <> 'rejected'
      )
  ) then
    m_staff := array_append(m_staff, 'doctor_profile_photo');
  end if;

  if not exists (
    select 1 from public.clinic_media m
    where m.clinic_id = p_clinic_id
      and m.kind = 'logo'
      and m.review_status <> 'rejected'
  ) then
    m_media := array_append(m_media, 'media:logo');
  end if;
  if not exists (
    select 1 from public.clinic_media m
    where m.clinic_id = p_clinic_id
      and m.kind = 'cover'
      and m.review_status <> 'rejected'
  ) then
    m_media := array_append(m_media, 'media:cover');
  end if;

  if not coalesce(e.emr_choice_confirmed, false) then
    v_reco := array_append(v_reco, 'emr_choice');
  elsif e.emr_app_type in ('third_party', 'internal')
        and coalesce(e.emr_app_name, '') = '' then
    v_reco := array_append(v_reco, 'emr_app_name');
  end if;
  if c.status = 'verified'
     and coalesce(e.emr_choice_confirmed, false)
     and e.emr_app_type <> 'none'
     and coalesce(e.satusehat_organization_id, '') = '' then
    v_reco := array_append(v_reco, 'satusehat_organization_id');
  end if;
  if not exists (
    select 1 from public.clinic_documents d
    where d.clinic_id = p_clinic_id and d.doc_type = 'service_sop'
  ) then
    v_reco := array_append(v_reco, 'doc:service_sop');
  end if;
  if not exists (
    select 1 from public.clinic_media m
    where m.clinic_id = p_clinic_id and m.kind = 'gallery'
  ) then
    v_reco := array_append(v_reco, 'media:gallery');
  end if;

  return jsonb_build_object(
    'status', c.status,
    'basic_data', jsonb_build_object(
      'complete', cardinality(m_basic) = 0,
      'missing', to_jsonb(m_basic)
    ),
    'services_facilities', jsonb_build_object(
      'complete', cardinality(m_serv) = 0,
      'missing', to_jsonb(m_serv)
    ),
    'admin_legal', jsonb_build_object(
      'complete', cardinality(m_legal) = 0,
      'missing', to_jsonb(m_legal)
    ),
    'emr_system', jsonb_build_object('complete', true, 'missing', '[]'::jsonb),
    'health_workers', jsonb_build_object(
      'complete', cardinality(m_staff) = 0,
      'missing', to_jsonb(m_staff)
    ),
    'public_media', jsonb_build_object(
      'complete', cardinality(m_media) = 0,
      'missing', to_jsonb(m_media)
    ),
    'recommendations', to_jsonb(v_reco),
    'ready_to_submit', (
      cardinality(m_basic) + cardinality(m_serv) + cardinality(m_legal) +
      cardinality(m_staff) + cardinality(m_media) = 0
    )
  );
end $$;

notify pgrst, 'reload schema';

commit;
