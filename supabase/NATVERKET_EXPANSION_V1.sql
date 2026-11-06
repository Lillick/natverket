-- NÄTVERKET expansion v1 – LIVE, profiler, omdömen och adminnotiser
-- Kör endast i rätt Supabase-projekt efter backup. Ingen publik åtkomst öppnas.
-- Alla publika flöden ska senare gå via serverfunktioner med validering och rate limit.

begin;

create table if not exists public.live_posts (
 id uuid primary key default gen_random_uuid(),
 request_id uuid references public.requests(id) on delete set null,
 category_key text not null,
 title text not null check (char_length(title) between 4 and 140),
 description text not null check (char_length(description) between 10 and 2500),
 city text not null,
 urgency text not null default 'planned' check (urgency in ('urgent','soon','planned')),
 needed_at timestamptz,
 status text not null default 'pending_review' check (status in ('pending_review','published','matched','booked','completed','cancelled','expired')),
 created_at timestamptz not null default now(),
 expires_at timestamptz
);

create table if not exists public.service_profiles (
 id uuid primary key default gen_random_uuid(),
 person_id uuid not null unique references public.people(id) on delete cascade,
 headline text,
 bio text,
 service_categories text[] not null default '{}',
 service_areas text[] not null default '{}',
 profile_visibility text not null default 'private' check (profile_visibility in ('private','unlisted','public')),
 verification_status text not null default 'unverified' check (verification_status in ('unverified','pending','verified','suspended')),
 created_at timestamptz not null default now()
);

create table if not exists public.provider_recommendations (
 id uuid primary key default gen_random_uuid(),
 provider_person_id uuid not null references public.people(id) on delete cascade,
 recommender_name text not null,
 quote text not null check (char_length(quote) between 8 and 400),
 publication_consent boolean not null default false,
 moderation_status text not null default 'pending' check (moderation_status in ('pending','approved','rejected','withdrawn')),
 created_at timestamptz not null default now(),
 moderated_at timestamptz,
 moderated_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.provider_reviews (
 id uuid primary key default gen_random_uuid(),
 provider_person_id uuid not null references public.people(id) on delete cascade,
 request_id uuid references public.requests(id) on delete set null,
 rating integer not null check (rating between 1 and 5),
 review_text text check (review_text is null or char_length(review_text) <= 1000),
 verified_job boolean not null default false,
 moderation_status text not null default 'pending' check (moderation_status in ('pending','approved','rejected','hidden')),
 created_at timestamptz not null default now(),
 moderated_at timestamptz,
 moderated_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.admin_notifications (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 notification_type text not null,
 title text not null,
 message text not null,
 entity_type text,
 entity_id uuid,
 created_at timestamptz not null default now(),
 read_at timestamptz
);

alter table public.live_posts enable row level security;
alter table public.service_profiles enable row level security;
alter table public.provider_recommendations enable row level security;
alter table public.provider_reviews enable row level security;
alter table public.admin_notifications enable row level security;

drop policy if exists "Admins manage live posts" on public.live_posts;
create policy "Admins manage live posts" on public.live_posts for all to authenticated
using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Admins manage service profiles" on public.service_profiles;
create policy "Admins manage service profiles" on public.service_profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Admins manage recommendations" on public.provider_recommendations;
create policy "Admins manage recommendations" on public.provider_recommendations for all to authenticated
using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Admins manage provider reviews" on public.provider_reviews;
create policy "Admins manage provider reviews" on public.provider_reviews for all to authenticated
using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Admins read own notifications" on public.admin_notifications;
create policy "Admins read own notifications" on public.admin_notifications for select to authenticated
using (public.is_admin() and recipient_id = auth.uid());
drop policy if exists "Admins update own notifications" on public.admin_notifications;
create policy "Admins update own notifications" on public.admin_notifications for update to authenticated
using (public.is_admin() and recipient_id = auth.uid())
with check (public.is_admin() and recipient_id = auth.uid());

revoke all on public.live_posts, public.service_profiles, public.provider_recommendations, public.provider_reviews, public.admin_notifications from anon, public;
grant select, insert, update, delete on public.live_posts, public.service_profiles, public.provider_recommendations, public.provider_reviews to authenticated;
grant select, update on public.admin_notifications to authenticated;

create or replace function public.notify_nverket_admins()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
 v_title text;
 v_message text;
 v_type text;
begin
 if tg_table_name = 'requests' then
  v_title := 'Ny förfrågan';
  v_message := coalesce(new.title, 'En ny förfrågan har kommit in');
  v_type := 'new_request';
 elsif tg_table_name = 'live_posts' then
  v_title := case when new.urgency = 'urgent' then 'Akut uppdrag i NÄTVERKET LIVE' else 'Nytt uppdrag i NÄTVERKET LIVE' end;
  v_message := new.title || ' · ' || new.city;
  v_type := 'new_live_post';
 elsif tg_table_name = 'provider_reviews' then
  v_title := 'Nytt omdöme väntar på granskning';
  v_message := 'Ett nytt leverantörsomdöme har skickats in';
  v_type := 'review_pending';
 elsif tg_table_name = 'provider_recommendations' then
  v_title := 'Ny rekommendation väntar på granskning';
  v_message := 'En rekommendation väntar på granskning';
  v_type := 'recommendation_pending';
 else
  return new;
 end if;
 insert into public.admin_notifications(recipient_id, notification_type, title, message, entity_type, entity_id)
 select p.id, v_type, v_title, v_message, tg_table_name, new.id
 from public.profiles p where p.role = 'admin';
 return new;
end;
$$;

revoke execute on function public.notify_nverket_admins() from public, anon, authenticated;

drop trigger if exists notify_admin_new_request on public.requests;
create trigger notify_admin_new_request after insert on public.requests
for each row execute function public.notify_nverket_admins();
drop trigger if exists notify_admin_new_live_post on public.live_posts;
create trigger notify_admin_new_live_post after insert on public.live_posts
for each row execute function public.notify_nverket_admins();
drop trigger if exists notify_admin_new_review on public.provider_reviews;
create trigger notify_admin_new_review after insert on public.provider_reviews
for each row execute function public.notify_nverket_admins();
drop trigger if exists notify_admin_new_recommendation on public.provider_recommendations;
create trigger notify_admin_new_recommendation after insert on public.provider_recommendations
for each row execute function public.notify_nverket_admins();

do $$
begin
 if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
 and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'admin_notifications') then
  alter publication supabase_realtime add table public.admin_notifications;
 end if;
end $$;

commit;

select c.relname, c.relrowsecurity,
 has_table_privilege('anon', c.oid, 'SELECT') as anon_select,
 has_table_privilege('anon', c.oid, 'INSERT') as anon_insert
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
and c.relname in ('live_posts','service_profiles','provider_recommendations','provider_reviews','admin_notifications')
order by c.relname;
