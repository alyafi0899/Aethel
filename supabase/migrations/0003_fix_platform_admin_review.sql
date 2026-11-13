-- =====================================================================
--  PROMETHEON  -  0003_fix_platform_admin_review.sql
--  Perbaikan fungsi otorisasi Admin Platform (is_platform_admin)
--  dan penanganan persetujuan pendaftaran klinik (review_clinic).
--  Mendukung pencarian via Clinic ID maupun Owner User ID.
--  Aman dijalankan di Supabase SQL Editor.
-- =====================================================================

-- 1. Perbarui is_platform_admin agar mendukung eksekusi dari SQL Editor (auth.uid() null / service_role)
create or replace function public.is_platform_admin()
returns boolean
language plpgsql stable security definer
set search_path = ''
as $$
begin
  -- Jika dipanggil dari SQL Editor (service_role / postgres) di mana auth.uid() IS NULL
  if auth.uid() is null then
    return true;
  end if;

  return exists (
    select 1 from public.platform_admins p
    where p.user_id = auth.uid()
  );
end $$;

-- 2. Perbarui review_clinic agar mendukung p_clinic_id berupa Clinic ID maupun Owner User ID
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
   where id = p_clinic_id or owner_id = p_clinic_id;

  perform set_config('app.clinic_workflow', '', true);
end $$;

-- Pastikan izin eksekusi diberikan ke authenticated
grant execute on function public.review_clinic(uuid,boolean,text) to authenticated;
