# NÄTVERKET – MVP

NÄTVERKET är en tidig webb-MVP med publik informationssida och separat administratörsvy.

## Lokal struktur
- `index.html` – publik webbplats och admin-MVP.
- `supabase/SECURITY_AUDIT.sql` – read-only SQL-kontroller av RLS, policyer, funktioner och privilegier.
- `supabase/PRODUCTION_HARDENING.sql` – samlad, idempotent databasmigrering för anonym åtkomst, RPC-behörigheter, aktiv matchning, GDPR-ärenderegister och metadata-baserad revisionslogg.
- `docs/LAUNCH_CHECKLIST.md` – lanserings- och dataskyddskrav.

## Drift
Projektet är en statisk webbplats och kan publiceras via Vercel från GitHub. Ingen byggprocess krävs.

Admin nås via `/?admin=1`. Anslut med Supabase Project URL och endast projektets publika anon/publishable key. Använd aldrig service_role i webbläsaren.

## Nuvarande begränsningar
Publika formulär är avsiktligt inte aktiverade. Det finns ännu ingen verifierad server-side intake-funktion, spambegränsning eller färdig GDPR-process. Den nya migreringen skapar interna dataskyddsregister och revisionslogg men utgör inte i sig en komplett GDPR-process eller juridiskt godkännande.

Se `docs/LAUNCH_CHECKLIST.md` innan riktiga personuppgifter eller externa användare tas in.
