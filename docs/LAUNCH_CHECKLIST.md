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
- [x] Statisk kontroll av index.html: inga dubbla id:n och inga brutna interna ankarlänkar. Två publika intagsformulär har avstängda skicka-knappar; det tredje är en inaktiv förhandsvisning av företagsregistrering med samtliga fält avstängda.

### Kvarstående tekniska punkter
- [ ] Supabase Auth: leaked-password protection är avstängd och ska aktiveras.
- [ ] Testa åtkomst med anonym besökare, vanlig inloggad användare och administratör i verkliga sessionsflöden.
- [ ] Genomför fullständig hemlighetsgranskning av hela det publika GitHub-repot och historiken, inte bara startsidan.
- [ ] Lägg till och verifiera CSP efter att tillåtna externa bild-, script- och API-källor har kartlagts. Startsidan laddar Supabase JS från jsDelivr och bilder från externa bildkällor.
- [x] Canonical URL, Open Graph- och Twitter-metadata har lagts till på arbetsgrenen. Favicon, sitemap och robots.txt återstår att kontrollera.
- [ ] Vercel: GitHub rapporterar lyckad Vercel-kontroll för senaste arbetsgrenscommit. Verifiera fortfarande Preview visuellt, faktiska HTTP-headers, produktionsdeployment, rollback, miljövariabler och domän.
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

## Ytterligare bygg- och testresultat – 2026-11-23

### Gjort i arbetsgrenen
- [x] Startsidan har nu tydliga Privat- och Företag-ingångar i toppmenyn och heron.
- [x] ?audience=private och ?audience=business styr respektive ingång och döljer irrelevanta delar.
- [x] Kategoriklick leder till kundförfrågningsflödet och förväljer rätt kategori; företagskategorier förväljer företag som kundtyp.
- [x] Individuell leverantörs-/uppdragslänk öppnar rätt personflöde i stället för företagsregistreringen.
- [x] Tidigare oåtkomlig kod efter tidiga return-satser är rättad i de tre flödesfunktionerna.
- [x] Företagsregistreringens inaktiva förhandsvisning är utökad med kontaktperson, företagskontakt, webbplats, frivilligt Instagram-namn, köp-/säljinriktning, tjänsteområde, geografiskt område, presentation, F-skatt, försäkring och behörigheter.
- [x] Förhandsvisningen visas, men samtliga fält och knappen är avstängda. De två publika intagsformulären är fortfarande dolda och deras skicka-knappar är avstängda.
- [x] Canonical URL samt Open Graph- och Twitter-metadata finns på arbetsgrenen.

### Statisk kvalitetssäkring av arbetsgrenen
- [x] 133 HTML-id:n kontrollerade: inga dubbletter.
- [x] Interna ankarlänkar kontrollerade: inga saknade mål.
- [x] 41 visuella tjänstekort och 4 företagskort kontrollerade mot tillåtna kategorier i förfrågningsformuläret: samtliga mappas till giltig kategori.
- [x] 11 nuvarande spårade filer genomsökta efter vanliga mönster för privata nycklar, GitHub-token, Stripe-hemligheter, Supabase secret keys, AWS-nycklar och Slack-token: inga träffar. Detta är inte en fullständig historikgranskning.
- [x] Supabase-funktionernas definitioner granskade: samtliga åtta varnade SECURITY DEFINER-funktioner har tom search_path; administrativa skrivfunktioner kontrollerar public.is_admin(), och katalog-/sökfunktionerna lämnar endast data när admin-kontrollen passerar.
- [x] Simulerat icke-admin-anrop med databasrollen authenticated: samtliga skyddade skrivfunktioner avvisade anropet och adminbegränsade läsningar returnerade inga rader. Test med riktiga användarsessioner återstår.
- [x] Vercels statuskontroll rapporterar success för senaste kontrollerade arbetsgrenscommit 0e19819d950a1e0aff4309d5180e2cf62f91958f.

### Fortfarande blockerande före publik datainsamling
- [ ] Aktivera Supabase Auth leaked-password protection.
- [ ] Testa med riktiga sessioner: utloggad besökare, vanlig inloggad användare och administratör.
- [ ] Granska Git-historikens tidigare commits för eventuella borttagna hemligheter; nuvarande filträd är skannat men historiken är inte fullständigt verifierad.
- [ ] Verifiera Vercel Preview i webbläsare och kontrollera faktiska HTTP-headers.
- [ ] CSP kräver först att inline-script, inline-stilar och inline-händelsehanterare kartläggs eller flyttas ut; lägg inte in en policy som bryter fungerande flöden eller ger falsk säkerhet.
- [ ] Slutför personuppgiftsansvarig, kontaktuppgifter, integritetsinformation, rättsliga grunder, gallringstider, leverantörs-/biträdesavtal och villkor.
- [ ] Testa backup/återställning, aviseringar, incidentflöde samt mobil- och desktopbeteende.
- [ ] PR #1 är fortfarande draft och omärkt som mergead. Ingen av dessa ändringar är publicerad på main.

### Backend för publika intag – byggt men avstängt
- [x] Supabase-migrationen secure_public_intake_all_flows har lagts på projektet.
- [x] Tre server-side databasfunktioner finns: submit_company_application, submit_public_request och submit_person_application.
- [x] EXECUTE för de tre funktionerna är endast tilldelad service_role; anon och authenticated saknar behörighet.
- [x] Test med syntetiska uppgifter kördes i transaktion och rullades tillbaka. Tre adminnotiser verifierades i testtransaktionen.
- [x] Kategori Skärm & display – uthyrning och köp har lagts till i categories och verifierats aktiv.
- [x] Edge Function public-intake v9 är driftsatt med tre intagstyper, validering, honeypot, IP-hashad rate limiting och adminnotiser. Hård spärr INTAKE_ENABLED=false är kvar.
- [x] Frontendens submitPublicForm är förberedd för company, request och person; company-preview har namngivna fält och statusmeddelande.
- [ ] PUBLIC_INTAKE_ENDPOINT är fortfarande tom och de publika formulären är avstängda. Ändra inte detta förrän legal basis, integritetsinformation och fullständiga tester är godkända.
- [ ] E-postaviseringar är inte konfigurerade; nuvarande adminnotiser sparas i databasen.
- [ ] Bekräfta att den juridiska grunden som ska användas i PUBLIC_INTAKE_LEGAL_BASIS är korrekt innan den konfigureras.
