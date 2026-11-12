-- Align databases created from an earlier profiles schema with the
-- handle_new_user() trigger defined in 0001_clinic_core.sql.
begin;

alter table public.profiles
  add column if not exists account_type text;

update public.profiles
set account_type = 'patient'
where account_type is null;

alter table public.profiles
  alter column account_type set default 'patient',
  alter column account_type set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_account_type_check'
  ) then
    alter table public.profiles
      add constraint profiles_account_type_check
      check (account_type in ('clinic', 'patient', 'health_worker'));
  end if;
end
$$;

commit;
