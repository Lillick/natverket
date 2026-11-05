# NÄTVERKET – MVP

NÄTVERKET är en tidig webb-MVP med publik informationssida och separat administratörsvy.

## Lokal struktur
- `index.html` – publik webbplats och admin-MVP.
- `supabase/SECURITY_AUDIT.sql` – read-only SQL-kontroller av RLS, policyer, funktioner och privilegier.
- `docs/LAUNCH_CHECKLIST.md` – lanserings- och dataskyddskrav.

## Drift
Projektet är en statisk webbplats och kan publiceras via Vercel från GitHub. Ingen byggprocess krävs.

Admin nås via `/?admin=1`. Anslut med Supabase Project URL och endast projektets publika anon/publishable key. Använd aldrig service_role i webbläsaren.

## Nuvarande begränsningar
Publika formulär är avsiktligt inte aktiverade. Det finns ännu ingen verifierad server-side intake-funktion, spambegränsning eller färdig GDPR-process. Den befintliga admin-MVP:n är inte i sig ett produktionsgodkännande.

Se `docs/LAUNCH_CHECKLIST.md` innan riktiga personuppgifter eller externa användare tas in.
