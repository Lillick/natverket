# NÄTVERKET – lanseringschecklista och verifieringsstatus

Senast tekniskt kontrollerad: 2026-11-23. Detta dokument skiljer mellan kontroller som faktiskt har körts och sådant som fortfarande kräver mänsklig eller juridisk verifiering.

## Status: kontrollerad pilot är inte ännu godkänd

Publik intresseanmälan är avsiktligt stängd. Ingen publik registrering eller kundförfrågan ska aktiveras innan alla blockerande punkter nedan är klara.

## Genomfört och verifierat tekniskt

- [x] 29 av 29 tabeller i `public` har RLS aktiverat.
- [x] 0 av 29 publika tabeller har anonym SELECT/INSERT/UPDATE/DELETE-behörighet.
- [x] 0 publika SECURITY DEFINER-funktioner kan köras av rollen `anon`.
- [x] Publika intags-RPC:er kan inte köras direkt av anon eller vanliga inloggade användare; Edge Function använder server-side service key.
- [x] Sju admin-RPC:er är ändrade från SECURITY DEFINER till SECURITY INVOKER och använder tabellernas admin-only RLS. Endast is_admin() är kvar som SECURITY DEFINER för att undvika rekursiv RLS-kontroll mot profiles.
- [x] Edge Function `public-intake` finns aktiv, men `INTAKE_ENABLED = false`.
- [x] Webbplatsens `PUBLIC_INTAKE_ENDPOINT` är tom. Formulären skickar därför inte personuppgifter.
- [x] Företagsansökningar är endast åtkomliga för plattformsadministratör via RLS. Ingen direkt anonym åtkomst.
- [x] Adminvyn har flik för företagsintresse, statusgranskning och intern granskningsanteckning. Godkänd status skapar inte automatiskt konto.
- [x] Adminvyn kan registrera och uppdatera GDPR-rättighetsärenden.
- [x] Databasen har metadata-baserad audit-logg med 13 triggers, inklusive CRM och företagsansökningar.
- [x] Tenant-organisationens SELECT-policy har korrigerats så att aktiv medlemsrad jämförs mot organisationens faktiska ID.
- [x] CRM-uppdateringar låser skaparattribution till aktuell användare.
- [x] Supabase Security Advisor visar inga anon-exekverbara SECURITY DEFINER-funktioner och inga publika tabeller utan RLS. En avsiktlig SECURITY DEFINER-varning återstår för is_admin().

## Kvarvarande tekniska kontroller före pilot

- [ ] Testa med två separata företagskonton och två organisationer: konto A får aldrig läsa, ändra eller se konto B:s kontakter, affärer, aktiviteter eller uppgifter.
- [ ] Testa rollerna owner, admin, member och viewer med riktiga testkonton.
- [ ] Testa administratörsinloggning, utloggning, lösenordsåterställning, e-postbekräftelse och sessionsutgång.
- [ ] Aktivera MFA för administratörskontot där det stöds.
- [ ] Testa de sju SECURITY INVOKER-admin-RPC:erna med både admin och vanligt konto. is_admin() är fortsatt SECURITY DEFINER eftersom den måste läsa adminroll utan rekursiv RLS; funktionen returnerar endast sant/falskt och anon saknar EXECUTE.
- [ ] Slutför test av formulärens server-side validering, honeypot, storleksgräns, CORS och rate-limit innan intaget öppnas. Rate-limit behöver testas även vid samtidiga anrop.
- [ ] Kontrollera att endast publishable/anon-nyckel finns i klientkod. Service-role/secret får endast finnas som server-side secret.
- [ ] Verifiera Vercel-deploy, domän, HTTPS, mobil och desktop i riktiga webbläsare. GitHub-commit är inte i sig bevis på lyckad Vercel-deploy.
- [ ] Säkerhetskopiera databasen och genomför dokumenterat återställningstest.
- [ ] Kontrollera loggning, incidentlarm, kontaktvägar och vem som bevakar inkomna ansökningar.

## Supabase-varningar som kräver beslut

- [ ] Leaked Password Protection är avstängt. Supabase dokumenterar att skyddet mot kända läckta lösenord kräver Pro-plan eller högre. Aktivera om planen redan stöder det; uppgradera inte utan kostnadsbeslut.
- [ ] Security Advisor varnar för åtta SECURITY DEFINER-funktioner som kan anropas av authenticated. Funktionerna är avsedda för adminflödet och innehåller admin-kontroller. De ska testas med vanligt konto och dokumenteras; varningen är inte ett bevis på sårbarhet men får inte ignoreras.
- [ ] `public_intake_rate_limits` har RLS och saknar policyer/klientbehörigheter avsiktligt. Endast server-side service role ska använda tabellen.

## GDPR och juridik – blockerar publik registrering

Följande uppgifter kan inte fyllas i korrekt genom kod utan beslut från verksamheten:

- [ ] Fastställ vilken juridisk person som är personuppgiftsansvarig och dess fullständiga namn.
- [ ] Fastställ offentlig kontaktadress för dataskyddsfrågor och postadress.
- [ ] Dokumentera ändamål och rättslig grund separat för företagsintresse, kundförfrågningar, leverantörsprofiler, CRM, matchning, marknadsföring och nyhetsbrev.
- [ ] Bestäm lagringstid/gallringsregel för varje kategori och hur gallring genomförs.
- [ ] Lista personuppgiftsbiträden och underbiträden (hosting, databas, e-post, analys, support), var data behandlas och eventuella tredjelandsöverföringar.
- [ ] Teckna/granska personuppgiftsbiträdesavtal där det behövs.
- [ ] Färdigställ integritetspolicy med registrerades rättigheter, klagomål till IMY, mottagare, överföringar och lagringstider.
- [ ] Färdigställ villkor och ansvarsfördelning för förmedlingsmodellen. Granska konsumentinformation, avtalspart, avgifter, avbokning, reklamation, försäkring, tillstånd, skatt och RUT/ROT-information.
- [ ] Bedöm cookies, lokal lagring, analys och eventuella spårningstekniker. Lägg bara till samtyckesbanner om icke-nödvändiga cookies/spårning faktiskt används.
- [ ] Dokumentera incidentrutin, register över behandlingar och bedöm om DPIA krävs.
- [ ] Låt integritetspolicy och användarvillkor granskas juridiskt innan publik lansering.

## Pilotupplägg som rekommenderas

1. Börja med en sluten pilot för ett fåtal företag som kontaktas manuellt.
2. Ta emot företagsintresse först när integritetstext, rättslig grund, lagring och server-side rate-limit är färdiga.
3. Granska företagen manuellt och verifiera kontaktperson/bolag innan konto skapas.
4. Skapa företagskonto och medlemskap manuellt. Ingen självregistrering eller automatiskt godkännande i första piloten.
5. Testa två separata företag och dokumentera att dataisoleringen fungerar.
6. Öppna därefter för en begränsad pilot. Publik kund-/personregistrering och betalningar är separata beslut.

## Viktigt

Tekniska kontroller är inte juridiskt GDPR-godkännande, penetrationstest eller garanti för felfri drift. Öppna inte formulär och lägg inte in riktiga personuppgifter förrän blockerande punkter är genomförda.
