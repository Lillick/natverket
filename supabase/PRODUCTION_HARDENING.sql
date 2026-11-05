-- NÄTVERKET – samlad säkerhets- och dataskyddsmigrering
-- Kör EN gång i Supabase SQL Editor efter att ha kontrollerat att rätt projekt är valt.
-- Idempotent: kan köras igen. Skapar INTE publika formulär eller anonym INSERT.
-- Säkerhetsprincip: endast admin får använda interna register via authenticated.
-- OBS: SQL kan inte ensam göra tjänsten GDPR-kompatibel eller ersätta juridisk granskning.

begin;

-- ---------------------------------------------------------------------------
-- 1. Ta bort direkt tabell-/sekvensåtkomst för anon och PUBLIC.
-- Behåller befintliga authenticated-privilegier och RLS-policyer.
-- ---------------------------------------------------------------------------
revoke all privileges on all tables in schema public from anon, public;
revoke all privileges on all sequences in schema public from anon, public;

-- ---------------------------------------------------------------------------
-- 2. Begränsa RPC-funktioner. Funktionerna kontrollerar dessutom is_admin()
-- internt. search_path är redan tomt i de granskade funktionerna.
-- ---------------------------------------------------------------------------
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;

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

-- ---------------------------------------------------------------------------
-- 3. Förbättra matchningsfunktionen: endast aktiva personer kan föreslås.
-- Behåller tidigare matchningslogik och befintliga matchningar.
-- ---------------------------------------------------------------------------
create or replace function public.generate_request_matches(p_request_id uuid)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare
    v_count integer := 0;
    v_request record;
begin
    if not public.is_admin() then
        raise exception 'Endast administratören får skapa matchningar';
    end if;

    select id, title, description, city
      into v_request
      from public.requests
     where id = p_request_id;

    if not found then
        raise exception 'Uppdraget kunde inte hittas';
    end if;

    insert into public.request_matches (
        request_id, person_id, status, match_score, match_reason
    )
    select
        p_request_id,
        p.id,
        'suggested',
        case
            when lower(coalesce(p.city, '')) =
                 lower(coalesce(v_request.city, ''))
                 and coalesce(v_request.city, '') <> ''
            then 100
            else 80
        end,
        'Kompetensmatch: ' || string_agg(distinct s.name, ', ')
    from public.people p
    join public.person_skills ps on ps.person_id = p.id
    join public.skills s on s.id = ps.skill_id
    where p.status = 'active'
      and (
          coalesce(v_request.title, '') || ' ' ||
          coalesce(v_request.description, '')
      ) ilike '%' || s.name || '%'
      and not exists (
          select 1
            from public.request_matches rm
           where rm.request_id = p_request_id
             and rm.person_id = p.id
      )
    group by p.id, p.city;

    get diagnostics v_count = row_count;
    return v_count;
end;
$function$;

