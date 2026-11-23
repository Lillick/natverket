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
