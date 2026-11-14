-- Limit operational status changes to clinic owners and admins.
-- Queue and facility metrics remain calculated/read-only data.

revoke update on public.clinic_operations_internal from anon, authenticated;

drop policy if exists clinic_operations_internal_member_update
  on public.clinic_operations_internal;

create or replace function public.update_clinic_operational_status(
  p_clinic_id uuid,
  p_facility_status public.facility_operating_status,
  p_queue_process_status public.queue_process_status
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_operations public.clinic_operations_internal;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.has_clinic_role(p_clinic_id, array['owner', 'admin']) then
    raise exception 'not_authorized';
  end if;

  update public.clinic_operations_internal
     set facility_status = p_facility_status,
         queue_process_status = p_queue_process_status
   where clinic_id = p_clinic_id
   returning * into v_operations;

  if not found then
    raise exception 'clinic_not_found';
  end if;

  return to_jsonb(v_operations);
end;
$$;

revoke all on function public.update_clinic_operational_status(
  uuid,
  public.facility_operating_status,
  public.queue_process_status
) from public, anon;
grant execute on function public.update_clinic_operational_status(
  uuid,
  public.facility_operating_status,
  public.queue_process_status
) to authenticated;
