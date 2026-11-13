-- Ensure the RME confirmation flag exists and refresh PostgREST metadata.
begin;

alter table public.clinic_emr_settings
  add column if not exists emr_choice_confirmed boolean not null default false;

notify pgrst, 'reload schema';

commit;
