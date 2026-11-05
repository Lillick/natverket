-- NÄTVERKET – read-only security audit
-- Kör i Supabase SQL Editor. Detta granskar status men ändrar INTE databasen.
-- Spara resultatet och granska innan riktiga personuppgifter läggs in.

-- 1. Tabeller och om RLS är aktiverat
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
order by c.relname;

-- 2. Befintliga RLS-policyer
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- 3. Funktioner med SECURITY DEFINER (måste granskas manuellt)
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer,
  p.proconfig as function_settings
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
order by p.proname;

-- 4. Privilegier för anon/authenticated på tabeller i public
select
  grantee,
  table_schema,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon', 'authenticated')
order by table_name, grantee, privilege_type;

-- 5. Kontrollera att känsliga tabeller inte kan nås av anon
-- Resultatet är en granskningslista, inte ett automatiskt godkännande.
select
  t.table_name,
  bool_or(g.grantee = 'anon' and g.privilege_type in ('SELECT','INSERT','UPDATE','DELETE')) as anon_has_table_privilege
from information_schema.tables t
left join information_schema.role_table_grants g
  on g.table_schema = t.table_schema and g.table_name = t.table_name
where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
group by t.table_name
order by t.table_name;
