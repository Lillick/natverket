# NÄTVERKET – MVP

NÄTVERKET är en tidig webb-MVP med publik informationssida och separat administratörsvy.

## Lokal struktur
- `index.html` – publik webbplats och admin-MVP.
- `supabase/SECURITY_AUDIT.sql` – read-only SQL-kontroller av RLS, policyer, funktioner och privilegier.
- `supabase/PRODUCTION_HARDENING.sql` – samlad, idempotent databasmigrering för anonym åtkomst, RPC-behörigheter, aktiv matchning, GDPR-ärenderegister och metadata-baserad revisionslogg.
- `supabase/PUBLIC_INTAKE_FUNCTIONS.sql` – aktuell definition och behörigheter för de tre server-side intagsfunktionerna.
- `docs/LAUNCH_CHECKLIST.md` – lanserings- och dataskyddskrav.

## Drift
Projektet är en statisk webbplats och kan publiceras via Vercel från GitHub. Ingen byggprocess krävs.

Admin nås via `/?admin=1`. Anslut med Supabase Project URL och endast projektets publika anon/publishable key. Använd aldrig service_role i webbläsaren.

## Nuvarande begränsningar
Publika formulär är avsiktligt inte aktiverade. Supabase Edge Function public-intake v9 är driftsatt med stöd för företagsintresse, kundförfrågningar och personintresse, inklusive server-side validering, honeypot, IP-hashad rate limiting och adminnotiser. Funktionen har en hård avstängning (INTAKE_ENABLED=false), och webbplatsens PUBLIC_INTAKE_ENDPOINT är tom. Databasfunktionerna kan endast köras av service_role. Ingen publik personuppgiftsinsamling sker. Legal basis och integritetsversionsnummer måste fastställas innan funktionen kan öppnas. Den interna dataskyddsstrukturen utgör inte i sig en komplett GDPR-process eller juridiskt godkännande.

Se `docs/LAUNCH_CHECKLIST.md` innan riktiga personuppgifter eller externa användare tas in.
