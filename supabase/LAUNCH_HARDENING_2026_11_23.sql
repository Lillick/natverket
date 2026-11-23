-- NÄTVERKET launch hardening – applied 2026-11-23
-- Re-run-safe SQL. This records the database changes made for the controlled pilot.
-- Public intake remains closed. This does NOT constitute legal GDPR approval.

begin;

-- Correct tenant row filtering. The old unqualified id was bound to m.id.
drop policy if exists tenant_org_select_member on public.tenant_organizations;
create policy tenant_org_select_member
on public.tenant_organizations
for select to authenticated
using (
  (select public.is_admin())
  or exists (
    select 1 from public.organization_memberships m
    where m.organization_id = tenant_organizations.id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  )
);

-- Admin-only review access to company applications; no public or member access.
drop policy if exists company_applications_admin_select on public.company_applications;
create policy company_applications_admin_select
on public.company_applications for select to authenticated
using ((select public.is_admin()));

drop policy if exists company_applications_admin_update on public.company_applications;
create policy company_applications_admin_update
on public.company_applications for update to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

grant select, update on public.company_applications to authenticated;
revoke all on public.company_applications from anon, public;
create index if not exists company_applications_reviewed_by_idx
on public.company_applications(reviewed_by);

-- Keep creator attribution fixed when a CRM record is edited.
drop policy if exists crm_contacts_org_update on public.crm_contacts;
create policy crm_contacts_org_update
on public.crm_contacts for update to authenticated
using (exists (
  select 1 from public.organization_memberships m
  where m.organization_id=crm_contacts.organization_id
    and m.user_id=(select auth.uid()) and m.status='active'
    and m.member_role in ('owner','admin','member')
))
with check (
  created_by=(select auth.uid())
  and exists (
    select 1 from public.organization_memberships m
    where m.organization_id=crm_contacts.organization_id
      and m.user_id=(select auth.uid()) and m.status='active'
      and m.member_role in ('owner','admin','member')
  )
);

drop policy if exists crm_leads_org_update on public.crm_leads;
create policy crm_leads_org_update
on public.crm_leads for update to authenticated
using (exists (
  select 1 from public.organization_memberships m
  where m.organization_id=crm_leads.organization_id
    and m.user_id=(select auth.uid()) and m.status='active'
    and m.member_role in ('owner','admin','member')
))
with check (
  created_by=(select auth.uid())
  and exists (
    select 1 from public.organization_memberships m
    where m.organization_id=crm_leads.organization_id
      and m.user_id=(select auth.uid()) and m.status='active'
      and m.member_role in ('owner','admin','member')
  )
);

drop policy if exists crm_tasks_org_update on public.crm_tasks;
create policy crm_tasks_org_update
on public.crm_tasks for update to authenticated
using (exists (
  select 1 from public.organization_memberships m
  where m.organization_id=crm_tasks.organization_id
    and m.user_id=(select auth.uid()) and m.status='active'
    and m.member_role in ('owner','admin','member')
))
with check (
  created_by=(select auth.uid())
  and exists (
    select 1 from public.organization_memberships m
    where m.organization_id=crm_tasks.organization_id
      and m.user_id=(select auth.uid()) and m.status='active'
      and m.member_role in ('owner','admin','member')
  )
);

-- Metadata-only audit events for the CRM and company intake review records.
drop trigger if exists audit_company_applications_changes on public.company_applications;
create trigger audit_company_applications_changes after insert or update or delete
on public.company_applications for each row execute function public.write_audit_event();

drop trigger if exists audit_tenant_organizations_changes on public.tenant_organizations;
create trigger audit_tenant_organizations_changes after insert or update or delete
on public.tenant_organizations for each row execute function public.write_audit_event();

drop trigger if exists audit_organization_memberships_changes on public.organization_memberships;
create trigger audit_organization_memberships_changes after insert or update or delete
on public.organization_memberships for each row execute function public.write_audit_event();

drop trigger if exists audit_crm_contacts_changes on public.crm_contacts;
create trigger audit_crm_contacts_changes after insert or update or delete
on public.crm_contacts for each row execute function public.write_audit_event();

drop trigger if exists audit_crm_leads_changes on public.crm_leads;
create trigger audit_crm_leads_changes after insert or update or delete
on public.crm_leads for each row execute function public.write_audit_event();

drop trigger if exists audit_crm_activities_changes on public.crm_activities;
create trigger audit_crm_activities_changes after insert or update or delete
on public.crm_activities for each row execute function public.write_audit_event();

drop trigger if exists audit_crm_tasks_changes on public.crm_tasks;
create trigger audit_crm_tasks_changes after insert or update or delete
on public.crm_tasks for each row execute function public.write_audit_event();

commit;

-- Convert admin-gated RPC functions to SECURITY INVOKER.
-- Their underlying tables already have admin-only RLS policies.
-- Keep is_admin() as SECURITY DEFINER to avoid recursive profile RLS checks.
do $$
declare
  r record;
  v_definition text;
begin
  for r in
    select p.oid
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prosecdef
      and p.proname in (
        'approve_match_contact','assign_skill_to_person','calculate_commission',
        'generate_request_matches','get_skill_catalogue','record_match_response',
        'search_people_by_skill'
      )
  loop
    v_definition := pg_get_functiondef(r.oid);
    v_definition := regexp_replace(v_definition,'SECURITY DEFINER','SECURITY INVOKER','i');
    execute v_definition;
  end loop;
end $$;

revoke execute on function public.approve_match_contact(uuid) from public, anon;
grant execute on function public.approve_match_contact(uuid) to authenticated, service_role;
revoke execute on function public.assign_skill_to_person(uuid, uuid) from public, anon;
grant execute on function public.assign_skill_to_person(uuid, uuid) to authenticated, service_role;
revoke execute on function public.calculate_commission(uuid) from public, anon;
grant execute on function public.calculate_commission(uuid) to authenticated, service_role;
revoke execute on function public.generate_request_matches(uuid) from public, anon;
grant execute on function public.generate_request_matches(uuid) to authenticated, service_role;
revoke execute on function public.get_skill_catalogue() from public, anon;
grant execute on function public.get_skill_catalogue() to authenticated, service_role;
revoke execute on function public.record_match_response(uuid, text) from public, anon;
grant execute on function public.record_match_response(uuid, text) to authenticated, service_role;
revoke execute on function public.search_people_by_skill(text, text) from public, anon;
grant execute on function public.search_people_by_skill(text, text) to authenticated, service_role;
