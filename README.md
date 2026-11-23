# NÄTVERKET – MVP

NÄTVERKET är en statisk webb-MVP med publik informationssida, separat administratörsvy och en första företagsyta för NÄTVERKET PRO.

## Lokal struktur
- `index.html` – publik webbplats och befintlig admin-MVP.
- `foretag.html` – inloggad företagsyta för kontakter, affärsmöjligheter, uppgifter och aktivitetslogg.
- `supabase/SECURITY_AUDIT.sql` – read-only SQL-kontroller av RLS, policyer, funktioner och privilegier.
- `supabase/PRODUCTION_HARDENING.sql` – tidigare säkerhetsarbete för anonym åtkomst, RPC-behörigheter, GDPR-register och revisionslogg.
- `docs/CRM_ARCHITECTURE.md` – datamodell, behörighetsmodell och begränsningar för NÄTVERKET PRO.
- `docs/LAUNCH_CHECKLIST.md` – lanserings- och dataskyddskrav.

## Drift
Projektet är en statisk webbplats och kan publiceras via Vercel från GitHub. Ingen byggprocess krävs.

- Admin nås via `/?admin=1`.
- NÄTVERKET PRO nås via `/foretag.html`.
- Företagsytan använder endast Supabase public publishable key i webbläsaren. `service_role` får aldrig exponeras i klientkod.
- Företagskonton är inte öppna för självregistrering. En användare måste ha en aktiv post i `organization_memberships`.

## Dataskydd och lansering
Publik intresseanmälan är fortsatt stängd. Supabase Edge Function `public-intake` finns men har en avsiktlig hård avstängning tills rättslig grund, integritetsinformation och lanseringstester är beslutade. Aktivera inte formulär eller ta emot riktiga personuppgifter innan checklistan är genomgången.

NÄTVERKET PRO:s CRM-tabeller har RLS aktiverat. Anonyma användare saknar tabellåtkomst. Inloggade användare får endast åtkomst till organisationer där de har en aktiv medlemsrad; detta ska fortsatt verifieras med separata testkonton före extern pilot.

Abonnemang, Stripe och betalningar är inte aktiverade. Första versionen är en intern/testbar grund utan nya löpande kostnader.

Se `docs/LAUNCH_CHECKLIST.md` och `docs/CRM_ARCHITECTURE.md` innan externa användare tas in.
