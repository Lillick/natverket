# NÄTVERKET – lanseringsplan och verifieringsstatus

Detta repo innehåller en tidig admin-MVP och publik informationssida. Att kod finns i GitHub eller att grundläggande SQL-kontroller passerar betyder inte att tjänsten är produktionsklar.

## Verifierat i Supabase – 2026-11-06

Följande kontroller har körts och resultaten har rapporterats:
- [x] RLS aktiverat på samtliga 16 publika tabeller.
- [x] Inga anonyma tabellbehörigheter kvar efter att SELECT på audit_events återkallats.
- [x] Inga publika funktioner med EXECUTE för rollen anon.
- [x] De tre dataskyddstabellerna privacy_requests, privacy_records och audit_events finns och har RLS.
- [x] generate_request_matches(uuid) är SECURITY DEFINER, har tom search_path, kräver admin och filtrerar på people.status = 'active'.
- [x] audit_events ger authenticated endast SELECT; anon har ingen behörighet.

Detta är en grundläggande teknisk kontroll, inte en fullständig penetrationstestning, behörighetsrevision eller ett juridiskt GDPR-godkännande.

## Vad som faktiskt finns i appen

- [x] Publik informationssida med beskrivning av NÄTVERKET och tjänsteområden.
- [x] Separat adminväg via `/?admin=1`.
- [x] Admininloggning via Supabase Auth och kontroll av adminroll i profiles.
- [x] Adminvyer för personer, kunder, företag, uppdrag och matchningar.
- [x] Matchningsvyn anropar Supabase RPC.
- [ ] Publika formulär för kundförfrågan och intresseanmälan.
- [ ] Server-side intake med validering, spam-/rate-limit-skydd och säker hantering.
- [ ] Adminvyer för GDPR-ärenden, revisionslogg, uppföljningar, tilldelningar och provisioner.
- [ ] Test av flöden med admin, vanligt konto och utloggad besökare.
- [ ] Säkerhetskopiering och återställning testad.
- [ ] Juridiska texter färdigställda med verkliga företags- och kontaktuppgifter.
- [ ] Dokumenterat acceptanstest på mobil och dator.

## Nästa arbetsfaser – samla arbetet i större leveranser

### Fas 1 – fungerande intag från publika webbplatsen
1. Bygg två tydliga publika flöden: "Jag behöver hjälp" och "Jag söker jobb eller uppdrag".
2. Skicka formulärdata via en server-side Supabase Edge Function; ge aldrig anon direkt INSERT/SELECT i registertabellerna.
3. Lägg till validering, honeypot och lämpligt spam-/rate-limit-skydd.
4. Spara minsta nödvändiga uppgifter och visa tydlig bekräftelse utan att exponera interna register.
5. Lägg till inkomna förfrågningar i adminflödet med status "ny".

### Fas 2 – komplett adminflöde
1. Lägg till adminvyer för uppföljningar, tilldelningar, provisioner och dataskyddsärenden.
2. Visa revisionslogg skrivskyddat.
3. Förbättra matchningshantering: godkänna kontakt, registrera svar och följa status.
4. Lägg till redigering, arkivering och kontrollerad radering där det behövs.

### Fas 3 – GDPR och juridik
1. Fastställ personuppgiftsansvarig och kontaktuppgifter.
2. Dokumentera ändamål, rättslig grund per flöde, datakategorier, mottagare/biträden, överföringar och lagringstider.
3. Färdigställ integritetspolicy, cookiebedömning och villkor efter beslutad affärsmodell.
4. Bygg och testa processer för registerutdrag, rättelse, radering, begränsning, invändning och dataportabilitet där tillämpligt.
5. Dokumentera incidentrutin, backup/återställning och bedömning av DPIA.
6. Låt juridiska texter och ansvarsfördelning granskas innan publik lansering.

### Fas 4 – kvalitetssäkring och lansering
1. Testa samtliga flöden på mobil och dator.
2. Testa behörigheter med admin, vanligt inloggat konto och utloggad besökare.
3. Kontrollera att endast anon/publishable key finns i webbläsaren. service_role får endast finnas som server-side secret.
4. Genomför dokumenterad acceptans- och återställningstest.
5. Öppna publik registrering först när samtliga lanseringskrav är uppfyllda.

## GDPR – miniminivå

- Samla bara in uppgifter som behövs för ett tydligt ändamål.
- Informera innan uppgifter samlas in; skilj mellan nödvändig behandling och frivillig marknadsföring.
- Använd inte samtycke slentrianmässigt när annan rättslig grund är korrekt.
- Bestäm gallringsfrister och radera/anonymisera uppgifter när de inte längre behövs.
- Begränsa åtkomst enligt minsta privilegium och logga relevanta administrativa åtgärder.
- Ha process för registrerades rättigheter och incidenthantering.
- Bedöm om konsekvensbedömning (DPIA) krävs innan mer omfattande eller riskfylld behandling.