-- ---------------------------------------------------------------------------
-- 4. GDPR-operativt register för inkomna rättighetsförfrågningar.
-- Det är ett internt ärenderegister, INTE ett publikt inlämningsformulär.
-- ---------------------------------------------------------------------------
create table if not exists public.privacy_requests (
    id uuid primary key default gen_random_uuid(),
    requester_name text not null,
    requester_email text not null,
    request_type text not null check (
        request_type in (
            'access', 'rectification', 'erasure', 'restriction',
            'objection', 'portability', 'withdraw_consent', 'other'
        )
    ),
    details text,
    status text not null default 'new'
        check (status in ('new', 'in_progress', 'completed', 'rejected')),
    received_at timestamptz not null default now(),
    due_date date,
    completed_at timestamptz,
    handled_by uuid references public.profiles(id) on delete set null,
    internal_notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.privacy_requests enable row level security;

drop policy if exists "Admins manage privacy requests" on public.privacy_requests;
create policy "Admins manage privacy requests"
on public.privacy_requests
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select, insert, update, delete on public.privacy_requests to authenticated;
revoke all on public.privacy_requests from anon, public;

-- ---------------------------------------------------------------------------
-- 5. Internt register över dokumenterade behandlingsändamål/rättsliga grunder.
-- Lägg endast in uppgifter som behövs. Samtycke används bara där samtycke
-- faktiskt är den valda rättsliga grunden.
-- ---------------------------------------------------------------------------
create table if not exists public.privacy_records (
    id uuid primary key default gen_random_uuid(),
    subject_type text not null
        check (subject_type in ('person', 'customer', 'company')),
    subject_id uuid not null,
    purpose text not null,
    legal_basis text not null
        check (legal_basis in (
            'consent', 'contract', 'legal_obligation',
            'legitimate_interests', 'vital_interests', 'public_task'
        )),
    notice_version text,
    consent_given boolean,
    recorded_at timestamptz not null default now(),
    withdrawn_at timestamptz,
    source text,
    recorded_by uuid references public.profiles(id) on delete set null,
    notes text,
    created_at timestamptz not null default now(),
    constraint privacy_records_consent_consistency check (
        (legal_basis = 'consent' and consent_given is not null)
        or (legal_basis <> 'consent' and consent_given is null)
    )
);

create index if not exists privacy_records_subject_idx
    on public.privacy_records(subject_type, subject_id);
create index if not exists privacy_records_purpose_idx
    on public.privacy_records(purpose);

alter table public.privacy_records enable row level security;

drop policy if exists "Admins manage privacy records" on public.privacy_records;
create policy "Admins manage privacy records"
on public.privacy_records
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select, insert, update, delete on public.privacy_records to authenticated;
revoke all on public.privacy_records from anon, public;

-- ---------------------------------------------------------------------------
-- 6. Minimal administrativ revisionslogg. Loggar händelse, aktör och rad-id,
-- inte gamla/nya personuppgiftsvärden.
-- ---------------------------------------------------------------------------
create table if not exists public.audit_events (
    id bigint generated always as identity primary key,
    occurred_at timestamptz not null default now(),
    actor_id uuid,
    table_name text not null,
    row_key text,
    operation text not null check (operation in ('INSERT', 'UPDATE', 'DELETE'))
);

create index if not exists audit_events_occurred_at_idx
    on public.audit_events(occurred_at desc);
create index if not exists audit_events_table_row_idx
    on public.audit_events(table_name, row_key);

alter table public.audit_events enable row level security;

drop policy if exists "Admins read audit events" on public.audit_events;
create policy "Admins read audit events"
on public.audit_events
for select
to authenticated
using (public.is_admin());

grant select on public.audit_events to authenticated;
revoke insert, update, delete, truncate, references, trigger
    on public.audit_events from anon, public, authenticated;

create or replace function public.write_audit_event()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
    v_row jsonb;
    v_key text;
begin
    if tg_op = 'DELETE' then
        v_row := to_jsonb(old);
    else
        v_row := to_jsonb(new);
    end if;

    v_key := coalesce(
        v_row ->> 'id',
        concat_ws(':', v_row ->> 'person_id', v_row ->> 'skill_id')
    );

    insert into public.audit_events(actor_id, table_name, row_key, operation)
    values ((select auth.uid()), tg_table_name, v_key, tg_op);

    if tg_op = 'DELETE' then
        return old;
    end if;
    return new;
end;
$function$;

revoke execute on function public.write_audit_event() from public, anon, authenticated;

drop trigger if exists audit_people_changes on public.people;
create trigger audit_people_changes after insert or update or delete on public.people
for each row execute function public.write_audit_event();

drop trigger if exists audit_customers_changes on public.customers;
create trigger audit_customers_changes after insert or update or delete on public.customers
for each row execute function public.write_audit_event();

drop trigger if exists audit_companies_changes on public.companies;
create trigger audit_companies_changes after insert or update or delete on public.companies
for each row execute function public.write_audit_event();

drop trigger if exists audit_requests_changes on public.requests;
create trigger audit_requests_changes after insert or update or delete on public.requests
for each row execute function public.write_audit_event();

drop trigger if exists audit_matches_changes on public.request_matches;
create trigger audit_matches_changes after insert or update or delete on public.request_matches
for each row execute function public.write_audit_event();

drop trigger if exists audit_commissions_changes on public.commissions;
create trigger audit_commissions_changes after insert or update or delete on public.commissions
for each row execute function public.write_audit_event();

-- ---------------------------------------------------------------------------
-- 7. Uppdatera updated_at automatiskt på de två nya ärendetabellerna.
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path to ''
as $function$
begin
    new.updated_at := now();
    return new;
end;
$function$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;

drop trigger if exists privacy_requests_set_updated_at on public.privacy_requests;
create trigger privacy_requests_set_updated_at
before update on public.privacy_requests
for each row execute function public.set_updated_at();

commit;

-- ---------------------------------------------------------------------------
-- 8. Kontrollresultat. Förväntat: anon_* = false på alla public-tabeller,
-- RLS = true, anon_is_admin_execute = false, authenticated_is_admin_execute=true.
-- ---------------------------------------------------------------------------
select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    has_table_privilege('anon', c.oid, 'SELECT') as anon_select,
    has_table_privilege('anon', c.oid, 'INSERT') as anon_insert,
    has_table_privilege('anon', c.oid, 'UPDATE') as anon_update,
    has_table_privilege('anon', c.oid, 'DELETE') as anon_delete
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
order by c.relname;

select
    has_function_privilege('anon', 'public.is_admin()', 'EXECUTE') as anon_is_admin_execute,
    has_function_privilege('authenticated', 'public.is_admin()', 'EXECUTE') as authenticated_is_admin_execute;

select
    (select count(*) from public.privacy_requests) as privacy_requests_count,
    (select count(*) from public.privacy_records) as privacy_records_count,
    (select count(*) from public.audit_events) as audit_events_count;