## Viktigt

Databastabeller för dataskydd är stöd för en process, inte en färdig GDPR-process i sig. Detta dokument är en teknisk och operativ plan, inte juridisk rådgivning eller ett intyg om GDPR-efterlevnad. Använd inte riktiga personuppgifter eller öppna publik registrering förrän relevanta säkerhets-, drift- och dataskyddskrav är testade.


## Ny teknisk återkontroll – 2026-11-23

Följande har verifierats direkt mot anslutet GitHub- och Supabase-projekt. Detta är en statusbild, inte ett godkännande för lansering.

### Verifierat
- [x] 23 publika tabeller har RLS aktiverat.
- [x] Rollen anon har 0 direkta tabellbehörigheter i public och 0 EXECUTE på funktioner i public.
- [x] `submit_company_application(jsonb)` kan endast köras av service_role.
- [x] `company_applications` och `public_intake_rate_limits` saknar policyer och direkta klientbehörigheter; de är avsiktligt stängda för klientroller.
- [x] Samtliga 8 SECURITY DEFINER-funktioner som Supabase varnar för har kontrollerats. De administrativa funktionerna kontrollerar `public.is_admin()`; `is_admin()` lämnar endast ett booleskt svar. Varningarna ska ändå följas upp genom negativa tester och minsta möjliga EXECUTE-behörighet.
- [x] Aktiv Supabase Edge Function `public-intake` är version 8. Den har `INTAKE_ENABLED = false`, så den avvisar anrop innan den läser eller sparar formulärdata.
- [x] Publik HTML saknar service-role-nyckel; förekomsten av texten `service_role` är en instruktion att aldrig använda nyckeln i webbläsaren.
- [x] Statisk kontroll av `index.html`: inga dubbla id:n och inga brutna interna ankarlänkar. Tre formulär finns; alla tre skicka-knappar är avstängda.

### Kvarstående tekniska punkter
- [ ] Supabase Auth: leaked-password protection är avstängd och ska aktiveras.
- [ ] Testa åtkomst med anonym besökare, vanlig inloggad användare och administratör i verkliga sessionsflöden.
- [ ] Genomför fullständig hemlighetsgranskning av hela det publika GitHub-repot och historiken, inte bara startsidan.
- [ ] Lägg till och verifiera CSP efter att tillåtna externa bild-, script- och API-källor har kartlagts. Startsidan laddar Supabase JS från jsDelivr och bilder från externa bildkällor.
- [ ] Lägg till canonical URL och Open Graph-metadata samt kontrollera favicon, sitemap och robots.txt.
- [ ] Vercel: verifiera produktionsdeployment, preview, rollback, miljövariabler, headers och domän via den redan anslutna Vercel-integrationen.
- [ ] Kontrollera backup och återställning, loggning, e-postaviseringar och incidentflöde.
- [ ] Genomför mobil-/desktop-acceptanstest och tillgänglighetskontroll.
- [ ] Juridisk identitet, personuppgiftsansvarig, kontaktuppgifter, rättsliga grunder, lagringstider, biträden/överföringar och slutliga villkor måste fastställas före personuppgiftsinsamling.

### Ändringar i arbetsgrenen `launch-readiness`
- [x] Supabase Edge Function-källan i GitHub har synkroniserats mot den aktiva version 8, så att kodbasen inte längre ligger efter den driftsatta funktionen.
- [x] `vercel.json` har lagts till med grundläggande säkerhetsheaders: nosniff, frame-deny, strikt referrer policy, begränsad Permissions-Policy och HSTS.
- [ ] Ändringarna är ännu inte mergade till `main` eller verifierade i Vercel Production.

### Viktiga skillnader att förstå
- 141 direkta tabellbehörigheter för rollen authenticated finns i databasen, men RLS-policyerna begränsar åtkomsten. Dessa ska inte bedömas enbart utifrån antalet grants; de måste testas med vanliga användarkonton.
- De två tabellerna utan RLS-policy är avsiktligt stängda för klientroller. Skapa inte en publik policy bara för att få bort en INFO-varning.
- Att en Edge Function har `verify_jwt = false` innebär att den är nåbar utan Supabase-inloggning. Den måste därför ha egen skyddskontroll. Just nu är intake-funktionen dessutom hårt avstängd; aktivera den inte innan hela lanseringsspärrlistan är godkänd.
